using Reight


class Reight::Runner < Reight::App

  TEMPORARY_HASH = {}

  def activated()
    super
    run force: true
    @context.call_activated__
  end

  def deactivated()
    super
    @context.call_deactivated__
    pause
  end

  def draw()
    push do
      @context&.call_draw__ unless paused?
    end
    super
  end

  def key_pressed()
    super
    @context&.key_pressed unless paused?
  end

  def key_released()
    super
    @context&.key_released unless paused?
  end

  def key_typed()
    super
    @context&.key_typed unless paused?
  end

  def mouse_pressed()
    super
    @context&.mouse_pressed unless paused?
  end

  def mouse_released()
    super
    @context&.mouse_released unless paused?
  end

  def mouse_moved()
    super
    @context&.mouse_moved unless paused?
    navigator.visible = mouse_y < NAVIGATOR_HEIGHT
  end

  def mouse_dragged()
    super
    @context&.mouse_dragged unless paused?
  end

  def mouse_clicked()
    super
    @context&.mouse_clicked unless paused?
  end

  def double_clicked()
    super
    @context&.double_clicked unless paused?
  end

  def mouse_wheel()
    super
    @context&.mouse_wheel unless paused?
  end

  def touch_started()
    super
    @context&.touch_started unless paused?
  end

  def touch_ended()
    super
    @context&.touch_ended unless paused?
  end

  def touch_moved()
    super
    @context&.touch_moved unless paused?
  end

  def window_moved()
    super
    @context&.window_moved
  end

  def window_resized()
    super
    @context&.window_resized
  end

  private

  def running? = @context && !@paused

  def paused?  = @context && @paused

  def run(force: false)
    return pause false if paused? && !force
    cleanup
    backup_global_vars
    @context = create_context
    @paused  = false
    begin_wrapping_user_classes @context
    eval_user_script @context, project.code_paths.zip(project.codes).to_h
  end

  def pause(state = true)
    @paused = state
  end

  def cleanup()
    remove_world @context.sprite_world__ if @context
    @context = nil
    end_wrapping_user_classes
    restore_global_vars
    GC.enable
    GC.start
  end

  def create_context()
    klass = Class.new do
      def project        = @project__

      def sprite_world__ = @sprite_world__ ||= SpriteWorld.new(pixels_per_meter: 5)

      def call_activated__()
        add_world sprite_world__
        activated
      end

      def call_deactivated__()
        deactivated
        remove_world sprite_world__
        @background_cleared__ = false
      end

      def call_draw__()
        unless @setup_done__
               @setup_done__ = true
          setup
        end
        unless @background_cleared__
               @background_cleared__ = true
          background 100, 100, 100
        end
        draw
      end

      def createSprite(...) = sprite_world__.createSprite(...)
      def addSprite(...)    = sprite_world__.addSprite(...)
      def removeSprite(...) = sprite_world__.removeSprite(...)
      def gravity(...)      = sprite_world__.gravity(...)
    end
    Reight.to_snake_case(
      %i[activated deactivated] + Processing::Context::EVENT_NAMES__
    ).each do |camel, snake|
      klass.class_eval <<~END
        def #{camel}(&block)
          if block
            @#{camel}_block__ = block
          else
            @#{camel}_block__&.call
          end
        end
      END
      klass.alias_method snake, camel if snake != camel
    end
    klass.new.tap do |context|
      context.instance_variable_set :@project__, project
    end
  end

  def begin_wrapping_user_classes(context)
    prefix       = get_user_class_prefix context
    wrapper      = create_user_class_wrapper context
    @trace_point = TracePoint.trace :class do |tp|
      tp.self.include wrapper if tp.self.name&.start_with? prefix
    end
  end

  def end_wrapping_user_classes()
    @trace_point&.disable
    @trace_point = nil
  end

  def get_user_class_prefix(context)
    prefix = nil
    context.instance_eval <<~EVAL
      class Reight_Dummy__; end
      prefix = Reight_Dummy__.name[/^#<Class:0x[0-9a-zA-Z]+>::/]
      singleton_class.__send__ :remove_const, :Reight_Dummy__
    EVAL
    prefix
  end

  def create_user_class_wrapper(context)
    Module.new.tap do |wrapper|
      wrap_methods context, wrapper
    end
  end

  def wrap_methods(context, klass)
    klass.define_method :respond_to_missing? do |name, include_private = false|
      context.respond_to?(name, false) || super(name, include_private)
    end
    klass.define_method :method_missing do |name, *args, **kwargs, &block|
      if context.respond_to? name
        klass.define_method(name) {|*a, **k, &b| context.public_send name, *a, **k, &b}
        context.public_send name, *args, **kwargs, &block
      else
        super name, *args, **kwargs, &block
      end
    end
    Reight.to_snake_case(%i[
      project createSprite addSprite removeSprite gravity
    ]).each do |camel, snake|
      klass.define_method(camel) {|*a, **k, &b| context.public_send camel, *a, **k, &b}
      klass.alias_method snake, camel if snake != camel
    end
  end

  def eval_user_script(context, codes)
    TEMPORARY_HASH[:params] = {context: context, codes: codes}
    context.class.class_eval <<~END
      ::Reight::Runner::TEMPORARY_HASH[:params] => {context:, codes:}
      codes.each {|path, code| context.instance_eval code, path if code}
    END
  ensure
    TEMPORARY_HASH.delete :params
  end

  def backup_global_vars()
    @global_vars = global_variables
      .each.with_object({}) {|name, hash| hash[name] = eval name.to_s}
      .freeze
  end

  def restore_global_vars()
    return unless @global_vars
    global_variables
      .map    {|name| [name, eval(name.to_s)]}
      .select {|name, value| value != nil && @global_vars[name] == nil}
      .each   {|name, value| global_var_set name, nil}
    %i[$, $/ $-0 $; $-F $-d $-i $-v $-w $. $\\ $_ $~ $DEBUG $VERBOSE]
      .select {|name| @global_vars.key? name}
      .each   {|name| global_var_set name, @global_vars[name]}
    /x/ =~ '' # clear vars about last result for regexp
    @global_vars = nil
  end

  def global_var_set(name, value)
    TEMPORARY_HASH[:value] = value
    eval "#{name} = ::Reight::Runner::TEMPORARY_HASH[:value]"
  ensure
    TEMPORARY_HASH.delete :value
  end

end# Runner

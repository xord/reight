using Reight


class Reight::Runner < Reight::App

  TEMPORARY_HASH = {}

  def activate()
    run force: true
    @context&.activated
    super
  end

  def deactivated()
    super
    @context&.call_deactivated__
    pause
  end

  def draw()
    return if paused?
    push_matrix do
      translate 0, NAVIGATOR_HEIGHT
      @context&.call_draw__
    end
  end

  def key_pressed()
    @context&.key_pressed unless paused?
  end

  def key_released()
    @context&.key_released unless paused?
  end

  def key_typed()
    @context&.key_typed unless paused?
  end

  def mouse_pressed()
    @context&.mouse_pressed unless paused?
  end

  def mouse_released()
    @context&.mouse_released unless paused?
  end

  def mouse_moved()
    @context&.mouse_moved unless paused?
  end

  def mouse_dragged()
    @context&.mouse_dragged unless paused?
  end

  def mouse_clicked()
    @context&.mouse_clicked unless paused?
  end

  def double_clicked()
    @context&.double_clicked unless paused?
  end

  def mouse_wheel()
    @context&.mouse_wheel unless paused?
  end

  def touch_started()
    @context&.touch_started unless paused?
  end

  def touch_ended()
    @context&.touch_ended unless paused?
  end

  def touch_moved()
    @context&.touch_moved unless paused?
  end

  def window_moved()
    @context&.window_moved
  end

  def window_resized()
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
    begin_wrapping_user_classes @context
    eval_user_script @context, project.code_paths.zip(project.codes).to_h
  end

  def pause(state = true)
    @paused = state
  end

  def cleanup()
    @context = nil
    @paused  = false
    end_wrapping_user_classes
    restore_global_vars
    GC.enable
    GC.start
  end

  def create_context()
    klass = Class.new do
      def project = @project__

      def call_deactivated__()
        deactivated
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
    end
    %i[
      activated deactivated setup draw
      key_pressed key_released key_typed
      mouse_pressed mouse_released mouse_moved mouse_dragged
      mouse_clicked double_clicked mouse_wheel
      touch_started touch_ended touch_moved
      window_moved window_resized
    ].each do |name|
      klass.class_eval <<~END
        def #{name}(&block)
          if block
            @#{name}_block__ = block
          else
            @#{name}_block__&.call
          end
        end
      END
      camelCase = name.to_s.gsub(/_([a-z])/) {$1.upcase}
      klass.alias_method camelCase, name if camelCase != name
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

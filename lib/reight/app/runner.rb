class Reight::Runner < Reight::App

  include Xot::Inspectable

  ROOT_CONTEXT   = Reight::CONTEXT__

  TEMPORARY_HASH = {}

  def label = 'Run'

  def activated()
    run force: true
    @context.call_activated__ {|&b| call_event(ignore_pause: true, &b)}
    super
  end

  def deactivated()
    super
    @context.call_deactivated__ {|&b| call_event(ignore_pause: true, &b)}
    pause
    cleanup
  end

  def draw()
    return unless @context
    @initial_resize ||= true.tap do
      call_event {@context.size ROOT_CONTEXT.width, ROOT_CONTEXT.height}
    end
    @context.call_draw__ {|push: true, &b| call_event(push: push, &b)}
    if canvasFrame = @context.canvasFrame__
      ROOT_CONTEXT.background 0
      ROOT_CONTEXT.image @context, *canvasFrame
    else
      ROOT_CONTEXT.image @context, 0, 0
    end
    super
  end

  def key_pressed()
    super
    call_event {@context.key_pressed}
  end

  def key_released()
    super
    call_event {@context.key_released}
  end

  def key_typed()
    super
    call_event {@context.key_typed}
  end

  def mouse_pressed()
    super
    call_event {@context.mouse_pressed}
  end

  def mouse_released()
    super
    call_event {@context.mouse_released}
  end

  def mouse_moved()
    super
    navigator.visible = ROOT_CONTEXT.mouse_y < NAVIGATOR_HEIGHT
    call_event {@context.mouse_moved}
  end

  def mouse_dragged()
    super
    call_event {@context.mouse_dragged}
  end

  def mouse_clicked()
    super
    call_event {@context.mouse_clicked}
  end

  def double_clicked()
    super
    call_event {@context.double_clicked}
  end

  def mouse_wheel()
    super
    call_event {@context.mouse_wheel}
  end

  def touch_started()
    super
    call_event {@context.touch_started}
  end

  def touch_ended()
    super
    call_event {@context.touch_ended}
  end

  def touch_moved()
    super
    call_event {@context.touch_moved}
  end

  def window_moved()
    super
    call_event(ignore_pause: true) {@context.window_moved}
  end

  def window_resized()
    super
    call_event(ignore_pause: true) {@context.window_resized}
  end

  private

  def call_event(push: true, ignore_pause: false, &block)
    if @context
      @context.beginDraw__
      @context.push if push
      block.call unless paused?
    end
  rescue ScriptError, StandardError => e
    puts e.full_message
  ensure
    if @context
      @context.pop if push
      @context.endDraw__
    end
  end

  def running? = @context && !@paused

  def paused?  = @context && @paused

  def run(force: false)
    return pause false if paused? && !force
    backup_global_vars
    @context = create_context
    @paused  = false
    Processing::Context.setContext__ @context
    begin_wrapping_user_classes @context
    eval_user_script @context, project.code_paths.zip(project.codes).to_h
  end

  def pause(state = true)
    @paused = state
  end

  def cleanup()
    ROOT_CONTEXT.remove_world @context.spriteWorld__ if @context
    Processing::Context.setContext__ nil
    @context = nil
    end_wrapping_user_classes
    clear_all_timers
    project.clear_all_sprites
    restore_global_vars
    GC.enable
    GC.start
  end

  def create_context()
    klass = Class.new do
      include Reight::Context

      def call_activated__(&caller)
        add_world spriteWorld__
        caller.call {activated}
      end

      def call_deactivated__(&caller)
        caller.call {deactivated}
        remove_world spriteWorld__
        @background_cleared__ = false
      end

      def call_draw__(&caller)
        @setup_done__         ||= true.tap {caller.call(push: false) {setup}}
        @background_cleared__ ||= true.tap {caller.call {background 100}}
        caller.call {draw}
      end

      def inspect()
        "#<#{self.class.name}:0x#{object_id}>"
      end

      methods = (instance_methods - Object.instance_methods)
        .reject {_1.end_with? '__'}
      Processing.to_snake_case__(methods).each do |camel, snake|
        alias_method snake, camel if snake != camel
      end

      Processing.to_snake_case__(
        %i[activated deactivated] + Processing::EVENT_NAMES__
      ).each do |camel, snake|
        class_eval <<~END
          def #{camel}(&block)
            if block
              @#{camel}_block__ = block
            else
              @#{camel}_block__&.call
            end
          end
        END
        alias_method snake, camel if snake != camel
      end

      Processing.funcs__(ROOT_CONTEXT).each do |func|
        next if method_defined? func
        define_method(func) {|*a, **k, &b| ROOT_CONTEXT.__send__ func, *a, **k, &b}
      end
    end
    klass.new(ROOT_CONTEXT, project)
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
      wrapper.define_method :respond_to_missing? do |name, include_private = false|
        context.respond_to?(name, false) || super(name, include_private)
      end
      wrapper.define_method :method_missing do |name, *args, **kwargs, &block|
        if context.respond_to? name
          wrapper.define_method(name) {|*a, **k, &b| context.public_send name, *a, **k, &b}
          context.public_send name, *args, **kwargs, &block
        else
          super name, *args, **kwargs, &block
        end
      end
    end
  end

  def eval_user_script(context, codes)
    TEMPORARY_HASH[:params] = {context: context, codes: codes}
    context.class.class_eval <<~END
      ::Reight::Runner::TEMPORARY_HASH[:params] => {context:, codes:}
      codes.each {|path, code| context.instance_eval code, path if code}
    END
  rescue ScriptError, StandardError => e
    puts e.full_message
  ensure
    TEMPORARY_HASH.delete :params
  end

  EXCLUDE_GLOBAL_VARS = [:$FILENAME]

  def backup_global_vars()
    @global_vars = (global_variables - EXCLUDE_GLOBAL_VARS)
      .each.with_object({}) {|name, hash| hash[name] = eval name.to_s}
      .freeze
  end

  def restore_global_vars()
    return unless @global_vars
    (global_variables - EXCLUDE_GLOBAL_VARS)
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

  def clear_all_timers()
    prefix = Reight::Context::TIMER_PREFIX__
    ROOT_CONTEXT.instance_eval do
      @timers__      .delete_if {|id| id in [prefix, _]}
      @firingTimers__.delete_if {|id| id in [prefix, _]}
    end
  end

end# Runner

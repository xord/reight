using Reight


class Reight::Runner < Reight::App

  TEMPORARY_HASH = {}

  def activate()
    run
    @context&.activated
    super
  end

  def deactivated()
    super
    @context&.call_deactivated__
  end

  def draw()           = @context&.call_draw__
  def key_pressed()    = @context&.key_pressed
  def key_released()   = @context&.key_released
  def key_typed()      = @context&.key_typed
  def mouse_pressed()  = @context&.mouse_pressed
  def mouse_released() = @context&.mouse_released
  def mouse_moved()    = @context&.mouse_moved
  def mouse_dragged()  = @context&.mouse_dragged
  def mouse_clicked()  = @context&.mouse_clicked
  def double_clicked() = @context&.double_clicked
  def mouse_wheel()    = @context&.mouse_wheel
  def touch_started()  = @context&.touch_started
  def touch_ended()    = @context&.touch_ended
  def touch_moved()    = @context&.touch_moved
  def window_moved()   = @context&.window_moved
  def window_resized() = @context&.window_resized

  private

  def running? = @context

  def run()
    cleanup
    backup_global_vars
    @context = create_context.new
    TEMPORARY_HASH[:params] = {
      context: @context,
      codes:   project.code_paths.zip(project.codes).to_h
    }
    @context.class.class_eval <<~END
      ::Reight::Runner::TEMPORARY_HASH[:params] => {context:, codes:}
      codes
        .select {|_,    code| code}
        .each   {|path, code| context.instance_eval code, path}
    END
    TEMPORARY_HASH.delete :params
  end

  def cleanup()
    @context = nil
    restore_global_vars
    GC.enable
    GC.start
  end

  def create_context()
    c = Class.new do
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
      c.class_eval <<~END
        def #{name}(&block)
          if block
            @#{name}_block__ = block
          else
            @#{name}_block__&.call
          end
        end
      END
      camelCase = name.to_s.gsub(/_([a-z])/) {$1.upcase}
      c.alias_method camelCase, name if camelCase != name
    end
    c
  end

  def backup_global_vars()
    @global_vars = global_variables.each.with_object({}) {|name, hash|
      hash[name] = eval name.to_s
    }.freeze
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
    eval "#{name.to_s} = ::Reight::Runner::TEMPORARY_HASH[:value]"
  #rescue StandardError, SyntaxError
  ensure
    TEMPORARY_HASH.delete :value
  end

end# Runner

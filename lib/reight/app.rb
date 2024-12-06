using Reight


class Reight::App

  SPACE            = 8
  BUTTON_SIZE      = 12
  NAVIGATOR_HEIGHT = BUTTON_SIZE + 2

  SCREEN_WIDTH     = 256
  SCREEN_HEIGHT    = 224 + NAVIGATOR_HEIGHT

  def initialize(project)
    @project = project
  end

  attr_reader :project

  def flash(...)
    r8.flash(...) if history.enabled?
  end

  def group(*buttons)
    buttons.each.with_index do |button, index|
      button.clicked do
        buttons.each.with_index {|b, i| b.active = i == index}
      end
    end
    buttons
  end

  def name()
    self.class.name
  end

  def history()
    @history ||= Reight::History.new
  end

  def sprites()
    []
  end

  def activate()
    sprites.each {|sp| add_sprite sp}
  end

  def deactivate()
    sprites.each {|sp| remove_sprite sp}
  end

  def draw()           = nil
  def key_pressed()    = nil
  def key_released()   = nil
  def key_typed()      = nil
  def mouse_pressed()  = nil
  def mouse_released() = nil
  def mouse_moved()    = nil
  def mouse_dragged()  = nil
  def mouse_clicked()  = nil
  def double_clicked() = nil
  def mouse_wheel()    = nil
  def touch_started()  = nil
  def touch_ended()    = nil
  def touch_moved()    = nil
  def window_moved()   = nil
  def window_resized() = nil

  def undo(flash: true) = nil
  def redo(flash: true) = nil

  def inspect()
    "#<#{self.class.name}:#{object_id}>"
  end

end# App

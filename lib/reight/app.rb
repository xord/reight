using Reight


class Reight::App

  SCREEN_WIDTH     = 400
  SCREEN_HEIGHT    = 224

  SPACE            = 6
  BUTTON_SIZE      = 12
  NAVIGATOR_HEIGHT = BUTTON_SIZE + 2
  CHIPS_WIDTH      = 128

  def initialize(project)
    @project = project
  end

  attr_reader :project

  def flash(...)
    navigator.flash(...) if history.enabled?
  end

  def group(*buttons)
    buttons.each.with_index do |button, index|
      button.clicked do
        buttons.each.with_index {|b, i| b.active = i == index}
      end
    end
    buttons
  end

  def pressing?(key)
    pressing_keys.include? key
  end

  def name()
    self.class.name
  end

  def history()
    @history ||= Reight::History.new
  end

  def sprites()
    navigator.sprites
  end

  def icon(xi, yi, size)
    (@icon ||= {})[[xi, yi, size]] ||= createGraphics(size, size).tap do |g|
      g.beginDraw do
        g.copy r8.icons, xi * size, yi * size, size, size, 0, 0, size, size
      end
    end
    # TODO: ||= r8.icons.sub_image xi * size, yi * size, size, size
  end

  def activated()
    add_world world if world
    @setup ||= true.tap {setup}
  end

  def deactivated()
    remove_world world if world
  end

  def setup()
  end

  def draw()
    navigator.draw
  end

  def key_pressed()
    navigator.key_pressed
    pressing_keys.add key_code
  end

  def key_released()
    pressing_keys.delete key_code
  end

  def window_resized()
    navigator.window_resized
  end

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

  #def undo(flash: true) = nil
  #def redo(flash: true) = nil

  #def cut(  flash: true) = nil
  #def copy( flash: true) = nil
  #def paste(flash: true) = nil

  def inspect()
    "#<#{self.class.name}:0x#{object_id}>"
  end

  private

  def navigator()
    @navigator ||= Reight::Navigator.new self
  end

  def world()
    @world ||= SpriteWorld.new.tap do |w|
      sprites.each {w.add_sprite _1}
    end
  end

  def pressing_keys()
    @pressing_keys ||= Set.new
  end

end# App

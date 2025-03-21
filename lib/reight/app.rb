using Reight


class Reight::App

  SCREEN_WIDTH     = 400
  SCREEN_HEIGHT    = 224

  SPACE            = 6
  BUTTON_SIZE      = 12
  INDEX_SIZE       = 36
  NAVIGATOR_HEIGHT = BUTTON_SIZE + 2
  CHIPS_WIDTH      = 128

  PALETTE_COLORS   = %w[
    #00000000 #742f29 #ab5236 #f18459 #f7cca9 #ee044e #b8023f #7e2553
    #452d32   #5f574f #a28879 #c2c3c7 #fdf1e8 #f6acc5 #f277a8 #e40dab
    #1d2c53   #3363b0 #42a5a1 #56adff #64dff6 #bd9adf #83759c #644788
    #1e5359   #2d8750 #3eb250 #4fe436 #95f041 #f8ec27 #f3a207 #e26b02
  ]

  def initialize(project)
    @project = project
    @active  = false
  end

  attr_reader :project

  def label()
    self.class.name.split('::').last.gsub(/([a-z])([A-Z])/) {"#{$1} #{$2}"}
  end

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

  def active?()
    @active
  end

  def pressing?(key)
    pressing_keys.include? key
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
    @active  = true
  end

  def deactivated()
    @active = false
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

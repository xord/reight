using RubySketch


class Reight::App

  SPACE            = 8
  BUTTON_SIZE      = 12
  NAVIGATOR_HEIGHT = BUTTON_SIZE + 2

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
    sprites.each {|sp| addSprite sp}
  end

  def deactivate()
    sprites.each {|sp| removeSprite sp}
  end

  def draw()
  end

  def resized()
  end

  def keyPressed(key)
  end

  def keyReleased(key)
  end

  def undo(flash: true)
  end

  def redo(flash: true)
  end

  def inspect()
    "#<#{self.class.name}:#{object_id}>"
  end

end# App

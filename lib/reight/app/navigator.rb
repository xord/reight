using RubySketch


class Message

  def initialize()
    @priority = 0
  end

  attr_accessor :text

  def flash(str, priority: 1)
    return if priority < @priority
    @text, @priority = str, priority
    setTimeout 2, id: :messageFlash do
      @text, @priority = '', 0
    end
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw do
        next unless @text
        fill 255, 255, 255
        textAlign LEFT, CENTER
        drawText @text, 0, 0, sp.w, sp.h
      end
    end
  end

end# Message


class Navigator < App

  def flash(...) = message.flash(...)

  def activate()
    super
    apps[0].click
  end

  def draw()
    fill 50, 50, 50
    noStroke
    rect 0, 0, width, NAVIGATOR_HEIGHT
    sprite *sprites
  end

  def resized()
    margin = (NAVIGATOR_HEIGHT - BUTTON_SIZE) / 2
    apps.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = SPACE + sp.w * index
      sp.y = margin
    end
    message.sprite.tap do |sp|
      sp.y     = apps.last.sprite.y
      sp.left  = apps.last.sprite.right + SPACE
      sp.right = width - margin
      sp.h     = NAVIGATOR_HEIGHT
    end
  end

  def keyPressed(key)
  end

  def keyReleased(key)
  end

  private

  def sprites()
    [*apps, message].map {_1.sprite}
  end

  def apps()
    @apps ||= [
      Button.new(label: 'S') {switchApp SpriteEditor}
    ]
  end

  def message()
    @message ||= Message.new
  end

  def switchApp(klass)
    app        = r8.apps.find {_1.class == klass}
    r8.current = app if app
  end

end# Navigator

using RubySketch


class Reight::Navigator < Reight::App

  def flash(...) = message.flash(...)

  def activate()
    super
    spriteEditorButton.click
  end

  def draw()
    fill 50, 50, 50
    noStroke
    rect 0, 0, width, NAVIGATOR_HEIGHT
    sprite *sprites
  end

  def resized()
    margin = (NAVIGATOR_HEIGHT - BUTTON_SIZE) / 2
    appButtons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = SPACE + (sp.w + 1) * index
      sp.y = margin
    end
    historyButtons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = appButtons.last.sprite.right + SPACE + (sp.w + 1) * index
      sp.y = appButtons.last.sprite.y
    end
    message.sprite.tap do |sp|
      sp.x     = historyButtons.last.sprite.right + SPACE * 2
      sp.y     = historyButtons.last.sprite.y
      sp.right = width - margin
      sp.h     = NAVIGATOR_HEIGHT
    end
  end

  def keyPressed(key)
    case key
    when F1 then spriteEditorButton.click
    when F2 then    mapEditorButton.click
    end
  end

  private

  def sprites()
    [*appButtons, *historyButtons, message].map {_1.sprite}
  end

  def appButtons()
    @appButtons ||= [spriteEditorButton, mapEditorButton]
  end

  def spriteEditorButton()
    @spriteEditorButton ||= Reight::Button.new(name: 'Sprite Editor', label: 'S') do
      switchApp Reight::SpriteEditor
    end
  end

  def mapEditorButton()
    @mapEditorButton ||= Reight::Button.new(name: 'Map Editor', label: 'M') do
      switchApp Reight::MapEditor
    end
  end

  def historyButtons()
    @historyButtons ||= [
      Reight::Button.new(name: 'Undo', label: 'Un') {r8.current.undo flash: false},
      Reight::Button.new(name: 'Redo', label: 'Re') {r8.current.redo flash: false}
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


class Reight::Navigator::Message

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

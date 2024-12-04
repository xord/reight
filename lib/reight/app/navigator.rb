using Reight


class Reight::Navigator < Reight::App

  def flash(...) = message.flash(...)

  def activate()
    super
    sprite_editor_button.click
  end

  def draw()
    fill 50, 50, 50
    no_stroke
    rect 0, 0, width, NAVIGATOR_HEIGHT
    sprite *sprites
  end

  def window_resized()
    margin = (NAVIGATOR_HEIGHT - BUTTON_SIZE) / 2
    app_buttons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = SPACE + (sp.w + 1) * index
      sp.y = margin
    end
    history_buttons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x = app_buttons.last.sprite.right + SPACE + (sp.w + 1) * index
      sp.y = app_buttons.last.sprite.y
    end
    message.sprite.tap do |sp|
      sp.x     = history_buttons.last.sprite.right + SPACE * 2
      sp.y     = history_buttons.last.sprite.y
      sp.right = width - margin
      sp.h     = NAVIGATOR_HEIGHT
    end
  end

  def key_pressed()
    case key_code
    when F1 then sprite_editor_button.click
    when F2 then    map_editor_button.click
    end
  end

  private

  def sprites()
    [*app_buttons, *history_buttons, message].map {_1.sprite}
  end

  def app_buttons()
    @app_buttons ||= [sprite_editor_button, map_editor_button]
  end

  def sprite_editor_button()
    @sprite_editor_button ||= Reight::Button.new(name: 'Sprite Editor', label: 'S') do
      switch_app Reight::SpriteEditor
    end
  end

  def map_editor_button()
    @map_editor_button ||= Reight::Button.new(name: 'Map Editor', label: 'M') do
      switch_app Reight::MapEditor
    end
  end

  def history_buttons()
    @history_buttons ||= [
      Reight::Button.new(name: 'Undo', label: 'Un') {r8.current.undo flash: false},
      Reight::Button.new(name: 'Redo', label: 'Re') {r8.current.redo flash: false}
    ]
  end

  def message()
    @message ||= Message.new
  end

  def switch_app(klass)
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
    set_timeout 2, id: :message_flash do
      @text, @priority = '', 0
    end
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw do
        next unless @text
        fill 255, 255, 255
        text_align LEFT, CENTER
        draw_text @text, 0, 0, sp.w, sp.h
      end
    end
  end

end# Message

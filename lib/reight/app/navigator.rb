using Reight


class Reight::Navigator

  def initialize(app)
    @app, @visible = app, true
  end

  def flash(...) = message.flash(...)

  def visible=(visible)
    return if visible == @visible
    @visible = visible
    sprites.each {|sp| visible ? sp.show : sp.hide}
  end

  def visible? = @visible

  def sprites()
    [*app_buttons, *control_buttons, *history_buttons, *edit_buttons, message]
      .map &:sprite
  end

  def draw()
    return unless visible?
    fill 220
    no_stroke
    rect 0, 0, width, Reight::App::NAVIGATOR_HEIGHT
    sprite(*sprites)
  end

  def key_pressed()
    index = [F1, F2, F3, F4, F5].index(key_code)
    app_buttons[index].click if index
  end

  def window_resized()
    [app_buttons, control_buttons, history_buttons, edit_buttons]
      .flatten.map(&:sprite).each do |sp|
        sp.w = sp.h = Reight::App::NAVIGATOR_HEIGHT
        sp.y = 0
      end

    space = Reight::App::SPACE
    x     = space

    app_buttons.map {_1.sprite}.each do |sp|
      sp.x = x + 1
      x    = sp.right
    end.tap do
      x += space unless _1.empty?
    end

    control_buttons.map {_1.sprite}.each do |sp|
      sp.x = x + 1
      x    = sp.right
    end.tap do
      x += space unless _1.empty?
    end

    history_buttons.map {_1.sprite}.each do |sp|
      sp.x = x + 1
      x    = sp.right
    end.tap do
      x += space unless _1.empty?
    end

    edit_buttons.map {_1.sprite}.each do |sp|
      sp.x = x + 1
      x    = sp.right
    end.tap do
      x += space unless _1.empty?
    end

    message.sprite.tap do |sp|
      sp.x     = x + space
      sp.y     = 0
      sp.h     = Reight::App::NAVIGATOR_HEIGHT
      sp.right = width - space
    end
  end

  private

  def app_buttons()
    @app_buttons ||= [
      Reight::Button.new(name: 'Run',           icon: @app.icon(0, 0, 8)) {
        switch_app Reight::Runner
      },
      Reight::Button.new(name: 'Sprite Editor', icon: @app.icon(1, 0, 8)) {
        switch_app Reight::SpriteEditor
      },
      Reight::Button.new(name: 'Map Editor',    icon: @app.icon(2, 0, 8)) {
        switch_app Reight::MapEditor
      },
      Reight::Button.new(name: 'Sound Editor',  icon: @app.icon(3, 0, 8)) {
        switch_app Reight::SoundEditor
      },
    ]
  end

  def control_buttons()
    @control_buttons ||= [].tap do |buttons|
      buttons << Reight::Button.new(name: 'Restart Game', label: 'Re') {
        @app.restart
      } if @app.respond_to? :restart
    end
  end

  def history_buttons()
    @history_buttons ||= [].tap do |buttons|
      next unless @app.respond_to? :undo
      buttons << Reight::Button.new(name: 'Undo', icon: @app.icon(3, 1, 8)) {
        @app.undo flash: false
      }.tap {|b|
        b.enabled? {@app.history.can_undo?}
      }
      buttons << Reight::Button.new(name: 'Redo', icon: @app.icon(4, 1, 8)) {
        @app.redo flash: false
      }.tap {|b|
        b.enabled? {@app.history.can_redo?}
      }
    end
  end

  def edit_buttons()
    @edit_buttons ||= [].tap do |buttons|
      next unless @app.respond_to? :paste
      buttons << Reight::Button.new(name: 'Cut',   icon: @app.icon(0, 1, 8)) {
        @app.cut   flash: false
      }.tap {|b|
        b.enabled? {@app.can_cut?}
      }
      buttons << Reight::Button.new(name: 'Copy',  icon: @app.icon(1, 1, 8)) {
        @app.copy  flash: false
      }.tap {|b|
        b.enabled? {@app.can_copy?}
      }
      buttons << Reight::Button.new(name: 'Paste', icon: @app.icon(2, 1, 8)) {
        @app.paste flash: false
      }.tap {|b|
        b.enabled? {@app.can_paste?}
      }
    end
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
        fill 100
        text_align LEFT, CENTER
        draw_text @text, 0, 0, sp.w, sp.h
      end
    end
  end

end# Message

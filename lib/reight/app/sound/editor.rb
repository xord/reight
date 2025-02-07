using Reight


class Reight::SoundEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new self
  end

  def activated()
    super
    history.disable do
      tones[0].click
      tools[0].click
    end
  end

  def draw()
    background 200
    sprite(*sprites)
    super
  end

  def key_pressed()
    super
    case key_code
    when :space then canvas.sound.play
    when :b     then  brush.click
    when :e     then eraser.click
    when /^[#{(1..Reight::Sound::TONES.size).to_a.join}]$/
      tones[key_code.to_s.to_i - 1].click
    end
  end

  def window_resized()
    super
    tones.map(&:sprite).each.with_index do |sp, index|
      sp.w, sp.h = 30, BUTTON_SIZE
      sp.x       = SPACE + (sp.w + 1) * index
      sp.y       = NAVIGATOR_HEIGHT + SPACE
    end
    tools.map(&:sprite).each.with_index do |sp, index|
      sp.w = sp.h = BUTTON_SIZE
      sp.x        = SPACE + (sp.w + 1) * index
      sp.y        = height - (SPACE + sp.h)
    end
    canvas.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = tones.first.sprite.bottom + SPACE
      sp.right  = width  - SPACE
      sp.bottom = tools.first.sprite.y - SPACE
    end
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      in [:put_note,    ti, ni, _]    then canvas.sound.remove ti, ni
      in [:delete_note, ti, ni, tone] then canvas.sound.add    ti, ni, tone
      end
      self.flash 'Undo!' if flash
    end
  end

  def redo(flash: true)
    history.redo do |action|
      case action
      in [:put_note,    ti, ni, tone] then canvas.sound.add    ti, ni, tone
      in [:delete_note, ti, ni, _]    then canvas.sound.remove ti, ni
      end
      self.flash 'Redo!' if flash
    end
  end

  private

  def sprites()
    [*tones, *tools, canvas].map(&:sprite) + super
  end

  def tones()
    @tones ||= group(*Reight::Sound::TONES.map {|tone|
      name = tone.to_s.capitalize
      Reight::Button.new name: name, label: name do
        canvas.tone = tone
        flash "Tone: #{name}"
      end
    })
  end

  def tools()
    @tools ||= group brush, eraser
  end

  def brush  = @brush  ||= Brush.new(self)  {canvas.tool = _1}
  def eraser = @eraser ||= Eraser.new(self) {canvas.tool = _1}

end# SoundEditor

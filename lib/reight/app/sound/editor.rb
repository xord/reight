using Reight


class Reight::SoundEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new self
  end

  def setup()
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
    when ENTER then play_or_stop.click
    when :b    then  brush.click
    when :e    then eraser.click
    when /^[#{(1..Reight::Sound::Note::TONES.size).to_a.join}]$/
      tones[key_code.to_s.to_i - 1].click
    end
  end

  def window_resized()
    super
    index.sprite.tap do |sp|
      sp.w, sp.h = 32, BUTTON_SIZE
      sp.x       = SPACE
      sp.y       = NAVIGATOR_HEIGHT + SPACE
    end
    bpm.sprite.tap do |sp|
      sp.w, sp.h = 40, BUTTON_SIZE
      sp.x       = index.sprite.right + SPACE
      sp.y       = index.sprite.y
    end
    edits.map(&:sprite).each.with_index do |sp, i|
      sp.w, sp.h = 32, BUTTON_SIZE
      sp.x       = bpm.sprite.right + SPACE + (sp.w + 1) * i
      sp.y       = bpm.sprite.y
    end
    controls.map(&:sprite).each.with_index do |sp, i|
      sp.w, sp.h = 32, BUTTON_SIZE
      sp.x       = SPACE + (sp.w + 1) * i
      sp.y       = height - (SPACE + sp.h)
    end
    tools.map(&:sprite).each.with_index do |sp, i|
      sp.w = sp.h = BUTTON_SIZE
      sp.x        = controls.last.sprite.right + SPACE * 2 + (sp.w + 1) * i
      sp.y        = controls.last.sprite.y
    end
    tones.map(&:sprite).each.with_index do |sp, i|
      sp.w = sp.h = BUTTON_SIZE
      sp.x        = tools.last.sprite.right + SPACE * 2 + (sp.w + 1) * i
      sp.y        = tools.last.sprite.y
    end
    canvas.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = index.sprite.bottom + SPACE
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
    [index, bpm, *edits, *controls, *tools, *tones, canvas]
      .map(&:sprite) + super
  end

  def index()
    @index ||= Reight::Index.new do |index|
      canvas.sound = project.sounds[index] ||= Reight::Sound.new
    end
  end

  def bpm()
    @bpm ||= Reight::Text.new(
      canvas.sound.bpm, label: 'BPM ', regexp: /^\-?\d+$/
    ) do |str, text|
      bpm = str.to_i.clamp(0, Reight::Sound::BPM_MAX)
      next text.revert if bpm <= 0
      text.value = canvas.sound.bpm = bpm
    end.tap do |text|
      canvas.sound_changed {text.value = _1.bpm}
    end
  end

  def edits()
    @edits ||= [
      Reight::Button.new(name: 'Clear All Notes', label: 'Clear') {
        canvas.sound.clear
        canvas.save
      },
      Reight::Button.new(name: 'Delete Sound', label: 'Delete') {
        project.sounds.delete_at index.index
        canvas.sound = project.sounds[index.index] ||= Reight::Sound.new
        canvas.save
      },
    ]
  end

  def controls()
    @controls ||= [play_or_stop]
  end

  def play_or_stop()
    @play_or_stop ||= Reight::Button.new(name: 'Play Sound', label: 'Play') {|b|
      played  = -> {b.name, b.label = 'Stop Sound', 'Stop'}
      stopped = -> {b.name, b.label = 'Play Sound', 'Play'}
      if canvas.sound.playing?
        canvas.sound.stop
        stopped.call
      else
        canvas.sound.play {stopped.call}
        played.call
      end
    }
  end

  def tools()
    @tools ||= group brush, eraser
  end

  def brush  = @brush  ||= Brush.new(self)  {canvas.tool = _1}
  def eraser = @eraser ||= Eraser.new(self) {canvas.tool = _1}

  def tones()
    @tones ||= group(*Reight::Sound::Note::TONES.map.with_index {|tone, index|
      name  = tone.to_s.capitalize.gsub('_', '.')
      name += ' Wave' if name !~ /noise/i
      Reight::Button.new name: name, icon: icon(index, 3, 8) do
        canvas.tone = tone
      end
    })
  end

end# SoundEditor

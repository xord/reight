using Reight


class Reight::SoundEditor::Canvas

  include Reight::Hookable

  SEQUENCE_LEN = 32
  NOTE_HEIGHT  = 3

  def initialize(app)
    hook :sound_changed

    @app, @sound = app, app.project.sounds.first
    @scrolly     = NOTE_HEIGHT * Reight::Sound::Note::MAX / 3
  end

  attr_accessor :tone, :tool

  attr_reader :sound

  def sound=(sound)
    @sound = sound
    sound_changed! sound
  end

  def save()
    @app.project.save
  end

  def begin_editing(&block)
    @app.history.begin_grouping
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    @app.history.end_grouping
    save
  end

  def note_pos_at(x, y)
    sp         = sprite
    notew      = sp.w / SEQUENCE_LEN
    max        = Reight::Sound::Note::MAX
    time_index = (x / notew).floor
    note_index = max - ((@scrolly + y) / NOTE_HEIGHT).floor
    return time_index, note_index.clamp(0, max)
  end

  def put(x, y)
    time_i, note_i = note_pos_at x, y

    @sound.each_note(time_index: time_i)
      .select {|note,| (note.index == note_i) != (note.tone == tone)}
      .each   {|note,| remove_note time_i, note.index, note.tone}
    add_note time_i, note_i, tone

    @app.flash note_name y
  end

  def delete(x, y)
    time_i, note_i = note_pos_at x, y
    note           = @sound.at time_i, note_i
    return unless note

    remove_note time_i, note_i, note.tone

    @app.flash note_name y
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new.tap do |sp|
      pos = -> {return sp.mouse_x, sp.mouse_y}
      sp.draw           {draw}
      sp.mouse_pressed  {mouse_pressed( *pos.call, sp.mouse_button)}
      sp.mouse_released {mouse_released(*pos.call, sp.mouse_button)}
      sp.mouse_moved    {mouse_moved(   *pos.call)}
      sp.mouse_dragged  {mouse_dragged( *pos.call, sp.mouse_button)}
      sp.mouse_clicked  {mouse_clicked( *pos.call, sp.mouse_button)}
    end
  end

  private

  def add_note(ti, ni, tone)
    return if @sound.at(ti, ni)&.tone == tone
    @sound.add ti, ni, tone
    @sound.at(ti, ni)&.play 120
    @app.history.append [:put_note, ti, ni, tone]
  end

  def remove_note(ti, ni, tone)
    #@sound.at(ti, ni)&.play @sound.bpm
    @sound.remove ti, ni
    @app.history.append [:delete_note, ti, ni, tone]
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h

    no_stroke
    fill 0
    rect 0, 0, sp.w, sp.h

    translate 0, -@scrolly
    draw_grids
    draw_notes
    draw_note_names
  end

  TONE_COLORS = {
    sine:      5,
    triangle:  29,
    square:    19,
    sawtooth:  30,
    pulse12_5: 27,
    pulse25:   14,
    noise:     12
  }.transform_values {Reight::App::PALETTE_COLORS[_1]}

  GRID_COLORS = [1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1]
    .map.with_index {|n, i| i == 0 ? 100 : (n == 1 ? 80 : 60)}

  def draw_grids()
    sp    = sprite
    noteh = NOTE_HEIGHT
    Reight::Sound::Note::MAX.downto(0).with_index do |y, index|
      fill GRID_COLORS[index % GRID_COLORS.size]
      rect 0, y * noteh, sp.w, noteh
    end
  end

  def draw_notes()
    sp           = sprite
    notew, noteh = sp.w / SEQUENCE_LEN, NOTE_HEIGHT
    tones, max   = Reight::Sound::Note::TONES, Reight::Sound::Note::MAX
    @sound.each_note do |note, index|
      fill TONE_COLORS[note.tone]
      rect index * notew, (max - note.index) * noteh, notew, noteh
    end
  end

  def draw_note_names()
    fill 200
    text_size 4
    text_align LEFT, CENTER
    noteh = NOTE_HEIGHT
    max   = Reight::Sound::Note::MAX
    (0..Reight::Sound::Note::MAX).step(12).with_index do |y, index|
      text "C#{index}", 2, (max - y) * noteh, 10, noteh
    end
  end

  def mouse_pressed(...)
    tool&.canvas_pressed(...)  unless hand?
  end

  def mouse_released(...)
    tool&.canvas_released(...) unless hand?
  end

  def mouse_moved(x, y)
    tool&.canvas_moved(x, y)
    @app.flash note_name y
  end

  def mouse_dragged(...)
    if hand?
      sp        = sprite
      @scrolly -= sp.mouse_y - sp.pmouse_y
    else
      tool&.canvas_dragged(...)
    end
  end

  def mouse_clicked(...)
    tool&.canvas_clicked(...) unless hand?
  end

  def hand? = @app.pressing?(SPACE)

  def note_name(y)
    _, note_i = note_pos_at 0, y
    Reight::Sound::Note.new(note_i).to_s.split(':').first.capitalize
  end

end# Canvas

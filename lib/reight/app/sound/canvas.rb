using Reight


class Reight::SoundEditor::Canvas

  SEQUENCE_LEN = 32
  NOTE_HEIGHT  = 3

  def initialize(app)
    @app, @sound = app, app.project.sounds.first
    @scrolly     = NOTE_HEIGHT * Reight::Sound::Note::MAX / 3
  end

  attr_accessor :sound, :tone, :tool

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
    time_index = (x / notew).to_i
    note_index = ((sp.h - y + @scrolly) / NOTE_HEIGHT)
      .floor.clamp(0, Reight::Sound::Note::MAX)
    return time_index, note_index
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
    @sprite ||= Sprite.new.tap do |sp|
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
    @sound.at(ti, ni)&.play @sound.bpm
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

    translate 0, @scrolly
    draw_grids
    draw_notes
  end

  GRID_COLORS = [1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1]
    .map.with_index {|n, i| i == 0 ? 100 : (n == 1 ? 80 : 60)}

  def draw_grids()
    sp    = sprite
    noteh = NOTE_HEIGHT
    (0..Reight::Sound::Note::MAX).each.with_index do |y, index|
      fill GRID_COLORS[index % GRID_COLORS.size]
      rect 0, sp.h - y * noteh, sp.w, -noteh
    end
  end

  def draw_notes()
    sp           = sprite
    notew, noteh = sp.w / SEQUENCE_LEN, NOTE_HEIGHT
    @sound.each_note do |note, index|
      palette = 8 + Reight::Sound::Note::TONES.index(note.tone)
      fill @app.project.palette_colors[palette]
      rect index * notew, sp.h - note.index * noteh, notew, noteh
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
      @scrolly += sp.mouse_y - sp.pmouse_y
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

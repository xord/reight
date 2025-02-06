using Reight


class Reight::MusicEditor::Canvas

  NOTE_MIN   = 36
  NOTE_MAX   = NOTE_MIN + 64
  NOTES_LEN  = 32

  def initialize(app)
    @app, @music = app, Reight::Music.new(480)
  end

  attr_accessor :tone, :tool

  attr_reader :music, :tone, :tool

  def begin_editing(&block)
    @app.history.begin_grouping
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    @app.history.end_grouping
    #save
  end

  def note_pos_at(x, y)
    sp         = sprite
    notew      = sprite.w / NOTES_LEN
    noteh      = sp.h / (NOTE_MAX - NOTE_MIN)
    time_index = (x / notew).to_i
    note_index = NOTE_MIN + ((sp.h - y) / noteh).ceil.clamp(0, NOTE_MAX)
    return time_index, note_index
  end

  def put(x, y)
    time_i, note_i = note_pos_at x, y

    @music.each_note(time_index: time_i)
      .select {|note,| note.index == note_i || note.tone == tone}
      .each   {|note,| remove_note time_i, note.index, note.tone}
    add_note time_i, note_i, tone

    @app.flash note_name y
  end

  def delete(x, y)
    time_i, note_i = note_pos_at x, y
    note           = @music.at time_i, note_i
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
    @music.add ti, ni, tone
    @app.history.append [:put_note, ti, ni, tone]
  end

  def remove_note(ti, ni, tone)
    @music.remove ti, ni
    @app.history.append [:delete_note, ti, ni, tone]
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h

    no_stroke
    fill 0
    rect 0, 0, sp.w, sp.h

    draw_grids
    draw_notes
  end

  COLORS = [1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1]
    .map.with_index {|n, i| i == 0 ? 100 : (n == 1 ? 80 : 60)}

  def draw_grids()
    sp    = sprite
    noteh = sp.h / (NOTE_MAX - NOTE_MIN)
    (0..sp.h).step(noteh).each.with_index do |y, index|
      fill COLORS[index % COLORS.size]
      rect 0, sp.h - y, sp.w, -noteh
    end
  end

  def draw_notes()
    sp           = sprite
    notew, noteh = sp.w / NOTES_LEN, sp.h / (NOTE_MAX - NOTE_MIN)
    @music.each_note do |note, index|
      fill @app.project.palette_colors[8 + Reight::Music::TONES.index(note.tone)]
      rect index * notew, sp.h - (note.index - NOTE_MIN) * noteh, notew, noteh
    end
  end

  def mouse_pressed(...)
    tool&.canvas_pressed(...)
  end

  def mouse_released(...)
    tool&.canvas_released(...)
  end

  def mouse_moved(x, y)
    tool&.canvas_moved(x, y)
    @app.flash note_name y
  end

  def mouse_dragged(...)
    tool&.canvas_dragged(...)
  end

  def mouse_clicked(...)
    tool&.canvas_clicked(...)
  end

  def note_name(y)
    note_i, = note_pos_at 0, y
    Reight::Music::Note.new(note_i).to_s.split(':').first.capitalize
  end

end# Canvas

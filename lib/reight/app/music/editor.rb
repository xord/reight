using Reight


class Reight::MusicEditor < Reight::App

  def draw()
    background 200

    push do
      text_align LEFT, CENTER

      text_size 10
      fill 220; text "Music Editor", 150, 1, 200, height
      fill 150; text "Music Editor", 150, 0, 200, height

      text_size 8
      dots = '.' * (frame_count / 60 % 4).to_i
      fill 220; text "is under construction#{dots}", 150, 11, 200, height
      fill 150; text "is under construction#{dots}", 150, 10, 200, height
    end

    super
  end

end# MusicEditor

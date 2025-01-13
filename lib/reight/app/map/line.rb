using Reight


class Reight::MapEditor::Line < Reight::MapEditor::BrushBase

  def initialize(app, &block)
    super app, icon: app.icon(3, 2, 8), &block
    set_help left: name, right: 'Pick Chip'
  end

  def brush(cursor_from, cursor_to, chip)
    result = false
    canvas.begin_editing do
      fromx, fromy = cursor_from[...2]
      tox,   toy   = cursor_to[...2]
      dx           = fromx < tox ? chip.w : -chip.w
      dy           = fromy < toy ? chip.h : -chip.h
      if (tox - fromx).abs > (toy - fromy).abs
        (fromx..tox).step(dx).each do |x|
          y = map x, fromx, tox, fromy, toy
          y = y / chip.h * chip.h
          result |= put_or_delete_chip x, y, chip
        end
      else
        (fromy..toy).step(dy).each do |y|
          x = map y, fromy, toy, fromx, tox
          x = x / chip.w * chip.w
          result |= put_or_delete_chip x, y, chip
        end
      end
    end
    result
  end

end# Line

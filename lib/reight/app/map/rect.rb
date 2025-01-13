using Reight


class Reight::MapEditor::Rect < Reight::MapEditor::BrushBase

  def initialize(app, fill:, &block)
    @fill = fill
    super app, icon: app.icon(fill ? 5 : 4, 2, 8), &block
    set_help left: "#{fill ? 'Fill' : 'Stroke'} #{name}", right: 'Pick Chip'
  end

  def brush(cursor_from, cursor_to, chip)
    result = false
    canvas.begin_editing do
      fromx, fromy = cursor_from[...2]
      tox,   toy   = cursor_to[...2]
      fromx, tox   = tox, fromx if fromx > tox
      fromy, toy   = toy, fromy if fromy > toy
      (fromy..toy).step(chip.h).each do |y|
        (fromx..tox).step(chip.w).each do |x|
          next if !@fill && fromx < x && x < tox && fromy < y && y < toy
          result |= put_or_delete_chip x, y, chip
        end
      end
    end
    result
  end

end# Rect

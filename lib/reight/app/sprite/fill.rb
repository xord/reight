using Reight


class Reight::SpriteEditor::Fill < Reight::SpriteEditor::Tool

  def initialize(app, &block)
    super app, icon: app.icon(2, 2, 8), &block
    set_help left: 'Fill', right: 'Pick Color'
  end

  def canvas_pressed(x, y, button)
    return unless button == LEFT
    x, y           = [x, y].map &:to_i
    fx, fy, fw,    = canvas.frame
    sx, sy, sw, sh = canvas.selection || canvas.frame
    sx -= fx
    sy -= fy
    return unless (sx...(sx + sw)).include?(x) && (sy...(sy + sh)).include?(y)
    canvas.begin_editing
    count = 0
    canvas.update_pixels do |pixels|
      from = pixels[y * fw + x]
      to   = color(*canvas.color)
      rest = [[x, y]]
      until rest.empty?
        xx, yy = rest.shift
        next if pixels[yy * fw + xx] == to
        pixels[yy * fw + xx] = to
        count += 1
        _x, x_ = xx - 1, xx + 1
        _y, y_ = yy - 1, yy + 1
        rest << [_x, yy] if _x >= sx      && pixels[yy * fw + _x] == from
        rest << [x_, yy] if x_ <  sx + sw && pixels[yy * fw + x_] == from
        rest << [xx, _y] if _y >= sy      && pixels[_y * fw + xx] == from
        rest << [xx, y_] if y_ <  sy + sh && pixels[y_ * fw + xx] == from
      end
    end
    canvas.end_editing if count > 0
  end

  def canvas_clicked(x, y, button)
    pick_color x, y if button == RIGHT
  end

end# Fill

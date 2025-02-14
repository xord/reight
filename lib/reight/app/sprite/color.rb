using Reight


class Reight::SpriteEditor::Color < Reight::Button

  def initialize(color, &clicked)
    super name: '', &clicked
    @color = color
  end

  attr_reader :color

  def draw()
    sp = sprite

    fill(*color)
    no_stroke
    blend_mode REPLACE
    rect 0, 0, sp.w, sp.h

    if active?
      no_fill
      stroke_weight 1
      stroke '#000000'
      rect 2, 2, sp.w - 4, sp.h - 4
      stroke '#ffffff'
      rect 1, 1, sp.w - 2, sp.h - 2
    end
  end

end# Color

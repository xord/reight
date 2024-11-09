using RubySketch


class Reight::Button

  include Reight::Activatable
  include Reight::Clickable

  def initialize(name: nil, label: nil, &clicked)
    super()
    @name, @label = name, label
    self.clicked &clicked
  end

  def draw()
    sp = sprite

    noStroke
    fill 50, 50, 50
    rect 0, 1, sp.w, sp.h, 2
    fill(*(active? ? [200, 200, 200] : [150, 150, 150]))
    rect 0, 0, sp.w, sp.h, 2

    if @label
      textAlign CENTER, CENTER
      fill 100, 100, 100
      text @label, 0, 1, sp.w, sp.h
      fill 255, 255, 255
      text @label, 0, 0, sp.w, sp.h
    end
  end

  def hover(x, y)
  end

  alias click clicked!

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw         {draw}
      sp.mouseMoved   {hover sp.mouseX, sp.mouseY}
      sp.mouseClicked {clicked!}
    end
  end

end# Button

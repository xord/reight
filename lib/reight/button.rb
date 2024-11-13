using Reight


class Reight::Button

  include Reight::Activatable
  include Reight::Clickable
  include Reight::HasHelp

  def initialize(name: nil, label: nil, &clicked)
    @name, @label = name, label
    super()
    self.clicked &clicked
    self.clicked {r8.flash name}
  end

  def draw()
    sp = sprite

    no_stroke
    fill 50, 50, 50
    rect 0, 1, sp.w, sp.h, 2
    fill(*(active? ? [200, 200, 200] : [150, 150, 150]))
    rect 0, 0, sp.w, sp.h, 2

    if @label
      text_align CENTER, CENTER
      fill 100, 100, 100
      text @label, 0, 1, sp.w, sp.h
      fill 255, 255, 255
      text @label, 0, 0, sp.w, sp.h
    end
  end

  def hover(x, y)
    r8.flash help, priority: 0.5
  end

  alias click clicked!

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw          {draw}
      sp.mouse_moved   {hover sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked {clicked!}
    end
  end

end# Button

using RubySketch


class Canvas

  def initialize(image, path)
    @image, @path, @tool, @color = image, path, nil, [255, 255, 255]
    setFrame 0, 0, 32, 32
  end

  attr_accessor :tool, :color

  attr_reader :image, :x, :y, :w, :h

  def setFrame(x, y, w, h)
    @x, @y, @w, @h = [x, y, w, h].map &:floor
  end

  def paint(&block)
    image.beginDraw do |g|
      g.clip x, y, w, h
      g.push do
        g.translate x, y
        block.call g
      end
    end
    save
  end

  def updatePixels(&block)
    tmp = createGraphics w, h
    tmp.beginDraw do |g|
      g.copy image, x, y, w, h, 0, 0, w, h
    end
    tmp.updatePixels {|pixels| block.call pixels}
    image.beginDraw do |g|
      g.copy tmp, 0, 0, w, h, x, y, w, h
    end
    save
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      pos = -> {toImage sp.mouseX, sp.mouseY}
      sp.draw          {draw}
      sp.mousePressed  {tool&.mousePressed( *pos.call)}
      sp.mouseReleased {tool&.mouseReleased(*pos.call)}
      sp.mouseMoved    {tool&.mouseMoved(   *pos.call)}
      sp.mouseDragged  {tool&.mouseDragged( *pos.call)}
    end
  end

  private

  def toImage(x, y)
    return x, y unless @w && @h
    sp = sprite
    return x * (@w.to_f / sp.w), y * (@h.to_f / sp.h)
  end

  def save()
    image.save path
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h
    copy image, x, y, w, h, 0, 0, sp.w, sp.h if image && x && y && w && h

    scale sp.w / w, sp.h / h
    translate -x, -y
    noFill
    strokeWeight 0
    stroke 50, 50, 50
    shape grid 8
    stroke 100, 100, 100
    shape grid 16
    stroke 150, 150, 150
    shape grid 32
  end

  def grid(interval)
    (@grids ||= [])[interval] ||= createShape.tap do |sh|
      w, h = image.width, image.height
      sh.beginShape LINES
      (0..w).step(interval).each do |x|
        sh.vertex x, 0
        sh.vertex x, h
      end
      (0..h).step(interval).each do |y|
        sh.vertex 0, y
        sh.vertex w, y
      end
      sh.endShape
    end
  end

end# Canvas


class Tool

  def initialize(app, label = nil, &clicked)
    @app, @label, @clicked = app, label, clicked
  end

  attr_accessor :active

  attr_reader :app

  def canvas = app.canvas

  def mousePressed(x, y)
  end

  def mouseReleased(x, y)
  end

  def mouseMoved(x, y)
  end

  def mouseDragged(x, y)
  end

  def sprite()
    @sprite ||= Sprite.new(image: @icon).tap do |sp|
      sp.draw do |&draw|
        #tint active ? '#ffffff' : '#83769C'
        #draw.call
        fill active ? '#ffffff' : '#83769C'
        noStroke
        rect 0, 0, sp.w, sp.h
        fill active ? '#83769C' : '#ffffff'
        textAlign CENTER, CENTER
        text @label, 0, 0, sp.w, sp.h
      end
      sp.mouseClicked {@clicked.call self} if @clicked
    end
  end
end# ToolButton


class Hand < Tool

  def initialize(app, &block)
    super app, 'H', &block
  end

  def mousePressed(x, y)
    @canvasPos = createVector canvas.x, canvas.y
    @pressPos  = createVector x, y
  end

  def mouseDragged(x, y)
    xx = (@canvasPos.x - (x - @pressPos.x)).clamp 0, canvas.image.width  - 1
    yy = (@canvasPos.y - (y - @pressPos.y)).clamp 0, canvas.image.height - 1
    canvas.setFrame xx, yy, canvas.w, canvas.h
  end

end# Hand


class Brush < Tool

  def initialize(app, &block)
    super app, 'B', &block
    @size = 1
  end

  attr_reader :size

  def brush(x, y)
    canvas.paint do |g|
      g.noFill
      g.stroke *canvas.color
      g.strokeWeight size
      g.point x, y
    end
  end

  def mousePressed(...)
    brush(...)
  end

  def mouseDragged(...)
    brush(...)
  end

end# Brush


class Fill < Tool

  def initialize(app, &block)
    super app, 'F', &block
  end

  def mousePressed(x, y)
    x, y = [x, y].map &:to_i
    canvas.updatePixels do |pixels|
      w, h = canvas.w, canvas.h
      from = pixels[y * w + x]
      to   = color canvas.color
      rest = [[x, y]]
      until rest.empty?
        xx, yy = rest.shift
        next if pixels[yy * w + xx] == to
        pixels[yy * w + xx] = to
        _x, x_ = xx - 1, xx + 1
        _y, y_ = yy - 1, yy + 1
        rest << [x_, yy] if x_ <  w && pixels[yy * w + x_] == from
        rest << [_x, yy] if _x >= 0 && pixels[yy * w + _x] == from
        rest << [xx, y_] if y_ <  h && pixels[y_ * w + xx] == from
        rest << [xx, _y] if _y >= 0 && pixels[_y * w + xx] == from
      end
    end
  end

end# Fill


class Color

  def initialize(color, &clicked)
    @color, @clicked = color, clicked
  end

  attr_accessor :active

  attr_reader :color

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw do
        fill *color
        noStroke
        rect 0, 0, sp.w, sp.h
        if active
          noFill
          stroke '#ffffff'
          rect 0, 0, sp.w, sp.h
          stroke '#000000'
          rect 1, 1, sp.w - 1, sp.h - 1
        end
      end
      sp.mouseClicked &@clicked
    end
  end

end# Color


class SpriteEditor < App

  def canvas()
    @canvas ||= Canvas.new r8.project.spriteImage, r8.project.spriteImagePath
  end

  def history()
    @history ||= History.new
  end

  def useTool(tool)
    canvas.tool = tool
    tools.each {_1.active = _1 == tool}
  end

  def useColor(color)
    canvas.color = color
    colors.each {_1.active = _1.color == color}
  end

  def activate()
    super
    useTool  tools[0]
    useColor colors[7].color
  end

  def draw()
    background 100, 100, 100
    sprite *sprites
  end

  def resized()
    space, buttonSize = 8, 12
    colors.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = space + sp.w * (index % 8)
      sp.y = height - space - sp.h * (2 - index / 8)
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = colors.last.sprite.right + space + sp.w * index
      sp.y = colors.first.sprite.top
    end
    canvas.sprite.tap do |sp|
      sp.left   = space
      sp.top    = space
      sp.bottom = colors.first.sprite.top - space
      sp.w      = sp.h
    end
  end

  private

  def sprites()
    [canvas, *tools, *colors].map {_1.sprite}
  end

  def tools()
    @tools ||= [
      Hand.new(self)  {|self_| useTool self_},
      Brush.new(self) {|self_| useTool self_},
      Fill.new(self)  {|self_| useTool self_},
    ]
  end

  def colors()
    @colors ||= r8.project.paletteColors.map do |color|
      Color.new(color) {useColor color}
    end
  end

end# SpriteEditor

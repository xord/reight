require 'rubysketch'
using RubySketch


class Canvas
  def initialize(width, height)
    @w, @h = width, height
    @color = [255, 255, 255]
    @tool  = nil
    attach nil, 0, 0, 0, 0
  end

  attr_accessor :color, :tool

  def attach(image, x, y, w, h)
    @image, @ix, @iy, @iw, @ih = image, x, y, w, h
  end

  def paint(&block)
    @image.beginDraw do |g|
      g.clip @ix, @iy, @iw, @ih
      g.push do
        g.translate @ix, @iy
        block.call g
      end
    end
  end

  def updatePixels(&block)
    image = createGraphics @iw, @ih
    image.beginDraw do |g|
      g.copy @image, @ix, @iy, @iw, @ih, 0, 0, @iw, @ih
    end
    image.updatePixels {|pixels| block.call pixels, @iw, @ih}
    @image.beginDraw do |g|
      g.copy image, 0, 0, @iw, @ih, @ix, @iy, @iw, @ih
    end
  end

  def sprite()
    @sprite ||= Sprite.new(0, 0, @w, @h).tap do |sp|
      sp.draw do |&draw|
        next unless @image && @ix && @iy && @iw && @ih
        copy @image, @ix, @iy, @iw, @ih, 0, 0, sp.w, sp.h
      end
      mousePos = -> {toImage sp.mouseX, sp.mouseY}
      sp.mousePressed  {tool.mousePressed  self, *mousePos.call}
      sp.mouseReleased {tool.mouseReleased self, *mousePos.call}
      sp.mouseMoved    {tool.mouseMoved    self, *mousePos.call}
      sp.mouseDragged  {tool.mouseDragged  self, *mousePos.call}
    end
  end

  private

  def toImage(x, y)
    return x, y unless @iw && @ih
    sp = sprite
    return x * (@iw.to_f / sp.w), y * (@ih.to_f / sp.h)
  end
end# Canvas


class Tool
  def initialize(label = nil, &clicked)
    @label, @clicked = label, clicked
  end

  attr_accessor :active

  def mousePressed(canvas, x, y)
  end

  def mouseReleased(canvas, x, y)
  end

  def mouseMoved(canvas, x, y)
  end

  def mouseDragged(canvas, x, y)
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


class Brush < Tool
  def initialize(&block)
    super 'B', &block
    @size = 1
  end

  attr_reader :size

  def brush(canvas, x, y)
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
end# BrushButton


class Fill < Tool
  def initialize(&block)
    super 'F', &block
  end

  def mousePressed(canvas, x, y)
    x, y = [x, y].map &:to_i
    canvas.updatePixels do |pixels, w, h|
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
end# BrushButton


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


class SpriteEditor
  def useTool(tool)
    canvas.tool = tool
    tools.each {_1.active = _1 == tool}
  end

  def useColor(color)
    canvas.color = color
    colors.each {_1.active = _1.color == color}
  end

  def activate()
    sprites.each {|sp| addSprite sp}
    useTool  tools.first
    useColor colors.first.color
  end

  def deactivate()
    sprites.each {|sp| removeSprite sp}
  end

  def draw()
    background 100, 100, 100
    sprite *sprites
  end

  def resized()
    space, buttonSize = 4, 12
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = space
      sp.y = space + sp.h * index
    end
    colors.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = tools.first.sprite.right + space + sp.w * index
      sp.y = height - space - sp.h
    end
    canvas.sprite.tap do |sp|
      sp.left   = tools.first.sprite.right + space
      sp.top    = space
      sp.bottom = colors.first.sprite.top - space
      sp.w      = sp.h
    end
  end

  private

  def sprites()
    [canvas, *tools, *colors].map {_1.sprite}
  end

  def image()
    @image ||= createGraphics(1024, 1024).tap do |img|
      img.beginDraw {|g| g.background 0, 0, 0}
    end
  end

  def canvas()
    @canvas ||= Canvas.new(80, 80).tap do |c|
      c.attach image, 0, 0, 16, 16
    end
  end

  def tools()
    @tools ||= [
      Brush.new {|self_| useTool self_},
      Fill.new  {|self_| useTool self_},
    ]
  end

  def colors()
    @colors ||= %w[
      #000000 #1D2B53 #7E2553 #008751 #AB5236 #5F574F #C2C3C7 #FFF1E8
      #FF004D #FFA300 #FFEC27 #00E436 #29ADFF #83769C #FF77A8 #FFCCAA
    ].map do |color|
      Color.new(color) {useColor color}
    end
  end
end# SpriteEditor


setup do
  $editor = SpriteEditor.new
  $editor.activate
  size 256, 224
  setTitle 'Sprite Editor'
end

draw          {$editor.draw}
windowResized {$editor.resized}

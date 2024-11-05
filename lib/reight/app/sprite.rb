using RubySketch


class Button

  def initialize(label, &clicked)
    @label, @clickeds = label, []
    on_click &clicked
  end

  attr_accessor :active

  def on_click(&block)
    @clickeds.push block if block
  end

  def draw()
    sp = sprite

    noStroke
    fill 50, 50, 50
    rect 0, 1, sp.w, sp.h, 2
    fill(*(active ? [200, 200, 200] : [150, 150, 150]))
    rect 0, 0, sp.w, sp.h, 2

    textAlign CENTER, CENTER
    fill 100, 100, 100
    text @label, 0, 1, sp.w, sp.h
    fill 255, 255, 255
    text @label, 0, 0, sp.w, sp.h
  end

  def buttonClicked()
    @clickeds.each {_1.call self}
  end

  alias click buttonClicked

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw         {draw}
      sp.mouseClicked {buttonClicked}
    end
  end

end# Button


class Message

  def initialize()
    @text = "Sprite Editor"
  end

  attr_accessor :text

  def flash(str)
    @text = str
    setTimeout 3, id: :messageFlash do
      @text = ''
    end
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw do
        fill 255, 255, 255
        textAlign LEFT, CENTER
        drawText @text, 0, 0, sp.w, sp.h
      end
    end
  end

end# Message


class Canvas

  def initialize(app, image, path)
    @app, @image, @path       = app, image, path
    @tool, @color, @selection = nil, [255, 255, 255], nil

    @app.history.disable do
      setFrame 0, 0, 16, 16
    end
  end

  attr_accessor :tool, :color

  attr_reader :x, :y, :w, :h

  def width  = @image.width

  def height = @image.height

  def save()
    @image.save @path
  end

  def setFrame(x, y, w, h)
    old            = [@x, @y, @w, @h]
    new            = correctBounds x, y, w, h
    return if new == old
    @x, @y, @w, @h = new
    @app.history.push [:frame, old, new]
  end

  def select(x, y, w, h)
    old        = @selection
    new        = correctBounds x, y, w, h
    return if new == old
    @selection = new
    @app.history.push [:select, old, new]
  end

  def deselect()
    return if @selection == nil
    old, @selection = @selection, nil
    @app.history.push [:deselect, old]
  end

  def paint(&block)
    @image.beginDraw do |g|
      g.clip x, y, w, h
      g.push do
        g.translate x, y
        block.call g
      end
    end
  end

  def updatePixels(&block)
    tmp = createGraphics w, h
    tmp.beginDraw do |g|
      g.copy @image, x, y, w, h, 0, 0, w, h
    end
    tmp.updatePixels {|pixels| block.call pixels}
    @image.beginDraw do |g|
      g.copy tmp, 0, 0, w, h, x, y, w, h
    end
  end

  def captureFrame()
    createGraphics(w, h).tap do |g|
      g.beginDraw do
        g.copy @image, x, y, w, h, 0, 0, w, h
      end
    end
  end

  def applyFrame(image, x, y)
    @image.beginDraw do |g|
      w, h = image.width, image.height
      g.copy image, 0, 0, w, h, x, y, w, h
    end
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      pos = -> {toImage sp.mouseX, sp.mouseY}
      sp.draw          {draw}
      sp.mousePressed  {tool&.mousePressed( *pos.call)}
      sp.mouseReleased {tool&.mouseReleased(*pos.call)}
      sp.mouseMoved    {tool&.mouseMoved(   *pos.call)}
      sp.mouseDragged  {tool&.mouseDragged( *pos.call)}
      sp.mouseClicked  {tool&.mouseClicked}
    end
  end

  private

  def toImage(x, y)
    return x, y unless @w && @h
    sp = sprite
    return x * (@w.to_f / sp.w), y * (@h.to_f / sp.h)
  end

  def correctBounds(x, y, w, h)
    x2, y2 = x + w, y + h
    x, x2  = x2, x if x > x2
    y, y2  = y2, y if y > y2
    x, y   = x.floor, y.floor
    return x, y, (x2 - x).ceil, (y2 - y).ceil
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h
    copy @image, x, y, w, h, 0, 0, sp.w, sp.h if @image && x && y && w && h

    sx, sy = sp.w / w, sp.h / h
    scale sx, sy
    translate -x, -y
    noFill
    strokeWeight 0

    drawGrids
    drawSelection sx, sy
  end

  def drawGrids()
    push do
      stroke 50, 50, 50
      shape grid 8
      stroke 100, 100, 100
      shape grid 16
      stroke 150, 150, 150
      shape grid 32
    end
  end

  def grid(interval)
    (@grids ||= [])[interval] ||= createShape.tap do |sh|
      w, h = @image.width, @image.height
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

  def drawSelection(scaleX, scaleY)
    return unless @selection&.size == 4
    push do
      stroke 255, 255, 255
      shader selectionShader.tap {|sh|
        sh.set :time, frameCount.to_f / 60
        sh.set :scale, scaleX, scaleY
      }
=begin
      beginShape LINES
      x, y, w, h = @selection
      vertex x,     y,     x, 0
      vertex x + w, y,     x + w, 0
      vertex x + w, y,     x, 0
      vertex x + w, y + h, x + w, 0
      vertex x + w, y + h, x, 0
      vertex x,     y + h, x + w, 0
      vertex x,     y + h, x, 0
      vertex x,     y,     x + w, 0
      endShape
=end
      rect *@selection
    end
  end

  def selectionShader()
    @selectionShader ||= createShader nil, <<~END
      varying vec4  vertTexCoord;
      uniform float time;
      uniform vec2  scale;
      void main()
      {
        vec2 pos = vertTexCoord.xy * scale;
        float t  = floor(time * 4.) / 4.;
        float x  = mod( pos.x + time, 4.) < 2. ? 1. : 0.;
        float y  = mod(-pos.y + time, 4.) < 2. ? 1. : 0.;
        gl_FragColor = x != y ? vec4(0., 0., 0., 1.) : vec4(1., 1., 1., 1.);
      }
    END
  end

end# Canvas


class Navigator

  def initialize(app, image, size = 8, &selected)
    @app, @image, @selected = app, image, selected
    @offset = createVector

    @app.history.disable do
      setFrame 0, 0, size, size
    end
  end

  attr_reader :x, :y, :size

  def setFrame(x, y, w, h)
    raise 'Navigator: width != height' if w != h
    @x    = alignToGrid(x).clamp(0..@image.width)
    @y    = alignToGrid(y).clamp(0..@image.height)
    @size = w
    selected
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h
    translate(*clampOffset(@offset).to_a)
    image @image, 0, 0

    noFill
    stroke 255, 255, 255
    strokeWeight 1
    rect @x, @y, @size, @size
  end

  def mousePressed(x, y)
    @prevPos = createVector x, y
  end

  def mouseReleased(x, y)
    @offset = clampOffset @offset
  end

  def mouseDragged(x, y)
    pos      = createVector x, y
    @offset += pos - @prevPos if @prevPos
    @prevPos = pos
  end

  def mouseClicked(x, y)
    setFrame(
      -@offset.x + alignToGrid(x),
      -@offset.y + alignToGrid(y),
      size,
      size)
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw          {draw}
      sp.mousePressed  {mousePressed  sp.mouseX, sp.mouseY}
      sp.mouseReleased {mouseReleased sp.mouseX, sp.mouseY}
      sp.mouseDragged  {mouseDragged  sp.mouseX, sp.mouseY}
      sp.mouseClicked  {mouseClicked  sp.mouseX, sp.mouseY}
    end
  end

  private

  def clampOffset(offset)
    sp = sprite
    x  = offset.x.clamp(-(@image.width  - sp.w)..0)
    y  = offset.y.clamp(-(@image.height - sp.h)..0)
    createVector alignToGrid(x), alignToGrid(y)
  end

  def alignToGrid(n)
    n.to_i / 8 * 8
  end

  def selected()
    @selected.call @x, @y, @size, @size
  end

end# Navigator


class Tool < Button

  def initialize(app, label = nil, &clicked)
    super label, &clicked
    @app = app
    on_click {app.flash name}
  end

  attr_reader :app

  def name    = self.class.name

  def canvas  = app.canvas

  def history = app.history

  def beginEditing()
    @before = canvas.captureFrame
  end

  def endEditing()
    canvas.save
    c = canvas
    history.push [:capture, @before, c.captureFrame, c.x, c.y] if @before
  end

  def mousePressed(x, y)
  end

  def mouseReleased(x, y)
  end

  def mouseMoved(x, y)
  end

  def mouseDragged(x, y)
  end

  def mouseClicked()
  end

end# Tool


class Select < Tool

  def initialize(app, &block)
    super app, 'S', &block
  end

  def select(x, y)
    canvas.select @x, @y, x - @x, y - @y
  end

  def mousePressed(x, y)
    @x, @y = x, y
    select x, y
  end

  def mouseDragged(x, y)
    app.undo
    select x, y
  end

  def mouseClicked()
    app.undo
    canvas.deselect
  end

end# Select


class Brush < Tool

  def initialize(app, &block)
    super app, 'B', &block
    @size = 1
  end

  attr_accessor :size

  def brush(x, y)
    canvas.paint do |g|
      g.noFill
      g.stroke *canvas.color
      g.strokeWeight size
      g.point x, y
    end
  end

  def mousePressed(...)
    beginEditing
    brush(...)
  end

  def mouseReleased(...)
    endEditing
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
    beginEditing
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
    endEditing
  end

end# Fill


class Shape < Tool

  def initialize(app, fun, fill, &block)
    super app, "#{fun[0].capitalize}#{fill ? :f : :s}", &block
    @fun, @fill = fun, fill
  end

  def name = "#{@fill ? :Fill : :Stroke} #{@fun.capitalize}"

  def drawRect(x, y)
    beginEditing
    canvas.paint do |g|
      @fill ? g.fill(*canvas.color) : g.noFill
      g.stroke(*canvas.color)
      g.rectMode    CORNER
      g.ellipseMode CORNER
      g.send @fun, @x, @y, x - @x, y - @y
    end
    endEditing
  end

  def mousePressed(x, y)
    @x, @y = x, y
    drawRect x, y
  end

  def mouseDragged(x, y)
    app.undo
    drawRect x, y
  end

end# Shape


class Color < Button

  def initialize(color, &clicked)
    super '', &clicked
    @color = color
  end

  attr_reader :color

  def draw()
    sp = sprite

    fill *color
    noStroke
    rect 0, 0, sp.w, sp.h

    if active
      noFill
      strokeWeight 1
      stroke '#000000'
      rect 2, 2, sp.w - 4, sp.h - 4
      stroke '#ffffff'
      rect 1, 1, sp.w - 2, sp.h - 2
    end
  end

end# Color


class SpriteEditor < App

  def canvas()
    @canvas ||= Canvas.new self, r8.project.spriteImage, r8.project.spriteImagePath
  end

  def history()
    @history ||= History.new
  end

  def flash(text)
    message.flash text
  end

  def activate()
    super
    history.disable do
      spriteSizes[0].click
      colors[7].click
      tools[1].click
      brushSizes[0].click
    end
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
      sp.y = height - (space + sp.h * (2 - index / 8))
    end
    historyButtons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = colors.last.sprite.right + space + (sp.w + 1) * index
      sp.y = colors.first.sprite.top
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = historyButtons.last.sprite.right + space + (sp.w + 1) * index
      sp.y = historyButtons.first.sprite.top
    end
    brushSizes.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = tools.first.sprite.x + (sp.w + 1) * index
      sp.y = tools.first.sprite.bottom + 2
    end
    spriteSizes.reverse.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = width - (space + sp.w * (index + 1) + index)
      sp.y = space
    end
    navigator.sprite.tap do |sp|
      sp.w      = 80
      sp.x      = width - (space + sp.w)
      sp.top    = spriteSizes.first.sprite.bottom + space
      sp.bottom = colors.first.sprite.top - space
    end
    canvas.sprite.tap do |sp|
      sp.x     = space
      sp.y     = navigator.sprite.y
      sp.right = navigator.sprite.left - space
      sp.h     = sp.w
    end
    message.sprite.tap do |sp|
      sp.left  = space
      sp.right = spriteSizes.first.sprite.left - space
      sp.h     = 8
      sp.y     = canvas.sprite.top - (space + sp.h)
    end
  end

  def keyPressed(key)
    case key
    when LEFT  then navigator.x -= navigator.size
    when RIGHT then navigator.x += navigator.size
    when UP    then navigator.y -= navigator.size
    when DOWN  then navigator.y += navigator.size
    end
  end

  def undo()
    history.undo do |action|
      case action
      in [:frame, [x, y, w, h], _]       then navigator.setFrame x, y, w, h
      in [:capture, before, after, x, y] then canvas.applyFrame before, x, y
      in [  :select, sel, _]             then sel ? canvas.select(*sel) : canvas.deselect
      in [:deselect, sel]                then canvas.select *sel
      end
    end
  end

  def redo()
    history.redo do |action|
      case action
      in [:frame, _, [x, y, w, h]]       then navigator.setFrame x, y, w, h
      in [:capture, before, after, x, y] then canvas.applyFrame after, x, y
      in [  :select, _, sel]             then canvas.select *sel
      in [:deselect, _]                  then canvas.deselect
      end
    end
  end

  def inspect()
    "#<#{self.class.name}:#{object_id}>"
  end

  private

  def sprites()
    [
      message,
      *spriteSizes,
      canvas,
      navigator,
      *colors,
      *historyButtons,
      *tools,
      *brushSizes
    ].map {_1.sprite}
  end

  def message()
    @message ||= Message.new
  end

  def spriteSizes()
    @spriteSizes ||= group(
      Button.new(8)  {navigator.setFrame navigator.x, navigator.y, 8,  8},
      Button.new(16) {navigator.setFrame navigator.x, navigator.y, 16, 16},
      Button.new(32) {navigator.setFrame navigator.x, navigator.y, 32, 32}
    )
  end

  def navigator()
    @navigator ||= Navigator.new self, r8.project.spriteImage do |x, y, w, h|
      canvas.setFrame x, y, w, h
    end
  end

  def historyButtons()
    @historyButtons ||= [
      Button.new('Un') {flash 'Undo!'; undo},
      Button.new('Re') {flash 'Redo!'; self.redo},
    ]
  end

  def tools()
    @tools ||= group(
      Select.new(self)                 {|select|  canvas.tool = select},
      brush,
      Fill.new(self)                   {|fill|    canvas.tool = fill},
      Shape.new(self, :rect,    false) {|rect|    canvas.tool = rect},
      Shape.new(self, :rect,    true)  {|rect|    canvas.tool = rect},
      Shape.new(self, :ellipse, false) {|ellipse| canvas.tool = ellipse},
      Shape.new(self, :ellipse, true)  {|ellipse| canvas.tool = ellipse},
    )
  end

  def brush()
    @brush ||= Brush.new(self) {|brush| canvas.tool = brush}
  end

  def brushSizes()
    @btushSizes ||= group(
      Button.new(1)  {brush.size = 1},
      Button.new(2)  {brush.size = 2},
      Button.new(3)  {brush.size = 3},
      Button.new(5)  {brush.size = 5},
      Button.new(10) {brush.size = 10}
    )
  end

  def colors()
    @colors ||= r8.project.paletteColors.map do |color|
      Color.new(color) {canvas.color = color}
    end.then {|buttons| group *buttons}
  end

  def group(*buttons)
    buttons.each.with_index do |button, index|
      button.on_click do
        buttons.each.with_index {|b, i| b.active = i == index}
      end
    end
    buttons
  end

end# SpriteEditor

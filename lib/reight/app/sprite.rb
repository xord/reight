using RubySketch


class Button

  include Activatable
  include Clickable

  def initialize(label, &clicked)
    super()
    @label = label
    self.clicked &clicked
  end

  def draw()
    sp = sprite

    noStroke
    fill 50, 50, 50
    rect 0, 1, sp.w, sp.h, 2
    fill(*(active? ? [200, 200, 200] : [150, 150, 150]))
    rect 0, 0, sp.w, sp.h, 2

    textAlign CENTER, CENTER
    fill 100, 100, 100
    text @label, 0, 1, sp.w, sp.h
    fill 255, 255, 255
    text @label, 0, 0, sp.w, sp.h
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


class Message

  def initialize()
    @priority = 0
  end

  attr_accessor :text

  def flash(str, priority: 1)
    return if priority < @priority
    @text, @priority = str, priority
    setTimeout 3, id: :messageFlash do
      @text, @priority = '', 0
    end
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      sp.draw do
        next unless @text
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

  attr_accessor :tool

  attr_reader :x, :y, :w, :h, :color, :selection

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

  def frame = [x, y, w, h]

  def color=(color)
    return if color == @color
    @color = color
    colorChanged!
  end

  def select(x, y, w, h)
    old        = @selection
    new        = correctBounds x, y, w, h
    return if new == old
    @selection = new
    @app.history.push [:select, old, new]
  end

  def selection()
    xrange, yrange = x..(x + w), y..(y + h)
    sx, sy, sw, sh = @selection
    return nil unless
      xrange.include?(sx) && xrange.include?(sx + sw) &&
      yrange.include?(sy) && yrange.include?(sy + sh)
    @selection
  end

  def deselect()
    return if @selection == nil
    old, @selection = @selection, nil
    @app.history.push [:deselect, old]
  end

  def paint(&block)
    @image.beginDraw do |g|
      g.clip(*(selection || frame))
      g.push do
        g.translate x, y
        block.call g
      end
    end
  end

  def updatePixels(&block)
    tmp = subImage x, y, w, h
    tmp.updatePixels {|pixels| block.call pixels}
    @image.beginDraw do |g|
      g.copy tmp, 0, 0, w, h, x, y, w, h
    end
  end

  def subImage(x, y, w, h)
    createGraphics(w, h).tap do |g|
      g.beginDraw {g.copy @image, x, y, w, h, 0, 0, w, h}
    end
  end

  def pixelAt(x, y)
    img = subImage x, y, 1, 1
    img.loadPixels
    c = img.pixels[0]
    [red(c), green(c), blue(c), alpha(c)].map &:to_i
  end

  def clear(frame, color: [0, 0, 0])
    paint do |g|
      g.fill(*color)
      g.noStroke
      g.rect(*frame)
    end
  end

  def beginEditing(&block)
    @before = captureFrame
    block.call if block
  ensure
    endEditing if block
  end

  def endEditing()
    return unless @before
    save
    @app.history.push [:capture, @before, captureFrame, x, y]
  end

  def captureFrame(frame = self.frame)
    x, y, w, h = frame
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

  def colorChanged(&block)
    (@colorChangeds ||= []).push block if block
  end

  def colorChanged!()
    @colorChangeds&.each {_1.call color}
  end

  def sprite()
    @sprite ||= Sprite.new.tap do |sp|
      pos = -> {toImage sp.mouseX, sp.mouseY}
      sp.draw          {draw}
      sp.mousePressed  {tool&.canvasPressed( *pos.call, sp.mouseButton)}
      sp.mouseReleased {tool&.canvasReleased(*pos.call, sp.mouseButton)}
      sp.mouseMoved    {tool&.canvasMoved(   *pos.call)}
      sp.mouseDragged  {tool&.canvasDragged( *pos.call, sp.mouseButton)}
      sp.mouseClicked  {tool&.canvasClicked( *pos.call, sp.mouseButton)}
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
    @app      = app
    @subTools = nil
    self.clicked {app.flash name}
  end

  attr_accessor :subTools

  attr_reader :app

  def name    = self.class.name

  def help    = name

  def canvas  = app.canvas

  def history = app.history

  def canvasPressed(x, y, button)
  end

  def canvasReleased(x, y, button)
  end

  def canvasMoved(x, y)
  end

  def canvasDragged(x, y, button)
  end

  def canvasClicked(x, y, button)
  end

  def hover(x, y)
    app.flash help, priority: 0.5
  end

  def pickColor(x, y)
    canvas.color = canvas.pixelAt x, y
  end

end# Tool


class Select < Tool

  def initialize(app, &block)
    super app, 'S', &block
  end

  def moveOrSelect(x, y)
    x0, y0 = @pressPos&.to_a || return
    if @moving
      sx, sy, sw, sh = canvas.selection
      dx, dy         = (x - x0).to_i, (y - y0).to_i
      history.group do
        canvas.beginEditing do
          image = canvas.captureFrame [sx, sy, sw, sh]
          app.clearCanvas sx, sy, sw, sh
          canvas.applyFrame image, sx + dx, sy + dy
          canvas.select sx + dx, sy + dy, sw, sh
        end
      end
    else
      canvas.select canvas.x + x0, canvas.y + y0, x - x0, y - y0
    end
  end

  def canvasPressed(x, y, button)
    @pressPos = createVector x, y
    @moving   = button == LEFT && isInSelection?(x, y)
    moveOrSelect x, y
  end

  def canvasReleased(x, y, button)
    @pressPos = nil
    @moving   = false
  end

  def canvasDragged(x, y, button)
    app.undo flash: false
    moveOrSelect x, y
  end

  def canvasClicked(x, y, button)
    app.undo flash: false if button == LEFT
    canvas.deselect
  end

  private

  def isInSelection?(x, y)
    return false unless sel = canvas.selection
    sx, sy, sw, sh = sel
    (sx..(sx + sw)).include?(canvas.x + x) && (sy..(sy + sh)).include?(canvas.y + y)
  end

end# Select


class Brush < Tool

  def initialize(app, &block)
    super app, 'B', &block
    @size = 1
  end

  attr_accessor :size

  def brush(x, y, button)
    canvas.paint do |g|
      g.noFill
      g.stroke *canvas.color
      g.strokeWeight size
      g.point x, y
    end
  end

  def canvasPressed(x, y, button)
    return unless button == LEFT
    canvas.beginEditing
    brush x, y, button
  end

  def canvasReleased(x, y, button)
    return unless button == LEFT
    canvas.endEditing
  end

  def canvasDragged(x, y, button)
    return unless button == LEFT
    brush x, y, button
  end

  def canvasClicked(x, y, button)
    pickColor x, y if button == RIGHT
  end

end# Brush


class Fill < Tool

  def initialize(app, &block)
    super app, 'F', &block
  end

  def canvasPressed(x, y, button)
    return unless button == LEFT
    x, y           = [x, y].map &:to_i
    fx, fy, fw, fh = canvas.frame
    sx, sy, sw, sh = canvas.selection || canvas.frame
    sx -= fx
    sy -= fy
    return unless (sx...(sx + sw)).include?(x) && (sy...(sy + sh)).include?(y)
    canvas.beginEditing
    count = 0
    canvas.updatePixels do |pixels|
      from = pixels[y * fw + x]
      to   = color *canvas.color
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
    canvas.endEditing if count > 0
  end

  def canvasClicked(x, y, button)
    pickColor x, y if button == RIGHT
  end

end# Fill


class Shape < Tool

  def initialize(app, shape, fill, &block)
    super app, "#{shape[0].capitalize}#{fill ? :f : :s}", &block
    @shape, @fill = shape, fill
  end

  def name = "#{@fill ? :Fill : :Stroke} #{@shape.capitalize}"

  def drawShape(x, y)
    canvas.beginEditing do
      canvas.paint do |g|
        @fill ? g.fill(*canvas.color) : g.noFill
        g.stroke(*canvas.color)
        g.rectMode    CORNER
        g.ellipseMode CORNER
        g.send @shape, @x, @y, x - @x, y - @y
      end
    end
  end

  def canvasPressed(x, y, button)
    return unless button == LEFT
    @x, @y = x, y
    drawShape x, y
  end

  def canvasDragged(x, y, button)
    return unless button == LEFT
    app.undo flash: false
    drawShape x, y
  end

  def canvasClicked(x, y, button)
    pickColor x, y if button == RIGHT
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

    if active?
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
    @canvas ||= Canvas.new(
      self,
      r8.project.spriteImage,
      r8.project.spriteImagePath
    ).tap do |canvas|
      canvas.colorChanged {updateActiveColor}
    end
  end

  def history()
    @history ||= History.new
  end

  def flash(text, **kwargs)
    message.flash text, **kwargs if history.enabled?
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
    editButtons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = colors.last.sprite.right + space + (sp.w + 1) * index
      sp.y = colors.first.sprite.top
    end
    historyButtons.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = editButtons.first.sprite.x + (sp.w + 1) * index
      sp.y = editButtons.last.sprite.bottom + 2
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = sp.h = buttonSize
      sp.x = editButtons.last.sprite.right + space + (sp.w + 1) * index
      sp.y = editButtons.first.sprite.top
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
    pressingKeys.add key
    nav              = navigator
    shift, ctrl, cmd = %i[shift control command].map {pressing? _1}
    case key
    when LEFT  then nav.setFrame nav.x - nav.size, nav.y, nav.size, nav.size
    when RIGHT then nav.setFrame nav.x + nav.size, nav.y, nav.size, nav.size
    when UP    then nav.setFrame nav.x, nav.y - nav.size, nav.size, nav.size
    when DOWN  then nav.setFrame nav.x, nav.y + nav.size, nav.size, nav.size
    when :c    then copy  if ctrl || cmd
    when :x    then cut   if ctrl || cmd
    when :v    then paste if ctrl || cmd
    when :z    then shift ? self.redo : undo if ctrl || cmd
    when :s    then select.click
    when :b    then  brush.click
    when :f    then   fill.click
    when :r    then (shift ? fillRect    : strokeRect   ).click
    when :e    then (shift ? fillEllipse : strokeEllipse).click
    end
  end

  def keyReleased(key)
    pressingKeys.delete key
  end

  def copy(flash: true)
    sel   = canvas.selection || canvas.frame
    image = canvas.captureFrame(sel) || return
    x, y, = sel
    @copy = [image, x - canvas.x, y - canvas.y]
    self.flash 'Copy!' if flash
  end

  def cut(flash: true)
    copy flash: false
    image, x, y = @copy || return
    canvas.beginEditing do
      clearCanvas x, y, image.width, image.height
    end
    self.flash 'Cut!' if flash
  end

  def paste(flash: true)
    image, x, y = @copy || return
    w, h        = image.width, image.height
    history.group do
      canvas.deselect
      canvas.beginEditing do
        canvas.paint do |g|
          g.copy image, 0, 0, w, h, x, y, w, h
        end
      end
      canvas.select canvas.x + x, canvas.y + y, w, h
    end
    self.flash 'Paste!' if flash
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      in [:frame, [x, y, w, h], _]       then navigator.setFrame x, y, w, h
      in [:capture, before, after, x, y] then canvas.applyFrame before, x, y
      in [  :select, sel, _]             then sel ? canvas.select(*sel) : canvas.deselect
      in [:deselect, sel]                then canvas.select *sel
      end
      self.flash 'Undo!' if flash
    end
  end

  def redo(flash: true)
    history.redo do |action|
      case action
      in [:frame, _, [x, y, w, h]]       then navigator.setFrame x, y, w, h
      in [:capture, before, after, x, y] then canvas.applyFrame after, x, y
      in [  :select, _, sel]             then canvas.select *sel
      in [:deselect, _]                  then canvas.deselect
      end
      self.flash 'Redo!' if flash
    end
  end

  def clearCanvas(x, y, w, h)
    canvas.clear [x, y, w, h], color: colors.first.color
  end

  def setBrushSize(size)
    brush.size = size
    flash "Brush Size #{size}"
  end

  def inspect()
    "#<#{self.class.name}:#{object_id}>"
  end

  private

  def pressingKeys()
    @pressingKeys ||= Set.new
  end

  def pressing?(key)
    pressingKeys.include? key
  end

  def sprites()
    [
      message,
      *spriteSizes,
      canvas,
      navigator,
      *colors,
      *editButtons,
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

  def editButtons()
    @editButtons ||= [
      Button.new('Co') {copy},
      Button.new('Cu') {cut},
      Button.new('Pa') {paste},
    ]
  end

  def historyButtons()
    @historyButtons ||= [
      Button.new('Un') {undo},
      Button.new('Re') {self.redo},
    ]
  end

  def tools()
    @tools ||= group(select, brush, fill, strokeRect, fillRect, strokeEllipse, fillEllipse)
  end

  def select        = @select        ||= Select.new(self)                 {canvas.tool = _1}
  def brush         = @brush         ||= Brush.new(self)                  {canvas.tool = _1}
  def fill          = @fill          ||= Fill.new(self)                   {canvas.tool = _1}
  def strokeRect    = @strokeRect    ||= Shape.new(self, :rect,    false) {canvas.tool = _1}
  def fillRect      = @fillRect      ||= Shape.new(self, :rect,    true)  {canvas.tool = _1}
  def strokeEllipse = @strokeEllipse ||= Shape.new(self, :ellipse, false) {canvas.tool = _1}
  def fillEllipse   = @fillEllipse   ||= Shape.new(self, :ellipse, true)  {canvas.tool = _1}

  def brushSizes()
    @brushSizes ||= group(
      Button.new(1)  {setBrushSize 1},
      Button.new(2)  {setBrushSize 2},
      Button.new(3)  {setBrushSize 3},
      Button.new(5)  {setBrushSize 5},
      Button.new(10) {setBrushSize 10}
    )
  end

  def colors()
    @colors ||= r8.project.paletteColors.map {|color|
      rgb = self.color(color)
        .then {[red(_1), green(_1), blue(_1), alpha(_1)]}.map &:to_i
      Color.new(rgb) {canvas.color = rgb}
    }
  end

  def updateActiveColor()
    colors.each do |button|
      button.active = button.color == canvas.color
    end
  end

  def group(*buttons)
    buttons.each.with_index do |button, index|
      button.clicked do
        buttons.each.with_index {|b, i| b.active = i == index}
      end
    end
    buttons
  end

end# SpriteEditor

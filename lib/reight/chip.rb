using Reight


class Reight::Chip

  include Comparable

  def initialize(id, image, x, y, w, h, pos: nil, shape: nil, sensor: nil)
    @id, @image, @x, @y, @w, @h, @pos, @shape, @sensor =
     id,  image,  x,  y,  w,  h,  pos,  shape, (sensor || false)
  end

  attr_accessor :shape

  attr_writer :sensor

  attr_reader :id, :image, :x, :y, :w, :h, :pos

  def frame   = [x, y, w, h]

  def sensor? = @sensor

  def empty?()
    pixels.all? {red(_1) == 0 && green(_1) == 0 && blue(_1) == 0}
  end

  def with(**kwargs)
    id, image, x, y, w, h, pos, shape, sensor =
      kwargs.values_at :id, :image, :x, :y, :w, :h, :pos, :shape, :sensor
    #kwargs => {id:, image:, x:, y:, w:, h:, pos:, shape:, sensor:}
    self.class.new(
      id    || @id,
      image || @image,
      x     || @x,
      y     || @y,
      w     || @w,
      h     || @h,
      pos:    kwargs.key?(:pos)    ? pos    : @pos,
      shape:  kwargs.key?(:shape)  ? shape  : @shape,
      sensor: kwargs.key?(:sensor) ? sensor : @sensor)
  end

  def to_sprite()
    physics, shape =
      case @shape
      when :rect   then [true,  nil]
      when :circle then [true,  RubySketch::Circle.new(0, 0, w)]
      else              [false, nil]
      end
    Reight::Sprite.new(
      0, 0, w, h, chip: self,
      image: image, offset: [x, y], shape: shape, physics: physics
    ).tap do |sp|
      sp.x, sp.y = pos.x, pos.y if pos
      if physics
        sp.sensor = true if sensor?
        sp.fix_angle
      end
    end
  end

  def to_hash()
    {
      id: id, x: x, y: y, w: w, h: h
    }.tap do |h|
      h[:pos]    = pos.to_a(2) if pos
      h[:shape]  = shape       if shape
      h[:sensor] = true        if sensor?
    end
  end

  def <=>(o)
    a =                  [@id, @image.object_id, @x, @y, @w, @h, @pos, @shape, @sensor]
    b = o.instance_eval {[@id, @image.object_id, @x, @y, @w, @h, @pos, @shape, @sensor]}
    a <=> b
  end

  def self.restore(hash, image)
    id, x, y, w, h, pos, shape, sensor =
      hash.values_at :id, :x, :y, :w, :h, :pos, :shape, :sensor
    #hash => {id:, x:, y:, w:, h:, pos:, shape:, sensor:}
    new(
      id, image, x, y, w, h, pos: pos&.then {create_vector(*_1)},
      shape: shape&.to_sym, sensor: sensor || false)
  end

  private

  def pixels()
    g = createGraphics w, h
    g.beginDraw do
      g.copy image, x, y, w, h, 0, 0, w, h
    end
    g.load_pixels
    g.pixels
  end

end# Chip


class Reight::ChipList

  include Comparable

  def initialize(image)
    @image = image
    @next_id, @id2chip, @frame2chip = 1, {}, {}
  end

  attr_reader :image

  def at(x, y, w, h)
    @frame2chip[[x, y, w, h]] ||= create_chip x, y, w, h
  end

  def to_hash()
    {next_id: @next_id, chips: @id2chip.values.map {_1.to_hash}}
  end

  def [](id)
    @id2chip[id]
  end

  def <=>(o)
    a =                  [@image, @next_id, @id2chip, @frame2chip]
    b = o.instance_eval {[@image, @next_id, @id2chip, @frame2chip]}
    a <=> b
  end

  def self.restore(hash, image)
    next_id, chips = hash.values_at :next_id, :chips
    #hash => {next_id:, chips:}
    new(image).tap do |obj|
      obj.instance_eval do
        @next_id    = next_id
        @id2chip    = chips
          .map {|hash| Reight::Chip.restore hash, image}
          .map {|chip| [chip.id, chip]}
          .to_h
        @frame2chip = @id2chip.each_value
          .with_object({}) {|chip, hash| hash[chip.frame] = chip}
      end
    end
  end

  private

  def create_chip(x, y, w, h)
    id           = @next_id
    @next_id    += 1
    @id2chip[id] = Reight::Chip.new(id, @image, x, y, w, h, shape: :rect)
  end

end# ChipList

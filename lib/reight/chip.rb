using Reight


class Reight::Chip

  include Comparable

  def initialize(id, image, x, y, w, h, pos: nil)
    @id, @image, @x, @y, @w, @h, @pos = id, image, x, y, w, h, pos
  end

  attr_reader :id, :image, :x, :y, :w, :h, :pos

  def frame = [x, y, w, h]

  def with(**kwargs)
    id, image, x, y, w, h, pos =
      kwargs.values_at :id, :image, :x, :y, :w, :h, :pos
    self.class.new(
      id       || @id,
      image    || @image,
      x        || @x,
      y        || @y,
      w        || @w,
      h        || @h,
      pos: pos || @pos)
  end

  def to_hash()
    {id: id, x: x, y: y, w: w, h: h, pos: pos&.to_a(2)}
  end

  def <=>(o)
    a =                  [@id, @image.object_id, @x, @y, @w, @h, @pos]
    b = o.instance_eval {[@id, @image.object_id, @x, @y, @w, @h, @pos]}
    a <=> b
  end

  def self.restore(hash, image)
    hash => {id:, x:, y:, w:, h:, pos:}
    new id, image, x, y, w, h, pos: pos&.then {create_vector(*_1)}
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
    hash => {next_id:, chips:}
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
    @id2chip[id] = Reight::Chip.new(id, @image, x, y, w, h)
  end

end# ChipList

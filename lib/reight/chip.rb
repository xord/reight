class Reight::Chip

  include Comparable

  def initialize(id, image, x, y, w, h)
    @id, @image, @x, @y, @w, @h = id, image, x, y, w, h
  end

  attr_reader :id, :image, :x, :y, :w, :h

  def frame = [x, y, w, h]

  def to_hash()
    {id: id, x: x, y: y, w: w, h: h}
  end

  def <=>(o)
    a =                  [@id, @image.object_id, @x, @y, @w, @h]
    b = o.instance_eval {[@id, @image.object_id, @x, @y, @w, @h]}
    a <=> b
  end

  def self.restore(hash, image)
    hash => {id:, x:, y:, w:, h:}
    new id, image, x, y, w, h
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

  def <=>(o)
    a =                  [@image, @next_id, @id2chip, @frame2chip]
    b = o.instance_eval {[@image, @next_id, @id2chip, @frame2chip]}
    a <=> b
  end

  def self.restore(hash, image)
    hash => {next_id:, chips:}
    new(image).instance_eval {
      @next_id    = next_id
      @id2chip    = chips
        .map {|hash| Reight::Chip.restore hash, image}
        .map {|chip| [chip.id, chip]}
        .to_h
      @frame2chip = @id2chip.each_value
        .with_object({}) {|chip, hash| hash[chip.frame] = chip}
      self
    }
  end

  private

  def create_chip(x, y, w, h)
    id           = @next_id
    @next_id    += 1
    @id2chip[id] = Reight::Chip.new(id, @image, x, y, w, h)
  end

end# ChipList

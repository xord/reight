class Reight::Map

  include Enumerable
  include Comparable

  def initialize(chip_size: 8, chunk_size: 128)
    raise ArgumentError, "Invalid chip_size: #{chip_size}" if
      chip_size.to_i != chip_size
    raise ArgumentError, "Invalid chunk_size: #{chunk_size}" if
      chunk_size.to_i != chunk_size || chunk_size % chip_size != 0

    @chip_size, @chunk_size = [chip_size, chunk_size].map &:to_i
    @chunks                 = {}
  end

  def each_chip(x, y, w, h, &block)
    return enum_for :each_chip, x, y, w, h unless block
    x1, y1 = chunk_key_at x,         y
    x2, y2 = chunk_key_at x + w - 1, y + h - 1
    (y1..y2).step @chunk_size do |y|
      (x1..x2).step @chunk_size do |x|
        chunk_at(x, y)&.each_chip(&block)
      end
    end
  end

  def to_hash()
    {
      chip_size:  @chip_size,
      chunk_size: @chunk_size,
      chunks:     @chunks.values.map(&:to_hash)
    }
  end

  def []=(x, y, chip)
    chunk_at(x, y, create: true)[x, y] = chip
  end

  def [](x, y)
    chunk_at(x, y)&.[](x, y)
  end

  def <=>(o)
    a =                  [@chip_size, @chunk_size, @chunks]
    b = o.instance_eval {[@chip_size, @chunk_size, @chunks]}
    a <=> b
  end

  def self.restore(hash, source_chips)
    hash => {chip_size:, chunk_size:, chunks:}
    new(chip_size: chip_size, chunk_size: chunk_size).tap do |obj|
      obj.instance_eval do
        @chunks = chunks.each.with_object({}) do |chunk_hash, result|
          chunk_hash => {x:, y:}
          result[[x, y]] = Chunk.restore chunk_hash, source_chips
        end
      end
    end
  end

  private

  def chunk_at(x, y, create: false)
    x, y = chunk_key_at x, y
    if create
      @chunks[[x, y]] ||=
        Chunk.new x, y, @chunk_size, @chunk_size, chip_size: @chip_size
    else
      @chunks[[x, y]]
    end
  end

  def chunk_key_at(x, y)
    cs = @chunk_size
    [x.to_i / cs * cs, y.to_i / cs * cs]
  end

end# Map


class Reight::Map::Chunk

  include Comparable

  def initialize(x, y, w, h, chip_size: 8)
    raise ArgumentError, "Invalid chip_size: #{chip_size}" if chip_size.to_i != chip_size
    raise ArgumentError, "Invalid w: #{w}"                 if w % chip_size != 0
    raise ArgumentError, "Invalid h: #{h}"                 if h % chip_size != 0
    @x, @y, @w, @h     = [x, y, w, h].map &:to_i
    @chip_size, @chips = chip_size, []
    @ncolumn           = @w / @chip_size
  end

  attr_reader :x, :y, :w, :h

  def each_chip(&block)
    return enum_for :each_chip unless block
    cs, ncol = @chip_size, @ncolumn
    @chips.each.with_index do |chip, index|
      block.call chip, @x + (index % ncol) * cs, @y + (index / ncol) * cs if chip
    end
  end

  def frame = [@x, @y, @w, @h]

  def to_hash()
    {
      x: @x, y: @y, w: @w, h: @h,
      chip_size: @chip_size, chips: @chips.map {_1&.id}
    }
  end

  def []=(x, y, chip)
    @chips[index_at x, y] = chip
  end

  def [](x, y)
    @chips[index_at x, y]
  end

  def <=>(o)
    a =                  [@x, @y, @w, @h, @chip_size, @chips]
    b = o.instance_eval {[@x, @y, @w, @h, @chip_size, @chips]}
    a <=> b
  end

  def self.restore(hash, source_chips)
    hash => {x:, y:, w:, h:, chip_size: chip_size, chips: chip_ids}
    new(x, y, w, h, chip_size: chip_size).tap do |obj|
      obj.instance_eval do
        @chips = chip_ids.map {|id| id ? source_chips[id] : nil}
      end
    end
  end

  private

  def index_at(x, y) =
    (y.to_i - @y) / @chip_size * @ncolumn + (x.to_i - @x) / @chip_size

end# Chunk

class Reight::Map

  include Comparable

  def initialize(tile_size: 32)
    @tile_size = tile_size.to_i
    @tiles     = {}
  end

  attr_reader :tile_size

  def to_hash()
    {tile_size: @tile_size, tiles: @tiles.values.map(&:to_hash)}
  end

  def []=(x, y, chip)
    tile_at(x, y, create: true)[x, y] = chip
  end

  def [](x, y)
    tile_at(x, y)&.[](x, y)
  end

  def <=>(o)
    a =                  [@tile_size, @tiles]
    b = o.instance_eval {[@tile_size, @tiles]}
    a <=> b
  end

  def self.restore(hash, source_chips)
    hash => {tile_size:, tiles:}
    new(tile_size: tile_size).tap do |obj|
      obj.instance_eval do
        @tiles = tiles.each.with_object({}) do |tile_hash, result|
          tile_hash => {x:, y:}
          result[[x, y]] = Tile.restore tile_hash, source_chips
        end
      end
    end
  end

  private

  def tile_at(x, y, create: false)
    ts   = tile_size
    x, y = x.to_i / ts * ts, y.to_i / ts * ts
    if create
      @tiles[[x, y]] ||= Tile.new(x, y, ts, ts)
    else
      @tiles[[x, y]]
    end
  end

end# Map


class Reight::Map::Tile

  include Comparable

  def initialize(x, y, w, h)
    @x, @y, @w, @h = [x, y, w, h].map &:to_i
    @chips         = []
  end

  attr_reader :x, :y, :w, :h

  def frame = [x, y, w, h]

  def to_hash()
    {x: @x, y: @y, w: @w, h: @h, chips: @chips.map {_1&.id}}
  end

  def []=(x, y, chip)
    @chips[index_at x, y] = chip
  end

  def [](x, y)
    @chips[index_at x, y]
  end

  def <=>(o)
    a =                  [@x, @y, @w, @h, @chips]
    b = o.instance_eval {[@x, @y, @w, @h, @chips]}
    a <=> b
  end

  def self.restore(hash, source_chips)
    hash => {x:, y:, w:, h:, chips: chip_ids}
    new(x, y, w, h).tap do |obj|
      obj.instance_eval do
        @chips = chip_ids.map {|id| source_chips[id]}
      end
    end
  end

  private

  def index_at(x, y) = (y.to_i - @y) * @w + (x.to_i - @x)

end# Tile

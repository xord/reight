using Reight


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

  def put(x, y, chip)
    return unless chip
    each_chunk x, y, chip.w, chip.h, create: true do |chunk|
      chunk.put x, y, chip
    end
  end

  def delete(x, y)
    chip           = self[x, y] or return
    cx, cy, cw, ch = chip.then {[_1.pos.x, _1.pos.y, _1.w, _1.h]}
    each_chunk cx, cy, cw, ch, create: false do |chunk|
      each_chip_pos(cx, cy, cw, ch) {|xx, yy| chunk.delete xx, yy}
    end
  end

  def delete_chip(chip)
    delete chip.pos.x, chip.pos.y
  end

  def each_chip(x = nil, y = nil, w = nil, h = nil, clip_by_chunk: false, &block)
    return enum_for :each_chip, x, y, w, h, clip_by_chunk: clip_by_chunk unless block
    enum =
      case [x, y, w, h]
      in [nil,     nil,     nil,     nil]     then @chunks.values.each
      in [Numeric, Numeric, Numeric, Numeric] then each_chunk x, y, w, h
      else raise ArgumentError, "Invalid bounds"
      end
    x = y = w = h = nil if clip_by_chunk
    enum.each do |chunk|
      chunk.each_chip(x, y, w, h) {|chip, _, _| block.call chip}
    end
  end

  def each(&block) = each_chip(&block)

  def to_hash()
    {
      chip_size: @chip_size, chunk_size: @chunk_size,
      chunks: @chunks.values.map(&:to_hash)
    }
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

  def each_chunk(x, y, w = 0, h = 0, create: false, &block)
    return enum_for :each_chunk, x, y, w, h, create: create unless block
    x, w   = x + w, -w if w < 0
    y, h   = y + h, -h if h < 0
    x1, x2 = x, x + w
    y1, y2 = y, y + h
    x2    -= 1 if x2 > x1
    y2    -= 1 if y2 > y1
    x1, y1 = align_chunk_pos x1, y1
    x2, y2 = align_chunk_pos x2, y2
    (y1..y2).step @chunk_size do |yy|
      (x1..x2).step @chunk_size do |xx|
        chunk = chunk_at xx, yy, create: create
        block.call chunk if chunk
      end
    end
  end

  def chunk_at(x, y, create: false)
    x, y = align_chunk_pos x, y
    if create
      @chunks[[x, y]] ||=
        Chunk.new x, y, @chunk_size, @chunk_size, chip_size: @chip_size
    else
      @chunks[[x, y]]
    end
  end

  def each_chip_pos(x, y, w, h, &block)
    x, w   = x + w, -w if w < 0
    y, h   = y + h, -h if h < 0
    x1, y1 = align_chip_pos x, y
    x2, y2 = align_chip_pos x + w + @chip_size - 1, y + h + @chip_size - 1
    (y1...y2).step @chip_size do |yy|
      (x1...x2).step @chip_size do |xx|
        block.call xx, yy
      end
    end
  end

  def align_chunk_pos(x, y)
    s = @chunk_size
    [x.to_i / s * s, y.to_i / s * s]
  end

  def align_chip_pos(x, y)
    s = @chip_size
    [x.to_i / s * s, y.to_i / s * s]
  end

end# Map


class Reight::Map::Chunk

  include Comparable

  def initialize(x, y, w, h, chip_size: 8)
    raise ArgumentError, "Invalid chip_size: #{chip_size}" if chip_size.to_i != chip_size
    raise ArgumentError, "Invalid w: #{w}"                 if w % chip_size != 0
    raise ArgumentError, "Invalid h: #{h}"                 if h % chip_size != 0

    @x, @y, @w, @h, @chip_size = [x, y, w, h, chip_size].map &:to_i
    @chips, @ncolumn           = [], @w / @chip_size
  end

  attr_reader :x, :y, :w, :h

  def put(x, y, chip)
    x, y = align_chip_pos x, y
    raise "Invalid chip size" if
      chip.w % @chip_size != 0 || chip.h % @chip_size != 0
    raise "Conflicts with other chips" if
      each_chip_pos(x, y, chip.w, chip.h).any? {|xx, yy| self[xx, yy]}

    new_chip = nil
    get_chip = -> {new_chip ||= chip.with pos: create_vector(x, y)}
    each_chip_pos x, y, chip.w, chip.h do |xx, yy|
      @chips[pos2index xx, yy] = get_chip.call
    end
  end

  def delete(x, y)
    chip = self[x, y] or return
    each_chip_pos chip.pos.x, chip.pos.y, chip.w, chip.h do |xx, yy|
      index         = pos2index xx, yy
      @chips[index] = nil if @chips[index]&.id == chip.id
    end
    delete_last_nils
  end

  def each_chip(x = nil, y = nil, w = nil, h = nil, include_hidden: false, &block)
    return enum_for(:each_chip, x, y, w, h, include_hidden: include_hidden) unless block
    x, w = x + w, -w if x && w && w < 0
    y, h = y + h, -h if y && h && h < 0
    @chips.each.with_index do |chip, index|
      next unless chip
      xx, yy = index2pos index
      pos    = chip.pos
      next if x && !intersect?(x, y, w, h, pos.x, pos.y, chip.w, chip.h)
      block.call chip, xx, yy if include_hidden || (xx == pos.x && yy == pos.y)
    end
  end

  def each_chip_pos(x, y, w, h, &block)
    return enum_for :each_chip_pos, x, y, w, h unless block
    x, w   = x + w, -w if w < 0
    y, h   = y + h, -h if h < 0
    x1, y1 = align_chip_pos x, y
    x2, y2 = align_chip_pos x + w + @chip_size - 1, y + h + @chip_size - 1
    x1, x2 = [x1, x2].map {_1.clamp @x, @x + @w}
    y1, y2 = [y1, y2].map {_1.clamp @y, @y + @h}
    (y1...y2).step @chip_size do |yy|
      (x1...x2).step @chip_size do |xx|
        block.call xx, yy
      end
    end
  end

  def frame = [@x, @y, @w, @h]

  def to_hash()
    {
      x: @x, y: @y, w: @w, h: @h, chip_size: @chip_size,
      chips: @chips.map {|chip| chip ? [chip.id, chip.pos.x, chip.pos.y] : nil}
    }
  end

  def [](x, y)
    index = pos2index x, y
    return nil if index < 0 || (@w * @h) <= index
    @chips[index]
  end

  def <=>(o)
    a =                  [@x, @y, @w, @h, @chip_size, @chips]
    b = o.instance_eval {[@x, @y, @w, @h, @chip_size, @chips]}
    a <=> b
  end

  def self.restore(hash, source_chips)
    hash      => {x:, y:, w:, h:, chip_size: chip_size, chips: chip_ids}
    tmp_chips = {}
    get_chip  = -> id, x, y {
      tmp_chips[[id, x, y]] ||= source_chips[id].with(pos: create_vector(x, y))
    }
    new(x, y, w, h, chip_size: chip_size).tap do |obj|
      obj.instance_eval do
        @chips = chip_ids.map {|id, x, y| id ? get_chip.call(id, x, y) : nil}
      end
    end
  end

  private

  def pos2index(x, y) =
    (y.to_i - @y) / @chip_size * @ncolumn + (x.to_i - @x) / @chip_size

  def index2pos(index) = [
    @x + (index % @ncolumn) * @chip_size,
    @y + (index / @ncolumn) * @chip_size
  ]

  def align_chip_pos(x, y)
    s = @chip_size
    [x.to_i / s * s, y.to_i / s * s]
  end

  def delete_last_nils()
    last   = @chips.rindex {_1 != nil}
    @chips = @chips[..last] if last
  end

  def intersect?(ax, ay, aw, ah, bx, by, bw, bh)
    ax2, ay2 = ax + aw, ay + ah
    bx2, by2 = bx + bw, by + bh
    ax < bx2 && bx < ax2 && ay < by2 && by < ay2
  end

end# Chunk

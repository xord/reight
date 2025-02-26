class Reight::Sprite < RubySketch::Sprite

  def initialize(*a, chip: nil, **k, &b)
    @chip = chip
    super(*a, **k, &b)
  end

  attr_accessor :map_chunk

  attr_reader :chip

end# Sprite

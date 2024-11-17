require_relative 'helper'


class TestMap < Test::Unit::TestCase

  def map(...)  = R8::Map.new(...)

  def tile(...) = R8::Map::Tile.new(...)

  def chip(...) = R8::Chip.new(...)

  def image(w = 1, h = 1) = RS::Image.new Rays::Image.new w, h

  def test_initialize()
    assert_equal 32, map                .tile_size
    assert_equal 9,  map(tile_size: 9)  .tile_size
    assert_equal 9,  map(tile_size: 9.9).tile_size
  end

  def test_to_hash()
    assert_equal(
      {tile_size: 3, tiles: [{x: 6, y: 6, w: 3, h: 3, chips: [nil,nil,nil, 9]}]},
      map(tile_size: 3).tap {_1[6, 7] = chip 9, image, 8, 7, 6, 5}.to_hash)
  end

  def test_compare()
    assert_not_equal map(tile_size: 1), map(tile_size: 2)

    m1, m2 = map(tile_size: 3), map(tile_size: 3)
    assert_equal m1, m2

    i        = image
    m1[6, 7] = chip 9, i, 8, 7, 6, 5; assert_not_equal m1, m2
    m2[6, 7] = chip 9, i, 8, 7, 6, 5; assert_equal     m1, m2
    m2[6, 7] = chip 0, i, 8, 7, 6, 5; assert_not_equal m1, m2
  end

  def test_at()
    m = map tile_size: 3
    assert_nil m[6, 7]

    i       = image
    m[6, 7] =    chip 9, i, 8, 7, 6, 5
    assert_equal chip(9, i, 8, 7, 6, 5), m[6, 7]
  end

  def test_restore()
    i     = image
    chips = R8::ChipList.restore(
      {next_id: 10, chips: [{id: 9, x: 8, y: 7, w: 6, h: 5}]}, i)

    assert_equal(
      map(tile_size: 3).tap {_1[6, 7] = chip(9, i, 8, 7, 6, 5)},
      R8::Map.restore({
        tile_size: 3,
        tiles: [{x: 6, y: 6, w: 3, h: 3, chips: [nil,nil,nil, 9]}]
      }, chips))
  end

end# TestMap

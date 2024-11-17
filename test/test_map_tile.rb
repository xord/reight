require_relative 'helper'


class TestMapTile < Test::Unit::TestCase

  def tile(...) = R8::Map::Tile.new(...)

  def chip(...) = R8::Chip.new(...)

  def image(w = 1, h = 1) = RS::Image.new Rays::Image.new w, h

  def test_initialize()
    assert_equal [1, 2, 3, 4], tile(1,   2,   3,   4)  .frame
    assert_equal [1, 2, 3, 4], tile(1.1, 2.2, 3.3, 4.4).frame
  end

  def test_to_hash()
    t       = tile 1, 2, 3, 4
    t[2, 3] = chip(9, image, 8, 7, 6, 5)
    assert_equal(
      {x: 1, y: 2, w: 3, h: 4, chips: [nil,nil,nil, nil,9]},
      t.to_hash)
  end

  def test_compare()
    assert_not_equal tile(1, 2, 3, 4), tile(0, 2, 3, 4)
    assert_not_equal tile(1, 2, 3, 4), tile(1, 0, 3, 4)
    assert_not_equal tile(1, 2, 3, 4), tile(1, 2, 0, 4)
    assert_not_equal tile(1, 2, 3, 4), tile(1, 2, 3, 0)

    t1, t2 = tile(1, 2, 3, 4), tile(1, 2, 3, 4)
    assert_equal t1, t2

    i        = image
    t1[1, 2] = chip 9, i, 8, 7, 6, 5; assert_not_equal t1, t2
    t2[1, 2] = chip 9, i, 8, 7, 6, 5; assert_equal     t1, t2
    t2[1, 2] = chip 0, i, 8, 7, 6, 5; assert_not_equal t1, t2
  end

  def test_at()
    t = tile 1, 2, 3, 4
    assert_nil t[2, 3]

    i       = image
    t[2, 3] =    chip 9, i, 8, 7, 6, 5
    assert_equal chip(9, i, 8, 7, 6, 5), t[2, 3]
  end

  def test_restore()
    i     = image
    chips = R8::ChipList.restore(
      {next_id: 10, chips: [{id: 9, x: 8, y: 7, w: 6, h: 5}]}, i)

    assert_equal(
      tile(1, 2, 3, 4).tap {_1[2, 3] = chip(9, i, 8, 7, 6, 5)},
      R8::Map::Tile.restore({x: 1, y: 2, w: 3, h: 4, chips: [nil,nil,nil, nil,9]}, chips))
  end

end# TestMapTile

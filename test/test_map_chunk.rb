require_relative 'helper'
using Reight


class TestMapChunk < Test::Unit::TestCase

  def chunk(...) = R8::Map::Chunk.new(...)

  def chip(id: 1, image: self.image, frame: [2, 3, 4, 5]) =
    R8::Chip.new id, image, *frame

  def image(w = 1, h = 1) = create_image w, h

  def test_initialize()
    assert_equal [1, 3, 6, 8], chunk(1,   3,   6, 8, chip_size: 2).frame
    assert_equal [1, 3, 6, 8], chunk(1.1, 3,   6, 8, chip_size: 2).frame
    assert_equal [1, 3, 6, 8], chunk(1,   3.3, 6, 8, chip_size: 2).frame

    assert_raise(ArgumentError) {chunk 1, 3, 6,   8, chip_size: 2.2}
    assert_raise(ArgumentError) {chunk 1, 3, 6.6, 8}
    assert_raise(ArgumentError) {chunk 1, 3, 6,   8.8}
  end

  def test_each_chip()
    t        = chunk 1, 3, 6, 8, chip_size: 2
    t[3, 7]  = chip id: 10
    t[6, 10] = chip id: 11

    assert_equal(
      [[10, 3, 7], [11, 5, 9]],
      t.each_chip.to_a.map {|chip, x, y| [chip.id, x, y]})
  end

  def test_to_hash()
    x = nil

    t           = chunk 1, 3, 6, 8, chip_size: 2
    t[3, 5]     = chip id: 10
    assert_equal(
      {x: 1, y: 3, w: 6, h: 8, chip_size: 2, chips: [x,x,x, x,10]},
      t.to_hash)

    t[5, 7]     = chip id: 11
    assert_equal(
      {x: 1, y: 3, w: 6, h: 8, chip_size: 2, chips: [x,x,x, x,10,x, x,x,11]},
      t.to_hash)

    t[5.5, 7.7] = chip id: 12
    assert_equal(
      {x: 1, y: 3, w: 6, h: 8, chip_size: 2, chips: [x,x,x, x,10,x, x,x,12]},
      t.to_hash)
  end

  def test_compare()
    assert_not_equal chunk(1, 3, 6, 8, chip_size: 2), chunk(0, 3, 6, 8, chip_size: 2)
    assert_not_equal chunk(1, 3, 6, 8, chip_size: 2), chunk(1, 0, 6, 8, chip_size: 2)
    assert_not_equal chunk(1, 3, 6, 8, chip_size: 2), chunk(1, 3, 0, 8, chip_size: 2)
    assert_not_equal chunk(1, 3, 6, 8, chip_size: 2), chunk(1, 3, 6, 0, chip_size: 2)
    assert_not_equal chunk(1, 3, 6, 8, chip_size: 2), chunk(1, 3, 6, 8, chip_size: 1)

    t1, t2 = chunk(1, 3, 6, 8, chip_size: 2), chunk(1, 3, 6, 8, chip_size: 2)
    assert_equal t1, t2

    i        = image
    t1[3, 5] = chip id: 10, image: i; assert_not_equal t1, t2
    t2[3, 5] = chip id: 10, image: i; assert_equal     t1, t2
    t2[3, 5] = chip id: 0,  image: i; assert_not_equal t1, t2
  end

  def test_at()
    t = chunk 1, 3, 6, 8, chip_size: 2
    assert_nil t[3, 5]

    i       = image
    t[3, 5] =    chip id: 10, image: i
    assert_equal chip(id: 10, image: i), t[3, 5]
  end

  def test_restore()
    i     = image
    chips = R8::ChipList.restore(
      {next_id: 11, chips: [{id: 10, x: 9, y: 8, w: 7, h: 6}]}, i)

    assert_equal(
      chunk(1, 3, 6, 8, chip_size: 2)
        .tap {_1[3, 5] = chip(id: 10, image: i, frame: [9, 8, 7, 6])},
      R8::Map::Chunk.restore({
        x: 1, y: 3, w: 6, h: 8, chip_size: 2, chips: [nil,nil,nil, nil,10]
      }, chips))
  end

end# TestMapChunk

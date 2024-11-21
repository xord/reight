require_relative 'helper'
using Reight


class TestMap < Test::Unit::TestCase

  def map(...)   = R8::Map.new(...)

  def chunk(...) = R8::Map::Chunk.new(...)

  def chip(id: 1, image: self.image, frame: [2, 3, 4, 5]) =
    R8::Chip.new id, image, *frame

  def image(w = 1, h = 1) = create_image w, h

  def test_initialize()
    assert_nothing_raised       {map chip_size: 2,   chunk_size: 6}
    assert_raise(ArgumentError) {map chip_size: 2,   chunk_size: 7}
    assert_raise(ArgumentError) {map chip_size: 2.2, chunk_size: 6}
    assert_raise(ArgumentError) {map chip_size: 2,   chunk_size: 6.6}
  end

  def test_each_chip()
    m       = map chip_size: 2, chunk_size: 6
    m[2, 4] = chip id: 10
    m[6, 8] = chip id: 11

    assert_equal(
      [[10, 2, 4]],
      m.each_chip(0, 0, 6, 6).to_a.map {|chip, x, y| [chip.id, x, y]})
    assert_equal(
      [[10, 2, 4], [11, 6, 8]],
      m.each_chip(0, 0, 7, 7).to_a.map {|chip, x, y| [chip.id, x, y]})
  end

  def test_to_hash()
    assert_equal(
      {
        chip_size: 2, chunk_size: 6,
        chunks: [{x: 6, y: 6, w: 6, h: 6, chip_size: 2, chips: [nil,nil,nil, 10]}]
      },
      map(chip_size: 2, chunk_size: 6).tap {_1[6, 8] = chip id: 10}.to_hash)
  end

  def test_compare()
    assert_not_equal map(chip_size: 2, chunk_size: 8), map(chip_size: 4, chunk_size: 8)
    assert_not_equal map(chip_size: 2, chunk_size: 8), map(chip_size: 2, chunk_size: 4)

    m1, m2 = map(chip_size: 2, chunk_size: 6), map(chip_size: 2, chunk_size: 6)
    assert_equal m1, m2

    i        = image
    m1[6, 8] = chip id: 10, image: i; assert_not_equal m1, m2
    m2[6, 8] = chip id: 10, image: i; assert_equal     m1, m2
    m2[6, 8] = chip id: 0,  image: i; assert_not_equal m1, m2
  end

  def test_at()
    m = map chip_size: 2, chunk_size: 6
    assert_nil m[6, 8]

    i       = image
    m[6, 8] =    chip id: 10, image: i
    assert_equal chip(id: 10, image: i), m[6, 8]
  end

  def test_restore()
    i     = image
    chips = R8::ChipList.restore(
      {next_id: 11, chips: [{id: 10, x: 9, y: 8, w: 7, h: 6}]}, i)

    assert_equal(
      map(chip_size: 2, chunk_size: 6)
        .tap {_1[6, 8] = chip(id: 10, image: i, frame: [9, 8, 7, 6])},
      R8::Map.restore({
        chip_size: 2, chunk_size: 6,
        chunks: [{x: 6, y: 6, w: 6, h: 6, chip_size: 2, chips: [nil,nil,nil, 10]}]
      }, chips))
  end

end# TestMap

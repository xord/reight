require_relative 'helper'
using Reight


class TestMap < Test::Unit::TestCase

  def map(...)   = R8::Map.new(...)

  def chunk(...) = R8::Map::Chunk.new(...)

  def chip(x, y, w, h, id: 1, image: self.image, pos: nil) =
    R8::Chip.new id, image, x, y, w, h, pos: pos

  def image(w = 1, h = 1) = create_image w, h

  def vec(...)            = create_vector(...)

  def test_initialize()
    assert_nothing_raised       {map chip_size: 2,   chunk_size: 6}
    assert_raise(ArgumentError) {map chip_size: 2,   chunk_size: 7}
    assert_raise(ArgumentError) {map chip_size: 2.2, chunk_size: 6}
    assert_raise(ArgumentError) {map chip_size: 2,   chunk_size: 6.6}
  end

  def test_each_chip()
    m         = map chip_size: 10, chunk_size: 30
    m[10, 20] = chip 0, 0, 10, 10, id: 1
    m[20, 30] = chip 0, 0, 20, 20, id: 2

    assert_equal(
      [[1, 10, 20]],
      m.each_chip(0, 0, 30, 30).to_a.map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [[1, 10, 20], [2, 20, 30]],
      m.each_chip(0, 0, 31, 31).to_a.map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
  end

  def test_to_hash()
    assert_equal(
      {
        chip_size: 10, chunk_size: 30,
        chunks: [{x: 30, y: 30, w: 30, h: 30, chip_size: 10, chips: [nil,nil,nil, [1, 30, 40]]}]
      },
      map(chip_size: 10, chunk_size: 30).tap {_1[30, 40] = chip 0, 0, 10, 10, id: 1}.to_hash)
  end

  def test_compare()
    assert_not_equal map(chip_size: 10, chunk_size: 20), map(chip_size: 1,  chunk_size: 20)
    assert_not_equal map(chip_size: 10, chunk_size: 20), map(chip_size: 10, chunk_size: 10)

    m1, m2 = map(chip_size: 10, chunk_size: 30), map(chip_size: 10, chunk_size: 30)
    assert_equal m1, m2

    img        = image
    m1[10, 20] = chip 0, 0, 10, 10, id: 1, image: img; assert_not_equal m1, m2
    m2[10, 20] = chip 0, 0, 10, 10, id: 1, image: img; assert_equal     m1, m2
    m2[10, 20] = chip 0, 0, 10, 10, id: 2, image: img; assert_not_equal m1, m2
  end

  def test_at()
    m = map chip_size: 10, chunk_size: 30
    assert_nil m[10, 20]

    img       = image
    m[10, 20] =  chip 0, 0, 10, 10, id: 1, image: img
    assert_equal chip(0, 0, 10, 10, id: 1, image: img, pos: vec(10, 20)), m[10, 20]
    assert_nil                                                            m[10, 30]

    m[10, 20] =  chip 0, 0, 10, 20, id: 2, image: img
    assert_equal chip(0, 0, 10, 20, id: 2, image: img, pos: vec(10, 20)), m[10, 20]
    assert_equal chip(0, 0, 10, 20, id: 2, image: img, pos: vec(10, 20)), m[10, 30]
  end

  def test_restore()
    img      = image
    chips    = R8::ChipList.restore({
      next_id: 3, chips: [
        {id: 1, x: 0, y: 0, w: 10, h: 10, pos: nil},
        {id: 2, x: 0, y: 0, w: 20, h: 20, pos: nil},
      ]
    }, img)
    restored = R8::Map.restore({
      chip_size: 10, chunk_size: 30, chunks: [
        {
          x: 0,  y: 0, w: 30, h: 30, chip_size: 10,
          chips: [nil,nil,nil, nil,nil,[2,20,10], nil,[1,10,20],[2,20,10]]
        },
        {
          x: 30, y: 0, w: 30, h: 30, chip_size: 10,
          chips: [nil,nil,nil, [2,20,10],nil,nil, [2,20,10]]
        },
      ]
    }, chips)

    assert_equal(
      map(chip_size: 10, chunk_size: 30).tap {
        _1[10, 20] = chip 0, 0, 10, 10, id: 1, image: img
        _1[20, 10] = chip 0, 0, 20, 20, id: 2, image: img
      },
      restored)
    assert_equal     restored[20, 10].object_id, restored[20, 20].object_id
    assert_equal     restored[30, 10].object_id, restored[30, 20].object_id
    assert_not_equal restored[20, 10].object_id, restored[30, 10].object_id
  end

end# TestMap

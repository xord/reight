require_relative 'helper'
using Reight


class TestMapChunk < Test::Unit::TestCase

  def chunk(...) = R8::Map::Chunk.new(...)

  def chip(x, y, w, h, id: 1, image: self.image, pos: nil) =
    R8::Chip.new id, image, x, y, w, h, pos: pos

  def image(w = 100, h = 100) = create_image w, h

  def vec(...)                = create_vector(...)

  def test_initialize()
    assert_equal [1, 3, 4, 6], chunk(1,   3,   4, 6, chip_size: 2).frame
    assert_equal [1, 3, 4, 6], chunk(1.1, 3,   4, 6, chip_size: 2).frame
    assert_equal [1, 3, 4, 6], chunk(1,   3.3, 4, 6, chip_size: 2).frame

    assert_raise(ArgumentError) {chunk 1, 3, 4,   6,   chip_size: 2.2}
    assert_raise(ArgumentError) {chunk 1, 3, 4.4, 6,   chip_size: 2}
    assert_raise(ArgumentError) {chunk 1, 3, 4,   6.6, chip_size: 2}
  end

  def test_each_chip()
    c         = chunk 10, 20, 30, 40, chip_size: 10
    c[10, 20] = chip 0, 0, 10, 10, id: 1
    c[20, 30] = chip 0, 0, 20, 20, id: 2

    assert_equal(
      [[1, 10, 20], [2, 20, 30]],
      c.each_chip.to_a.map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
  end

  def test_to_hash()
    c         = chunk 10, 20, 30, 40, chip_size: 10
    c[20, 30] = chip 0, 0, 10, 10, id: 1
    assert_equal(
      {
        x: 10, y: 20, w: 30, h: 40, chip_size: 10,
        chips: [nil,nil,nil, nil,[1,20,30]]
      },
      c.to_hash)

    c[30, 40] = chip 0, 0, 10, 20, id: 2
    assert_equal(
      {
        x: 10, y: 20, w: 30, h: 40, chip_size: 10,
        chips: [nil,nil,nil, nil,[1,20,30],nil, nil,nil,[2,30,40], nil,nil,[2,30,40]]
      },
      c.to_hash)
  end

  def test_compare()
    assert_not_equal chunk(10, 20, 30, 40, chip_size: 10), chunk( 0, 20, 30, 40, chip_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, chip_size: 10), chunk(10,  0, 30, 40, chip_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, chip_size: 10), chunk(10, 20,  0, 40, chip_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, chip_size: 10), chunk(10, 20, 30,  0, chip_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, chip_size: 10), chunk(10, 20, 30, 40, chip_size: 1)

    c1, c2 = chunk(10, 20, 30, 40, chip_size: 10), chunk(10, 20, 30, 40, chip_size: 10)
    assert_equal c1, c2

    img      = image
    c1[10, 20] = chip 0, 0, 10, 10, id: 1, image: img; assert_not_equal c1, c2
    c2[10, 20] = chip 0, 0, 10, 10, id: 1, image: img; assert_equal     c1, c2
    c2[10, 20] = chip 0, 0, 10, 10, id: 2, image: img; assert_not_equal c1, c2
  end

  def test_at()
    img = image

    c = chunk 10, 20, 30, 40, chip_size: 10
    assert_nil c[20, 30]

    c[20, 30]     = chip 0, 0, 10, 10, id: 1, image: img, pos: nil
    assert_equal    chip(0, 0, 10, 10, id: 1, image: img, pos: vec(20, 30)), c[20, 30]

    c[20.2, 30.3] = chip 0, 0, 10, 10, id: 2, image: img, pos: nil
    assert_equal    chip(0, 0, 10, 10, id: 2, image: img, pos: vec(20, 30)), c[20, 30]

    c[20, 30]     = chip 0, 0, 20, 20, id: 3, image: img, pos: nil
    assert_equal    chip(0, 0, 20, 20, id: 3, image: img, pos: vec(20, 30)), c[20, 30]
    assert_equal    chip(0, 0, 20, 20, id: 3, image: img, pos: vec(20, 30)), c[30, 30]
    assert_equal    chip(0, 0, 20, 20, id: 3, image: img, pos: vec(20, 30)), c[30, 40]
    assert_equal    chip(0, 0, 20, 20, id: 3, image: img, pos: vec(20, 30)), c[20, 40]

    assert_equal c[20, 30].object_id, c[30, 30].object_id
    assert_equal c[20, 30].object_id, c[30, 40].object_id
    assert_equal c[20, 30].object_id, c[20, 40].object_id
  end

  def test_restore()
    img      = image
    chips    = R8::ChipList.restore({
      next_id: 3, chips: [
        {id: 1, x: 0, y: 0, w: 10, h: 10, pos: nil},
        {id: 2, x: 0, y: 0, w: 10, h: 20, pos: nil},
      ]
    }, img)
    restored = R8::Map::Chunk.restore({
      x: 10, y: 20, w: 30, h: 40, chip_size: 10,
      chips: [nil,nil,nil, nil,[1,20,30],nil, nil,nil,[2,30,40], nil,nil,[2,30,40]]
    }, chips)

    assert_equal(
      chunk(10, 20, 30, 40, chip_size: 10).tap {
        _1[20, 30] = chip 0, 0, 10, 10, id: 1, image: img
        _1[30, 40] = chip 0, 0, 10, 20, id: 2, image: img
      },
      restored)
    assert_equal restored[30, 40].object_id, restored[30, 50].object_id
  end

end# TestMapChunk

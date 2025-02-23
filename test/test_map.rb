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

  def test_put()
    img      = image
    new_chip = -> id, size, pos: nil {
      chip 0, 0, size, size, id: id, image: img, pos: pos
    }

    map(chip_size: 10, chunk_size: 30).tap do |m|
      assert_equal 0, count_all_chips(m)
    end

    map(chip_size: 10, chunk_size: 30).tap do |m|
      m.put 10, 20,     new_chip[1, 10]
      assert_equal      new_chip[1, 10, pos: vec(10, 20)],   m[10, 20]
      assert_equal 1, count_all_chips(m)
    end

    map(chip_size: 10, chunk_size: 30).tap do |m|
      m.put(-10, -20,   new_chip[1, 10])
      assert_equal      new_chip[1, 10, pos: vec(-10, -20)], m[-10, -20]
      assert_equal 1, count_all_chips(m)
    end

    map(chip_size: 10, chunk_size: 30).tap do |m|
      m.put 15, 25,     new_chip[2, 10]
      assert_equal      new_chip[2, 10, pos: vec(10, 20)],   m[15, 25]
      assert_equal      new_chip[2, 10, pos: vec(10, 20)],   m[10, 20]
      assert_equal 1, count_all_chips(m)
    end

    map(chip_size: 10, chunk_size: 30).tap do |m|
      m.put 10.1, 20.2, new_chip[3, 10]
      assert_equal      new_chip[3, 10, pos: vec(10, 20)],   m[10.1, 20.2]
      assert_equal      new_chip[3, 10, pos: vec(10, 20)],   m[10,   20]
      assert_equal 1, count_all_chips(m)
    end

    map(chip_size: 10, chunk_size: 30).tap do |m|
      m.put 15, 25,     new_chip[4, 20]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[15, 25]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[10, 20]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[25, 25]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[20, 20]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[15, 35]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[10, 30]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[25, 35]
      assert_equal      new_chip[4, 20, pos: vec(10, 20)],   m[20, 30]
      assert_equal 4, count_all_chips(m)

      assert_equal     m[10, 20].object_id, m[20, 20].object_id
      assert_equal     m[10, 30].object_id, m[20, 30].object_id
      assert_not_equal m[10, 20].object_id, m[10, 30].object_id
    end

    map(chip_size: 10, chunk_size: 30).tap do |m|
      assert_nothing_raised {m.put 10, 20, chip(0, 0, 10, 10)}
      assert_raise          {m.put 10, 20, chip(0, 0, 10, 10)}
    end
  end

  def test_remove()
    [
      [0, 0], [10, 20], [90, 90]
    ].each do |xx, yy|
      map(chip_size: 10, chunk_size: 30).tap do |m|
        m.remove xx, yy
        assert_equal 0, count_all_chips(m)
      end
    end

    [
      [10, 20, 0], [11, 21, 0], [15, 25, 0], [19, 29, 0],
      [ 9, 19, 1], [20, 30, 1],
      [19.999, 29.999, 0],
      [ 9.999, 19.999, 1]
    ].each do |xx, yy, count|
      map(chip_size: 10, chunk_size: 30).tap do |m|
        m.put 10, 20, chip(0, 0, 10, 10)
        assert_equal 1,     count_all_chips(m)
        m.remove xx, yy
        assert_equal count, count_all_chips(m)
      end
    end

    [
      [10, 20, 0], [20, 20, 0], [10, 30, 0], [20, 30, 0],
      [29, 30, 0], [20, 39, 0], [29, 39, 0],
      [ 9, 19, 4], [30, 40, 4],
      [29.999, 39.999, 0], [29.999, 30, 0], [20, 39.999, 0],
      [ 9.999, 19.999, 4],
    ].each do |xx, yy, count|
      map(chip_size: 10, chunk_size: 30).tap do |m|
        m.put 10, 20, chip(0, 0, 20, 20)
        assert_equal 4,     count_all_chips(m)
        m.remove xx, yy
        assert_equal count, count_all_chips(m)
      end
    end
  end

  def test_remove_chip()
    map(chip_size: 10, chunk_size: 30).tap do |m|
      m.put           10, 20, chip(0, 0, 10, 10)
      assert_equal 1, count_all_chips(m)
      m.remove_chip m[10, 20]
      assert_equal 0, count_all_chips(m)
    end
  end

  def test_each_chip()
    m           = map chip_size: 10, chunk_size: 30
    m.put 10,  20,  chip(0, 0, 10, 10, id: 1)
    m.put 20,  30,  chip(0, 0, 20, 20, id: 2)
    m.put 100, 200, chip(0, 0, 10, 10, id: 3)

    assert_equal(
      [],
      m.each_chip( 0,  0, 10, 20).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [[1, 10, 20]],
      m.each_chip( 0,  0, 11, 21).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [],
      m.each_chip(20, 20, 10, 10).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [[1, 10, 20]],
      m.each_chip(19, 20, 10, 10).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [],
      m.each_chip(10, 30, 10, 10).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [[1, 10, 20]],
      m.each_chip(10, 29, 10, 10).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [[1, 10, 20]],
      m.each_chip(0, 0, 30, 30).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [[1, 10, 20], [2, 20, 30]],
      m.each_chip(0, 0, 31, 31).map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
    assert_equal(
      [[1, 10, 20], [2, 20, 30], [3, 100, 200]],
      m.each_chip              .map {|chip| [chip.id, chip.pos.x, chip.pos.y]})
  end

  def test_to_hash()
    assert_equal(
      {
        chip_size: 10, chunk_size: 30,
        chunks: [{x: 30, y: 30, w: 30, h: 30, chip_size: 10, chips: [nil,nil,nil, [1, 30, 40]]}]
      },
      map(chip_size: 10, chunk_size: 30).tap {_1.put 30, 40, chip(0, 0, 10, 10, id: 1)}.to_hash)
  end

  def test_compare()
    assert_not_equal map(chip_size: 10, chunk_size: 20), map(chip_size: 1,  chunk_size: 20)
    assert_not_equal map(chip_size: 10, chunk_size: 20), map(chip_size: 10, chunk_size: 10)

    m1, m2 = map(chip_size: 10, chunk_size: 30), map(chip_size: 10, chunk_size: 30)
    assert_equal m1, m2

    img        = image
    m1.put    10, 20, chip(0, 0, 10, 10, id: 1, image: img); assert_not_equal m1, m2
    m2.put    10, 20, chip(0, 0, 10, 10, id: 1, image: img); assert_equal     m1, m2
    m2.remove 10, 20
    m2.put    10, 20, chip(0, 0, 10, 10, id: 2, image: img); assert_not_equal m1, m2
  end

  def test_restore()
    img      = image
    chips    = R8::ChipList.restore({
      next_id: 3, chips: [
        {id: 1, x: 0, y: 0, w: 10, h: 10},
        {id: 2, x: 0, y: 0, w: 20, h: 20},
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
        _1.put 10, 20, chip(0, 0, 10, 10, id: 1, image: img)
        _1.put 20, 10, chip(0, 0, 20, 20, id: 2, image: img)
      },
      restored)
    assert_equal     restored[20, 10].object_id, restored[20, 20].object_id
    assert_equal     restored[30, 10].object_id, restored[30, 20].object_id
    assert_not_equal restored[20, 10].object_id, restored[30, 10].object_id
  end

  private

  def count_all_chips(map_, map_size = 90, chip_size: 10)
    range = (-map_size...map_size).step(chip_size).to_a
    range.product(range)
      .map {|x, y| map_[x, y]}
      .count {_1 != nil}
  end

end# TestMap

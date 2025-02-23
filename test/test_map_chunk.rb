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

  def test_put()
    img      = image
    new_chip = -> id, size, pos: nil {
      chip 0, 0, size, size, id: id, image: img, pos: pos
    }

    chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
      assert_nil                                            c[20, 30]
      assert_equal 0, count_all_chips(c)
    end

    chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
      c.put 20, 30,     new_chip[1,  10]
      assert_equal      new_chip[1,  10, pos: vec(20, 30)], c[20, 30]
      assert_equal 1, count_all_chips(c)
    end

    chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
      c.put 25, 35,     new_chip[2,  10]
      assert_equal      new_chip[2,  10, pos: vec(20, 30)], c[25, 35]
      assert_equal      new_chip[2,  10, pos: vec(20, 30)], c[20, 30]
      assert_equal 1, count_all_chips(c)
    end

    chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
      c.put 20.2, 30.3, new_chip[3,  10]
      assert_equal      new_chip[3,  10, pos: vec(20, 30)], c[20.2, 30.3]
      assert_equal      new_chip[3,  10, pos: vec(20, 30)], c[20,   30]
      assert_equal 1, count_all_chips(c)
    end

    chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
      c.put 25, 35,     new_chip[4,  20]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[25, 35]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[20, 30]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[35, 35]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[30, 30]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[35, 45]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[30, 40]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[25, 45]
      assert_equal      new_chip[4,  20, pos: vec(20, 30)], c[20, 40]
      assert_equal 4, count_all_chips(c)

      assert_equal c[20, 30].object_id, c[30, 30].object_id
      assert_equal c[20, 30].object_id, c[30, 40].object_id
      assert_equal c[20, 30].object_id, c[20, 40].object_id
    end

    chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
      assert_nothing_raised {c.put 20, 30, chip(0, 0, 10, 10)}
      assert_raise          {c.put 20, 30, chip(0, 0, 10, 10)}
    end
  end

  def test_remove()
    [
      [0, 0], [20, 30], [90, 90]
    ].each do |xx, yy|
      chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
        assert_nothing_raised {c.remove xx, yy}
        assert_equal 0, count_all_chips(c)
      end
    end

    [
      [20, 30, 0], [21, 31, 0], [25, 35, 0], [29, 39, 0],
      [19, 29, 1], [30, 40, 1],
      [29.999, 39.999, 0],
      [19.999, 29.999, 1]
    ].each do |xx, yy, count|
      chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
        c.put 20, 30, chip(0, 0, 10, 10)
        assert_equal 1,     count_all_chips(c)
        assert_nothing_raised {c.remove xx, yy}
        assert_equal count, count_all_chips(c)
      end
    end

    [
      [20, 30, 0], [30, 30, 0], [20, 40, 0], [30, 40, 0],
      [39, 40, 0], [30, 49, 0], [39, 49, 0],
      [19, 29, 4], [40, 50, 4],
      [39.999, 49.999, 0], [39.999, 40, 0], [30, 49.999, 0],
      [19.999, 29.999, 4],
    ].each do |xx, yy, count|
      chunk(10, 20, 30, 40, chip_size: 10).tap do |c|
        c.put 20, 30, chip(0, 0, 20, 20)
        assert_equal 4,     count_all_chips(c)
        assert_nothing_raised {c.remove xx, yy}
        assert_equal count, count_all_chips(c)
      end
    end
  end

  def test_delete_last_nils()
    chunk(0, 0, 30, 30, chip_size: 10).tap do |c|
      c.put 10, 10, chip(0, 0, 10, 10)
      c.put 10, 20, chip(0, 0, 10, 10)
      assert_equal 8, c.to_hash[:chips].size

      c.remove 10, 20
      assert_equal 5, c.to_hash[:chips].size
    end
  end

  def test_each_chip()
    c         = chunk 10, 20, 30, 40, chip_size: 10
    c.put 10, 20, chip(0, 0, 10, 10, id: 1)
    c.put 20, 30, chip(0, 0, 20, 20, id: 2)

    assert_equal(
      [[1, 10,20, 10,20], [2, 20,30, 20,30]],
      c.each_chip(include_hidden: false).map {|chip, x, y| [chip.id, chip.pos.x,chip.pos.y, x,y]})
    assert_equal(
      [
        [1, 10,20, 10,20],
        [2, 20,30, 20,30], [2, 20,30, 30,30], [2, 20,30, 20,40], [2, 20,30, 30,40]
      ],
      c.each_chip(include_hidden: true) .map {|chip, x, y| [chip.id, chip.pos.x,chip.pos.y, x,y]})
  end

  def test_each_chip_pos()
    c = chunk 10, 20, 30, 40, chip_size: 10
    assert_equal [],                   c.each_chip_pos( 0,  0, 10, 10).to_a
    assert_equal [],                   c.each_chip_pos(20, 30,  0,  0).to_a
    assert_equal [[20, 30]],           c.each_chip_pos(20, 30,  1,  1).to_a
    assert_equal [[10, 20]],           c.each_chip_pos(20, 30, -1, -1) .to_a
    assert_equal [[20, 30]],           c.each_chip_pos(20, 30, 10, 10).to_a
    assert_equal [[20, 30], [30, 30]], c.each_chip_pos(20, 30, 11, 10).to_a
    assert_equal [[20, 30], [20, 40]], c.each_chip_pos(20, 30, 10, 11).to_a
    assert_equal([[20, 30], [30, 30], [20, 40], [30, 40]],
                                       c.each_chip_pos(20, 30, 11, 11).to_a)
    assert_equal [[20, 30]],           c.each_chip_pos(29, 39,  1,  1) .to_a
    assert_equal [[20, 30], [30, 30]], c.each_chip_pos(29, 39,  2,  1) .to_a
  end

  def test_to_hash()
    c = chunk 10, 20, 30, 40, chip_size: 10
    c.put 20, 30, chip(0, 0, 10, 10, id: 1)
    assert_equal(
      {
        x: 10, y: 20, w: 30, h: 40, chip_size: 10,
        chips: [nil,nil,nil, nil,[1,20,30]]
      },
      c.to_hash)

    c.put 30, 40, chip(0, 0, 10, 20, id: 2)
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
    c1.put    10, 20, chip(0, 0, 10, 10, id: 1, image: img); assert_not_equal c1, c2
    c2.put    10, 20, chip(0, 0, 10, 10, id: 1, image: img); assert_equal     c1, c2
    c2.remove 10, 20
    c2.put    10, 20, chip(0, 0, 10, 10, id: 2, image: img); assert_not_equal c1, c2
  end

  def test_restore()
    img      = image
    chips    = R8::ChipList.restore({
      next_id: 3, chips: [
        {id: 1, x: 0, y: 0, w: 10, h: 10},
        {id: 2, x: 0, y: 0, w: 10, h: 20},
      ]
    }, img)
    restored = R8::Map::Chunk.restore({
      x: 10, y: 20, w: 30, h: 40, chip_size: 10,
      chips: [nil,nil,nil, nil,[1,20,30],nil, nil,nil,[2,30,40], nil,nil,[2,30,40]]
    }, chips)

    assert_equal(
      chunk(10, 20, 30, 40, chip_size: 10).tap {
        _1.put 20, 30, chip(0, 0, 10, 10, id: 1, image: img)
        _1.put 30, 40, chip(0, 0, 10, 20, id: 2, image: img)
      },
      restored)
    assert_equal restored[30, 40].object_id, restored[30, 50].object_id
  end

  private

  def count_all_chips(chunk)
    chunk.each_chip(include_hidden: true).to_a.size
  end

end# TestMapChunk

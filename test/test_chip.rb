require_relative 'helper'
using Reight


class TestChip < Test::Unit::TestCase

  def chip(...) = R8::Chip.new(...)

  def image(w = 1, h = 1) = create_image w, h

  def test_initialize()
    c = chip 1, image(2, 3), 4, 5, 6, 7
    assert_equal 1,            c.id
    assert_equal [2, 3],       c.image.then {[_1.w, _1.h]}
    assert_equal [4, 5, 6, 7], c.frame
  end

  def test_to_hash()
    assert_equal(
      {id: 1,           x: 4, y: 5, w: 6, h: 7},
      chip(1, image(2, 3), 4,    5,    6,    7).to_hash)
  end

  def test_compare()
    i = image 8, 9
    assert_equal     chip(1, i, 2, 3, 4, 5), chip(1, i,           2, 3, 4, 5)
    assert_not_equal chip(1, i, 2, 3, 4, 5), chip(0, i,           2, 3, 4, 5)
    assert_not_equal chip(1, i, 2, 3, 4, 5), chip(1, i,           0, 3, 4, 5)
    assert_not_equal chip(1, i, 2, 3, 4, 5), chip(1, i,           2, 0, 4, 5)
    assert_not_equal chip(1, i, 2, 3, 4, 5), chip(1, i,           2, 3, 0, 5)
    assert_not_equal chip(1, i, 2, 3, 4, 5), chip(1, i,           2, 3, 4, 0)
    assert_not_equal chip(1, i, 2, 3, 4, 5), chip(1, image(8, 9), 2, 3, 4, 5)
  end

  def test_restore()
    img = image 8, 9
    assert_equal(
      chip(                 1, img, 2,    3,    4,    5),
      R8::Chip.restore({id: 1,   x: 2, y: 3, w: 4, h: 5}, img))
  end

end# TestChip

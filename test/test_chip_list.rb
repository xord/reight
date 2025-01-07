require_relative 'helper'
using Reight


class TestChipList < Test::Unit::TestCase

  def chip(...)  = R8::Chip.new(...)

  def chips(...) = R8::ChipList.new(...)

  def image(w = 100, h = 100) = create_image w, h

  def test_initialize()
    i = image
    assert_equal i, chips(i).image
  end

  def test_at()
    i  = image
    cs = chips i
    assert_equal chip(1, i, 1, 2, 3, 4, shape: :rect), cs.at(1, 2, 3, 4)
    assert_equal chip(2, i, 5, 6, 7, 8, shape: :rect), cs.at(5, 6, 7, 8)
    assert_equal chip(1, i, 1, 2, 3, 4, shape: :rect), cs.at(1, 2, 3, 4)
  end

  def test_to_hash()
    i  = image
    cs = chips(i).tap do |o|
      o.at 1, 2, 3, 4
      o.at 5, 6, 7, 8
    end
    assert_equal(
      {
        next_id: 3,
        chips: [
          {id: 1, x: 1, y: 2, w: 3, h: 4, shape: :rect},
          {id: 2, x: 5, y: 6, w: 7, h: 8, shape: :rect}
        ]
      },
      cs.to_hash)
  end

  def test_compare()
    i  = image
    cs = chips(i).tap {_1.at 1, 2, 3, 4}

    assert_equal cs, chips(i).tap {_1.at 1, 2, 3, 4}

    assert_not_equal cs, chips(image 8, 9).tap {_1.at 0, 2, 3, 4}
    assert_not_equal cs, chips(i)
    assert_not_equal cs, chips(i)         .tap {_1.at 0, 2, 3, 4}
    assert_not_equal cs, chips(i)         .tap {_1.at 1, 0, 3, 4}
    assert_not_equal cs, chips(i)         .tap {_1.at 1, 2, 0, 4}
    assert_not_equal cs, chips(i)         .tap {_1.at 1, 2, 3, 0}
    assert_not_equal cs, chips(i).tap {
      _1.at 1, 2, 3, 4
      _1.at 5, 6, 7, 8
    }
  end

  def test_restore()
    img = image 8, 9
    assert_equal(
      chips(img).tap {                               _1.at 2,    3,    4,    5},
      R8::ChipList.restore({next_id: 2, chips: [{id: 1, x: 2, y: 3, w: 4, h: 5, shape: :rect}]}, img))
  end

end# TestChipList

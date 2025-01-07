require_relative 'helper'
using Reight


class TestChip < Test::Unit::TestCase

  def chip(...)           = R8::Chip.new(...)

  def image(w = 1, h = 1) = create_image w, h

  def vec(...)            = create_vector(...)

  def test_initialize()
    assert_equal 1,            chip(1, image(2, 3), 4, 5, 6, 7)                .id
    assert_equal [2, 3],       chip(1, image(2, 3), 4, 5, 6, 7)                .image.size
    assert_equal [4, 5, 6, 7], chip(1, image(2, 3), 4, 5, 6, 7)                .frame
    assert_nil                 chip(1, image(2, 3), 4, 5, 6, 7, pos: nil)      .pos
    assert_equal vec(8, 9),    chip(1, image(2, 3), 4, 5, 6, 7, pos: vec(8, 9)).pos
    assert_nil                 chip(1, image(2, 3), 4, 5, 6, 7)                .shape
    assert_nil                 chip(1, image(2, 3), 4, 5, 6, 7, shape: nil)    .shape
    assert_equal :rect,        chip(1, image(2, 3), 4, 5, 6, 7, shape: :rect)  .shape
    assert_false               chip(1, image(2, 3), 4, 5, 6, 7)                .sensor?
    assert_false               chip(1, image(2, 3), 4, 5, 6, 7, sensor: false) .sensor?
    assert_true                chip(1, image(2, 3), 4, 5, 6, 7, sensor: true)  .sensor?
  end

  def test_with()
    i23 = image 2, 3
    assert_equal 9,           chip(1, i23, 4, 5, 6, 7)                .with(id: 9)             .id
    assert_equal [8, 9],      chip(1, i23, 4, 5, 6, 7)                .with(image: image(8, 9)).image.size
    assert_equal 9,           chip(1, i23, 4, 5, 6, 7)                .with(x: 9)              .x
    assert_equal 9,           chip(1, i23, 4, 5, 6, 7)                .with(y: 9)              .y
    assert_equal 9,           chip(1, i23, 4, 5, 6, 7)                .with(w: 9)              .w
    assert_equal 9,           chip(1, i23, 4, 5, 6, 7)                .with(h: 9)              .h
    assert_equal vec(10, 11), chip(1, i23, 4, 5, 6, 7, pos: nil)      .with(pos: vec(10, 11))  .pos
    assert_equal vec(10, 11), chip(1, i23, 4, 5, 6, 7, pos: vec(8, 9)).with(pos: vec(10, 11))  .pos
    assert_equal :rect,       chip(1, i23, 4, 5, 6, 7, shape: nil)    .with(shape: :rect)      .shape
    assert_nil                chip(1, i23, 4, 5, 6, 7, shape: :rect)  .with(shape: nil)        .shape
    assert_true               chip(1, i23, 4, 5, 6, 7, sensor: nil)   .with(sensor: true)      .sensor?
    assert_false              chip(1, i23, 4, 5, 6, 7, sensor: nil)   .with(sensor: false)     .sensor?
    assert_false              chip(1, i23, 4, 5, 6, 7, sensor: true)  .with(sensor: false)     .sensor?
    assert_false              chip(1, i23, 4, 5, 6, 7, sensor: true)  .with(sensor: nil)       .sensor?

    i2030 = image 20, 30
    c1    = chip        1,         i23,      4,     5,     6,     7,  pos: nil,         shape: nil,   sensor: nil
    c2    = c1.with id: 10, image: i2030, x: 40, y: 50, w: 60, h: 70, pos: vec(80, 90), shape: :rect, sensor: true
    assert_equal chip(1,  i23,   4,  5,  6,  7,  pos: nil,         shape: nil,   sensor: nil),  c1
    assert_equal chip(10, i2030, 40, 50, 60, 70, pos: vec(80, 90), shape: :rect, sensor: true), c2
  end

  def test_to_hash()
    assert_equal(
      {id: 1,           x: 4, y: 5, w: 6, h: 7},
      chip(1, image(2, 3), 4,    5,    6,    7).to_hash)
    assert_equal(
      {id: 1,           x: 4, y: 5, w: 6, h: 7, pos:    [8, 9], shape: :rect, sensor: true},
      chip(1, image(2, 3), 4,    5,    6,    7, pos: vec(8, 9), shape: :rect, sensor: true).to_hash)
  end

  def test_compare()
    i = image 8, 9
    assert_equal(
      chip(1, i, 2, 3, 4, 5, pos: nil, shape: nil, sensor: false),
      chip(1, i, 2, 3, 4, 5, pos: nil, shape: nil, sensor: false))
    assert_equal(
      chip(1, i, 2, 3, 4, 5, pos: vec(6, 7), shape: :rect, sensor: true),
      chip(1, i, 2, 3, 4, 5, pos: vec(6, 7), shape: :rect, sensor: true))

    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(0, i, 2, 3, 4, 5))
    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(1, i, 0, 3, 4, 5))
    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(1, i, 2, 0, 4, 5))
    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(1, i, 2, 3, 0, 5))
    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(1, i, 2, 3, 4, 0))
    assert_not_equal(
      chip(1, i,           2, 3, 4, 5),
      chip(1, image(8, 9), 2, 3, 4, 5))
    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(1, i, 2, 3, 4, 5, pos: vec(6, 7)))
    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(1, i, 2, 3, 4, 5, shape: :rect))
    assert_not_equal(
      chip(1, i, 2, 3, 4, 5),
      chip(1, i, 2, 3, 4, 5, sensor: true))
  end

  def test_restore()
    img = image 8, 9
    assert_equal(
      chip(                 1, img, 2,    3,    4,    5, pos: nil, shape: nil, sensor: false),
      R8::Chip.restore({id: 1,   x: 2, y: 3, w: 4, h: 5, pos: nil, shape: nil, sensor: false}, img))
    assert_equal(
      chip(                 1, img, 2,    3,    4,    5, pos: vec(6, 7), shape: :rect, sensor: true),
      R8::Chip.restore({id: 1,   x: 2, y: 3, w: 4, h: 5, pos:    [6, 7], shape: :rect, sensor: true}, img))
  end

end# TestChip

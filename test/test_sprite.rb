require_relative 'helper'
using Reight


class TestSpeite < Test::Unit::TestCase

  def sprite(...) = R8::Sprite.new(...)

  def test_prop()
    assert_raise(NoMethodError) {sprite.foo}
    assert_raise(NoMethodError) {sprite.foo = 9}

    sp = sprite
    assert_nothing_raised {sp[:foo] = 1}
    assert_nothing_raised {sp .foo}
    assert_equal 1,        sp[:foo]
    assert_equal 1,        sp .foo

    assert_nothing_raised {sp .foo = 2}
    assert_equal 2,        sp[:foo]
    assert_equal 2,        sp .foo

    assert_nothing_raised {sp .foo = 3, 4}
    assert_equal [3, 4],   sp[:foo]
    assert_equal [3, 4],   sp .foo
  end

end# TestChip

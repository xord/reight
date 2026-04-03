require_relative 'helper'


class TestMMLCompiler < Test::Unit::TestCase

  def compile(str)
    Reight::MMLCompiler.new.compile(str)
  end

  def procs(str, klass = nil)
    compile(str)[0].each.with_object([]) do |(processor, *), array|
      processor = find_input(processor) {_1.class == klass} if klass
      array << processor
    end
  end

  def times(str)
    compile(str)[0].each.with_object([]) do |(_, offset, duration), array|
      array << [offset, duration]
    end
  end

  def duration(str)
    compile(str)[1]
  end

  def oscillators(str) = procs(str, Beeps::Oscillator)

  def gains(str)       = procs(str, Beeps::Gain)

  def find_input(processor, &block)
    p = processor
    while p
      return p if block.call p
      p = p.input
    end
    nil
  end

  def test_note_frequency()
    assert_in_delta 440,     oscillators('A')    .first.freq

    assert_in_delta 246.942, oscillators('O3 B') .first.freq
    assert_in_delta 261.626, oscillators('O4 C') .first.freq
    assert_in_delta 277.183, oscillators('O4 C+').first.freq
    assert_in_delta 277.183, oscillators('O4 D-').first.freq
    assert_in_delta 293.665, oscillators('O4 D') .first.freq
    assert_in_delta 311.127, oscillators('O4 D+').first.freq
    assert_in_delta 311.127, oscillators('O4 E-').first.freq
    assert_in_delta 329.628, oscillators('O4 E') .first.freq
    assert_in_delta 349.228, oscillators('O4 F') .first.freq
    assert_in_delta 369.994, oscillators('O4 F+').first.freq
    assert_in_delta 369.994, oscillators('O4 G-').first.freq
    assert_in_delta 391.995, oscillators('O4 G') .first.freq
    assert_in_delta 415.305, oscillators('O4 G+').first.freq
    assert_in_delta 415.305, oscillators('O4 A-').first.freq
    assert_in_delta 440,     oscillators('O4 A') .first.freq
    assert_in_delta 466.164, oscillators('O4 A+').first.freq
    assert_in_delta 466.164, oscillators('O4 B-').first.freq
    assert_in_delta 493.883, oscillators('O4 B') .first.freq
    assert_in_delta 523.251, oscillators('O5 C') .first.freq
  end

  def test_note_duration()
    assert_in_delta 0.5,     duration('C')

    assert_in_delta 4,       duration('T60 C1')
    assert_in_delta 6,       duration('T60 C1.')
    assert_in_delta 7,       duration('T60 C1..')
    assert_in_delta 7.5,     duration('T60 C1...')
    assert_in_delta 2,       duration('T60 C2')
    assert_in_delta 3,       duration('T60 C2.')
    assert_in_delta 3.5,     duration('T60 C2..')
    assert_in_delta 3.75,    duration('T60 C2...')
    assert_in_delta 1,       duration('T60 C4')
    assert_in_delta 1.5,     duration('T60 C4.')
    assert_in_delta 1.75,    duration('T60 C4..')
    assert_in_delta 1.875,   duration('T60 C4...')
    assert_in_delta 0.5,     duration('T60 C8')
    assert_in_delta 0.75,    duration('T60 C8.')
    assert_in_delta 0.875,   duration('T60 C8..')
    assert_in_delta 0.9375,  duration('T60 C8...')
    assert_in_delta 0.25,    duration('T60 C16')
    assert_in_delta 0.375,   duration('T60 C16.')
    assert_in_delta 0.4375,  duration('T60 C16..')
    assert_in_delta 0.46875, duration('T60 C16...')

    assert_in_delta 2,     duration('T120 C1')
    assert_in_delta 1,     duration('T120 C2')
    assert_in_delta 0.5,   duration('T120 C4')
    assert_in_delta 0.25,  duration('T120 C8')
    assert_in_delta 0.125, duration('T120 C16')

    assert_in_delta 1, duration('T60 C-4')
    assert_in_delta 1, duration('T60 C+4')
    assert_in_delta 1, duration('T60 C#4')
    assert_in_delta 2, duration('T60 L4 C C')

    assert_equal [[0, 1], [1, 1]], times('T60 L4 C C')
  end

  def test_octave()
    assert_in_delta 440,     oscillators('O4   A').first.freq
    assert_in_delta 440 / 2, oscillators('O3   A').first.freq
    assert_in_delta 440 * 2, oscillators('O5   A').first.freq
    assert_in_delta 440 / 2, oscillators('O4 < A').first.freq
    assert_in_delta 440 * 2, oscillators('O4 > A').first.freq
  end

  def test_tone()
    assert_equal     oscillators('@0 C').first.samples, oscillators(   'C').first.samples
    assert_not_equal oscillators('@0 C').first.samples, oscillators('@1 C').first.samples
  end

  def test_velocity()
    assert_in_delta 1,   gains(    'C').first.gain
    assert_in_delta 0,   gains('V0  C').first.gain
    assert_in_delta 0.5, gains('V63 C').first.gain, 0.01
  end

  def test_tie()
    assert_equal [[0, 2]],         times('T60 L4 C  & C')
    assert_equal [[0, 3]],         times('T60 L4 C  & C & C')
    assert_equal [[0, 2.5]],       times('T60 L4 C. & C')
    assert_equal [[0, 3]],         times('T60 L4 C. & C.')
    assert_equal [[0, 2], [2, 1]], times('T60 L4 C  & C E')
  end

  def test_rest()
    assert_equal [[0, 1], [2, 1]], times('T60 L4 C    R    C')
    assert_equal [[0, 1], [3, 1]], times('T60 L4 C    R2   C')
    assert_equal [[0, 1], [3, 1]], times('T60 L4 C L2 R L4 C')
  end

  def test_comment()
    assert_in_delta 1, duration("; comment\nT60 L4 C")
  end

end# TestMMLCompiler

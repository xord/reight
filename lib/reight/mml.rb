class MMLCompiler

  TONES = %i[
    sine triangle square sawtooth pulse12_5 pulse25 noise
  ]

  def compile(str)
    scanner  = StringScanner.new str.gsub(/;.*\n/, '')
    seq      = Beeps::Sequencer.new
    bpm      = 120
    time     = 0
    tone     = 0
    octave   = 4
    length   = 4
    velocity = 127
    prev_osc = nil

    scanner.skip /\s*/
    until scanner.empty?
      case
      when scanner.scan(/T\s*(\d+)/i)
        bpm      = scanner[1].to_i
      when scanner.scan(/O\s*(\d+)/i)
        octave   = scanner[1].to_i
      when scanner.scan(/L\s*(\d+)/i)
        length   = scanner[1].to_i
      when scanner.scan(/V\s*(\d+)/i)
        velocity = scanner[1].to_i
      when scanner.scan(/R\s*(\d+)?/i)
        time    += seconds scanner[1]&.to_i || length, bpm
        prev_osc = nil
      when scanner.scan(/@\s*(\d+)/)
        tone     = scanner[1].to_i
      when scanner.scan(/([<>])/)
        case scanner[1]
        when '<' then octave -= 1
        when '>' then octave += 1
        end
      when scanner.scan(/([CDEFGAB])\s*([#+-]+)?\s*(\d+)?\s*(\.+)?/i)&.chomp
        char, offset, len, dots = [1, 2, 3, 4].map {scanner[_1]}

        freq = frequency(char, offset, octave) or next
        sec  = seconds len&.to_i || length, bpm
        sec *= 1 + dots.size.times.map {0.5 / (_1 + 1)}.sum if dots
        osc  = oscillator TONES[tone], 32, freq: freq
        env  = Beeps::Envelope.new {note_on; note_off sec}
        gain = Beeps::Gain.new gain: velocity.clamp(0, 127) / 127.0
        seq.add osc >> gain, time, sec
        time += sec

        sync_phase osc, prev_osc if prev_osc
        prev_osc = osc
      else
        raise "Unknown input: #{scanner.rest[..10]}"
      end
      scanner.skip /\s*/
    end
    return seq, time
  end

  private

  DISTANCES = -> {
    notes   = 'c_d_ef_g_a_b'.each_char.with_index.reject {|c,| c == '_'}.to_a
    octaves = (0..11).to_a
    octaves.product(notes)
      .map.with_object({}) {|(octave, (note, index)), hash|
        hash[[note, octave]] = octave * 12 + index - 57
      }
  }.call

  def frequency(note, offset, octave)
    raise "Bad note: '#{note}'" unless note =~ /[cdefgab]/i

    distance  = DISTANCES[[note.downcase, octave.to_i]]
    distance += (offset || '').each_char.reduce(0) {|value, char|
      case char
      when '+', '#' then value + 1
      when '-'      then value - 1
      else               value
      end
    }
    440 * (2 ** (distance.to_f / 12))
  end

  def seconds(length, bpm)
    60.0 / bpm / length
  end

  def sync_phase(osc, prev)
    osc.on(:start) {osc.phase = prev.phase}
  end

  def oscillator(type, size, **kwargs)
    case type
    when :noise then Beeps::Oscillator.new type
    else
      samples = (@samples ||= {})[type] ||= create_samples type, size
      Beeps::Oscillator.new samples: samples, **kwargs
    end
  end

  def create_samples(type, size)
    input = size.times.map {_1.to_f / size}
    duty  = {pulse12_5: 0.125, pulse25: 0.25, pulse75: 0.75}[type] || 0.5
    case type
    when :sine     then input.map {Math.sin _1 * Math::PI * 2}
    when :triangle then input.map {_1 < 0.5 ? _1 * 4 - 1 : 3 - _1 * 4}
    when :sawtooth then input.map {_1 * 2 - 1}
    else                input.map {_1 < duty ? 1 : -1}
    end
  end

end# MMLCompiler

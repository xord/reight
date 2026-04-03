class Reight::MMLCompiler

  TONES = %i[
    sine triangle square sawtooth pulse12_5 pulse25 noise
  ]

  def compile(str)
    scanner  = StringScanner.new str.gsub(/;.*\n/, '')
    seq      = Beeps::Sequencer.new
    note     = Note.new 0, 120, 4, 0, 4, 127, 1, 0
    pending  = nil
    prev_osc = nil
    tie      = false

    scanner.skip /\s*/
    until scanner.empty?
      case
      when scanner.scan(/T\s*(\d+)/i)
        note.bpm      = scanner[1].to_i
      when scanner.scan(/O\s*(\d+)/i)
        note.octave   = scanner[1].to_i
      when scanner.scan(/([<>])/)
        note.octave  +=
          case scanner[1]
          when '<' then -1
          when '>' then +1
          else           0
          end
      when scanner.scan(/@\s*(\d+)/)
        note.tone     = scanner[1].to_i
      when scanner.scan(/L\s*(\d+)/i)
        note.length   = scanner[1].to_i
      when scanner.scan(/V\s*(\d+)/i)
        note.velocity = scanner[1].to_i
      when scanner.scan(/R\s*(\d+)?/i)
        note.time += seconds scanner[1]&.to_i || note.length, note.bpm
        prev_osc   = nil
        tie        = false
      when scanner.scan(/&/)
        tie = true
      when scanner.scan(/([CDEFGAB])\s*([#+-]+)?\s*(\d+)?\s*(\.+)?/i)&.chomp
        if pending && !tie
          prev_osc = add_note seq, pending, prev_osc, note
          pending  = nil
        end
        tie = false

        char, offset, len, dots = [1, 2, 3, 4].map {scanner[_1]}
        sec                     = seconds len&.to_i || note.length, note.bpm
        sec                    *= 1 + dots.size.times.map {0.5 ** (_1 + 1)}.sum if dots

        pending         ||= note.dup
        pending.frequency = frequency char, offset, note.octave
        pending.seconds  += sec
      else
        raise "Unknown input: #{scanner.rest[..10]}"
      end

      scanner.skip /\s*/
    end

    add_note seq, pending, prev_osc, note if pending
    return seq, note.time
  end

  private

  Note = Struct.new :time, :bpm, :octave, :tone, :length, :velocity, :frequency, :seconds

  def seconds(length, bpm)
    60.0 * 4 / bpm / length
  end

  DISTANCES = -> {
    notes   = 'c_d_ef_g_a_b'.each_char.with_index.reject {|c,| c == '_'}.to_a
    octaves = (0..11).to_a
    octaves.product(notes)
      .map.with_object({}) {|(octave, (note, index)), hash|
        hash[[note, octave]] = octave * 12 + index - 57
      }
  }.call

  def frequency(note, offset, octave)
    distance  = DISTANCES[[note.downcase, octave.to_i]] ||
      (raise ArgumentError, "note:'#{note}' octave:'#{octave}' offset:'#{offset}'")
    distance += (offset || '').each_char.reduce(0) {|value, char|
      case char
      when '+', '#' then value + 1
      when '-'      then value - 1
      else               value
      end
    }
    440 * (2 ** (distance.to_f / 12))
  end

  def add_note(seq, note, prev_osc, state)
    processor   = to_processor note
    osc         = find_input(processor) {_1.class == Beeps::Oscillator}
    sync_phase osc, prev_osc if prev_osc
    seq.add processor, note.time, note.seconds
    state.time += note.seconds
    return osc
  end

  def to_processor(note)
    tone = TONES[note.tone] || (raise ArgumentError, "tone:'#{note.tone}'")
    osc  = oscillator tone, 32, freq: note.frequency
    env  = Beeps::Envelope.new {note_on; note_off note.seconds}
    gain = Beeps::Gain.new gain: note.velocity.clamp(0, 127) / 127.0
    osc >> env >> gain
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

  def sync_phase(osc, prev)
    osc.on(:start) {osc.phase = prev.phase}
  end

  def find_input(processor, &block)
    p = processor
    while p
      return p if block.call p
      p = p.input
    end
    nil
  end

end# MMLCompiler

using Reight


class Reight::Sound

  include Enumerable

  BPM_MAX = 999

  def initialize(bpm = 120)
    @bpm      = bpm
    @sequence = [[]]
  end

  attr_reader :bpm

  def bpm=(bpm)
    raise ArgumentError, "Invalid bpm: #{bpm}"                            if bpm <= 0
    raise ArgumentError, "bpm exceeds the max value (#{BPM_MAX}): #{bpm}" if bpm >  999
    @bpm = bpm
  end

  def play(gain: 1.0, &block)
    return block&.call false if empty?
    stop
    @playing = sound = to_sound
    sound.play gain: gain

    if block
      id = "__sound_playing_check_#{sound.object_id}"
      set_interval 0.1, id: id do
        next if sound.playing? == true
        block.call true
        clear_interval id
      end
    end
  end

  def stop()
    @playing&.stop
    @playing = nil
  end

  def clear()
    @sequence = [[]]
  end

  def add_note(time_index, note_index, tone)
    raise 'The note already exists' if note_at time_index, note_index
    (@sequence[time_index] ||= []) << Note.new(note_index, tone)
  end

  def remove_note(time_index, note_index)
    @sequence[time_index]&.delete_if {_1.index == note_index}
  end

  def note_at(time_index, note_index)
    @sequence[time_index]&.find {_1.index == note_index}
  end

  def each_note(time_index: nil, &block)
    return enum_for :each_note, time_index: time_index unless block
    if time_index
      @sequence[time_index]&.each do |note|
        block.call note, time_index
      end
    else
      @sequence.each.with_index do |notes, time_i|
        notes&.each do |note|
          block.call note, time_i
        end
      end
    end
  end

  alias    add    add_note
  alias remove remove_note
  alias     at        note_at
  alias   each   each_note

  def playing?()
    @playing = nil if @playing&.playing? == false
    !!@playing
  end

  def empty? = @sequence.all? {!_1 || _1.empty?}

  def to_hash()
    {
      bpm:      @bpm,
      sequence: @sequence.map {|notes| notes&.map {_1.to_hash}}
    }
  end

  def self.restore(hash)
    bpm, sequence = hash.values_at :bpm, :sequence
    #hash => {bpm:, sequence:}
    new(bpm).tap do |obj|
      obj.instance_eval do
        @sequence = sequence.map do |notes|
          notes&.map {Note.restore _1}
        end
      end
    end
  end

  private

  def to_sound()
    RubySketch::Sound.new Beeps::Sound.new(*sequencer)
  end

  def sequencer()
    seq   = Beeps::Sequencer.new
    time  = 0
    prevs = {}
    @sequence.each do |notes|
      sec       = Note.seconds 4, @bpm
      new_prevs = {}
      notes&.each do |note|
        osc       = Note.oscillator note.tone, 32
        osc.freq  = note.frequency
        osc.phase = osc.freq * time
        env       = Note.envelope sec
        seq.add osc >> env, time, sec

        new_prevs[note.tone] = [note.index, env, sec]
        pindex, penv, psec   = prevs[note.tone]

        if pindex && pindex == note.index
           env.attack  = 0
          penv.release = 0
          penv.note_off psec * 2# skip release phase
        end
      end
      time += sec
      prevs = new_prevs
    end
    return seq >> Note.gain, time
  end

end# Sound


class Reight::Sound::Note

  MAX   = 127

  TONES = %i[
    sine triangle square sawtooth pulse12_5 pulse25 noise
  ]

  def initialize(index, tone = TONES.first)
    raise "Invalid note index: #{index}" unless (0..MAX).include? index
    raise "Invalid tone: #{tone}"        unless    TONES.include? tone
    @index, @tone = index, tone
  end

  attr_reader :index, :tone

  def play(bpm)
    to_sound(bpm).play
  end

  def frequency()
    440 * (2 ** ((@index - 69).to_f / 12))
  end

  INDEX2NOTE = -> {
    notes   = %w[ c c+ d d+ e f f+ g g+ a a+ b ].map {_1.sub '+', '#'}
    octaves = (-1..9).to_a
    octaves.product(notes)
      .each_with_object({}).with_index do |((octave, note), hash), index|
        hash[index] = "#{note}#{octave}"
      end
  }.call

  def to_s()
    "#{INDEX2NOTE[@index]}:#{@tone}"
  end

  def to_hash()
    {index: @index, tone: TONES.index(@tone)}
  end

  def to_sound(bpm)
    osc  = self.class.oscillator tone, 32, freq: frequency
    sec  = self.class.seconds 4, bpm
    seq  = Beeps::Sequencer.new.tap {_1.add osc, 0, sec}
    env  = self.class.envelope sec
    gain = self.class.gain
    RubySketch::Sound.new Beeps::Sound.new(seq >> env >> gain, sec)
  end

  def self.oscillator(type, size, **kwargs)
    case type
    when :noise then Beeps::Oscillator.new type, **kwargs
    else
      samples = (@samples ||= {})[type] ||= create_samples type, size
      Beeps::Oscillator.new samples: samples, **kwargs
    end
  end

  def self.create_samples(type, size)
    input = size.times.map {_1.to_f / size}
    duty  = {pulse12_5: 0.125, pulse25: 0.25, pulse75: 0.75}[type] || 0.5
    case type
    when :sine     then input.map {Math.sin _1 * Math::PI * 2}
    when :triangle then input.map {_1 < 0.5 ? _1 * 4 - 1 : 3 - _1 * 4}
    when :sawtooth then input.map {_1 * 2 - 1}
    else                input.map {_1 < duty ? 1 : -1}
    end
  end

  def self.envelope(seconds)
    Beeps::Envelope.new release: seconds * 0.05 do
      note_on
      note_off seconds * 0.95
    end
  end

  def self.gain(gain = 0.2)
    Beeps::Gain.new gain
  end

  def self.seconds(length, bpm)
    raise ArgumentError, "Invalid length: #{length}" if length <= 0
    raise ArgumentError, "Invalid bpm: #{bpm}"       if bpm    <= 0
    60.0 / bpm / length
  end

  def self.restore(hash)
    index, tone = hash.values_at :index, :tone
    #hash => {index:, tone:}
    new index, TONES[tone]
  end

end# Note

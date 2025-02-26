using Reight


class Reight::Text

  include Reight::Activatable
  include Reight::Hookable
  include Reight::HasHelp

  def initialize(text = '', label: nil, regexp: nil, &changed)
    hook :changed

    super()
    @label, @regexp = label, regexp
    @shake          = 0
    self.changed(&changed) if changed

    self.value = text
  end

  attr_accessor :label

  attr_reader :value

  def revert()
    self.value = @old_value
    @shake     = 6
  end

  def focus=(bool)
    sprite.capture = bool
    revert unless valid? value
    changed! value, self if value != @old_value
  end

  def focus?()
    sprite.capturing?
  end

  def value=(text)
    str = text.to_s
    return if str == @value
    return unless valid? str
    @value = str
  end

  def valid?(value = self.value, ignore_regexp: focus?)
    case
    when !value        then false
    when ignore_regexp then true
    when !@regexp      then true
    else value =~ @regexp
    end
  end

  def draw()
    sp = sprite
    no_stroke

    if @shake != 0
      translate rand(-@shake.to_f..@shake.to_f), 0
      @shake *= rand(0.7..0.9)
      @shake  = 0 if @shake.abs < 0.1
    end

    fill focus? ? 230 : 200
    rect 0, 0, sp.w, sp.h, 3

    show_old = value == ''
    text     = show_old ? @old_value : value
    text     = label + text unless focus?
    fill show_old ? 200 : 50
    text_align CENTER, CENTER
    text text, 0, 0, sp.w, sp.h

    if focus? && (frame_count % 60) < 30
      fill 100
      bounds = text_font.text_bounds value
      rect (sp.w + bounds.w) / 2 - 1, (sp.h - bounds.h) / 2, 2, bounds.h
    end
  end

  def key_pressed(key, code)
    case code
    when ESC               then self.value  = @old_value; self.focus = false
    when ENTER             then self.focus  = false
    when DELETE, BACKSPACE then self.value  = value.split('').tap {_1.pop}.join
    else                        self.value += key if key && valid?(key)
    end
  end

  def clicked(x, y)
    if focus?
      return if hit? x, y
      self.value = @old_value if !valid?(ignore_regexp: false)
      self.focus = false
    else
      self.focus         = true
      @old_value, @value = @value.dup, ''
    end
  end

  def hit?(x, y)
    sp = sprite
    (0...sp.w).include?(x) && (0...sp.h).include?(y)
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new(physics: false).tap do |sp|
      sp.draw          {draw}
      sp.key_pressed   {key_pressed sp.key, sp.key_code}
      sp.mouse_clicked {clicked sp.mouse_x, sp.mouse_y}
    end
  end

end# Text

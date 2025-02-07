using Reight


class Reight::R8

  def initialize(path)
    raise if $r8__
    $r8__ = self

    @path        = path
    self.current = apps.first
  end

  attr_reader :current

  def version()
    '0.1'
  end

  def project()
    @project ||= Reight::Project.new @path
  end

  def apps()
    @apps ||= [
      Reight::Runner.new(project),
      Reight::SpriteEditor.new(project),
      Reight::MapEditor.new(project),
      Reight::SoundEditor.new(project)
    ]
  end

  def flash(...) = current.flash(...)

  def icons()
    @icons ||= loadImage(File.expand_path('../../res/icons.png', __dir__)).tap do |img|
      transp = color '#FF77A8'
      img.load_pixels
      img.pixels.map! {|c| c == transp ? color(0, 0, 0, 0) : c}
      img.update_pixels
    end
  end

  def current=(app)
    return if app == @current
    @current&.deactivated
    @current = app
    @current.activated

    set_title [
      self.class.name.split('::').first,
      version,
      '|',
      current.class.name.split('::').last
    ].join ' '
  end

  def setup()
    w, h = Reight::App::SCREEN_WIDTH, Reight::App::SCREEN_HEIGHT
    createCanvas w, h
    window_resize(*[w, h].map {_1 * 3})
    text_font r8.project.font, r8.project.font_size
  end

  def draw()           = current.draw
  def key_pressed()    = current.key_pressed
  def key_released()   = current.key_released
  def key_typed()      = current.key_typed
  def mouse_pressed()  = current.mouse_pressed
  def mouse_released() = current.mouse_released
  def mouse_moved()    = current.mouse_moved
  def mouse_dragged()  = current.mouse_dragged
  def mouse_clicked()  = current.mouse_clicked
  def double_clicked() = current.double_clicked
  def mouse_wheel()    = current.mouse_wheel
  def touch_started()  = current.touch_started
  def touch_ended()    = current.touch_ended
  def touch_moved()    = current.touch_moved
  def window_moved()   = apps.each {_1.window_moved}
  def window_resized() = apps.each {_1.window_resized}

end# R8

using Reight


class Reight::R8

  def initialize()
    raise if $r8
    $r8 = self

    navigator.activate
  end

  def version()
    '0.1'
  end

  def project()
    @project ||= Reight::Project.new File.expand_path '../..', __dir__
  end

  def apps()
    @apps ||= [
      Reight::Runner.new(project),
      Reight::SpriteEditor.new(project),
      Reight::MapEditor.new(project)
    ]
  end

  def flash(...) = navigator.flash(...)

  attr_reader :current

  def current=(app)
    return if app == @current
    @current&.deactivate
    @current = app
    @current.activate

    set_title [
      self.class.name.split('::').first,
      version,
      '|',
      current.class.name.split('::').last
    ].join ' '
  end

  def setup()
    size 256, 224
    text_font r8.project.font, r8.project.font_size
  end

  def draw()
    current.draw
    navigator.draw
  end

  def key_pressed()
    navigator.key_pressed
    current.key_pressed
  end

  def key_released()
    navigator.key_released
    current.key_released
  end

  def key_typed()
    navigator.key_typed
    current.key_typed
  end

  def mouse_pressed()
    navigator.mouse_pressed
    current.mouse_pressed
  end

  def mouse_released()
    navigator.mouse_released
    current.mouse_released
  end

  def mouse_moved()
    navigator.mouse_moved
    current.mouse_moved
  end

  def mouse_dragged()
    navigator.mouse_dragged
    current.mouse_dragged
  end

  def mouse_clicked()
    navigator.mouse_clicked
    current.mouse_clicked
  end

  def double_clicked()
    navigator.double_clicked
    current.double_clicked
  end

  def mouse_wheel()
    navigator.mouse_wheel
    current.mouse_wheel
  end

  def touch_started()
    navigator.touch_started
    current.touch_started
  end

  def touch_ended()
    navigator.touch_ended
    current.touch_ended
  end

  def touch_moved()
    navigator.touch_moved
    current.touch_moved
  end

  def window_moved()
    navigator.window_moved
    apps.each {_1.window_moved}
  end

  def window_resized()
    navigator.window_resized
    apps.each {_1.window_resized}
  end

  private

  def navigator()
    @navigator ||= Reight::Navigator.new(project)
  end

end# R8

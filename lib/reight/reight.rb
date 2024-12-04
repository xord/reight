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

  def window_resized()
    navigator.window_resized
    apps.each {_1.window_resized}
  end

  def key_pressed()
    navigator.key_pressed
    current.key_pressed
  end

  def key_released()
    navigator.key_released
    current.key_released
  end

  private

  def navigator()
    @navigator ||= Reight::Navigator.new(project)
  end

end# R8

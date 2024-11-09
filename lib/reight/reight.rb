using RubySketch


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
    @apps ||= [Reight::SpriteEditor.new, Reight::MapEditor.new]
  end

  def flash(...) = navigator.flash(...)

  attr_reader :current

  def current=(app)
    return if app == @current
    @current&.deactivate
    @current = app
    @current.activate

    setTitle [
      self.class.name.split('::').first,
      version,
      '|',
      current.class.name.split('::').last
    ].join ' '
  end

  def setup()
    size 256, 224
    textFont r8.project.font, r8.project.fontSize
  end

  def draw()
    current.draw
    navigator.draw
  end

  def resized()
    navigator.resized
    apps.each {_1.resized}
  end

  def keyPressed(key)
    navigator.keyPressed key
    current.keyPressed key
  end

  def keyReleased(key)
    navigator.keyReleased key
    current.keyReleased key
  end

  private

  def navigator()
    @navigator ||= Reight::Navigator.new
  end

end# R8

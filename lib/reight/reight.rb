using RubySketch


class Reight

  def initialize()
    raise if $reight
    $reight = self

    navigator.activate
  end

  def version()
    '0.1'
  end

  def project()
    @project ||= Project.new File.expand_path '../..', __dir__
  end

  def apps()
    @apps ||= [SpriteEditor.new]
  end

  def flash(...) = navigator.flash(...)

  attr_reader :current

  def current=(app)
    return if app == @current
    @current&.deactivate
    @current = app
    @current.activate
    setTitle "#{self.class.name} #{version} | #{current.name}"
  end

  def setup()
    size 256, 224
    textFont @font, 8
  end

  def draw()
    current.draw
    navigator.draw
  end

  def resized()
    navigator.resized
    @apps.each {_1.resized}
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
    @navigator ||= Navigator.new
  end

end# Reight

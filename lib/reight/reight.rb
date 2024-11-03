using RubySketch


class Reight

  def initialize()
    raise if $reight
    $reight = self

    self.current = apps.first
  end

  def version()
    '0.1'
  end

  def project()
    @project ||= Project.new File.expand_path '../..', __dir__
  end

  attr_reader :current

  def current=(app)
    @current&.deactivate
    @current = app
    @current.activate
  end

  def setup()
    size 256, 224
    setTitle "Reight #{version}"

    textFont @font, 8
  end

  def draw()
    current.draw
  end

  def resized()
    @apps.each {_1.resized}
  end

  def keyPressed(key)
    current.keyPressed key
  end

  private

  def apps()
    @apps ||= [SpriteEditor.new]
  end

end# Reight

using RubySketch


class App

  def name()
    self.class.name
  end

  def sprites()
    []
  end

  def activate()
    sprites.each {|sp| addSprite sp}
  end

  def deactivate()
    sprites.each {|sp| removeSprite sp}
  end

  def draw()
  end

  def resized()
  end

  def keyPressed()
  end

end# App

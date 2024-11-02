using RubySketch


class Project

  def initialize(projectDir)
    raise 'the project directory is required' unless projectDir
    @projectDir = projectDir
    load
  end

  attr_reader :projectDir, :settings

  def projectPath = "#{projectDir}/project.json"

  def spriteImageWidth  = 1024

  def spriteImageHeight = 1024

  def spriteImagePath   = "#{projectDir}/sprite.png"

  def spriteImage()
    @spriteImage ||= loadSpriteImage spriteImagePath
  end

  def paletteColors()
    %w[
      #000000 #1D2B53 #7E2553 #008751 #AB5236 #5F574F #C2C3C7 #FFF1E8
      #FF004D #FFA300 #FFEC27 #00E436 #29ADFF #83769C #FF77A8 #FFCCAA
    ]
  end

  private

  def load()
    @settings = JSON.parse File.read projectPath
  rescue
    @settings = {}
  end

  def save()
    File.write projectPath, @settings.to_json
  end

  def loadSpriteImage(path)
    i = loadImage path
    g = createGraphics i.width, i.height
    g.beginDraw {|g| g.image i, 0, 0}
    g
  rescue
    g = createGraphics spriteImageWidth, spriteImageHeight
    g.beginDraw {|g| g.background 0, 0, 0}
    g
  end

end# Project

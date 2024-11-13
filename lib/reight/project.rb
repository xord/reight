using Reight


class Reight::Project

  def initialize(project_dir)
    raise 'the project directory is required' unless project_dir
    @project_dir = project_dir
    load
  end

  attr_reader :project_dir, :settings

  def project_path = "#{project_dir}/project.json"

  def font         = @font ||= create_font(nil, font_size)

  def font_size    = 8

  def sprite_image_width  = 1024

  def sprite_image_height = 1024

  def sprite_image_path   = "#{project_dir}/sprite.png"

  def sprite_image()
    @sprite_image ||= load_sprite_image sprite_image_path
  end

  def palette_colors()
    %w[
      #000000 #1D2B53 #7E2553 #008751 #AB5236 #5F574F #C2C3C7 #FFF1E8
      #FF004D #FFA300 #FFEC27 #00E436 #29ADFF #83769C #FF77A8 #FFCCAA
    ]
  end

  private

  def load()
    @settings = JSON.parse File.read project_path
  rescue
    @settings = {}
  end

  def save()
    File.write project_path, @settings.to_json
  end

  def load_sprite_image(path)
    i = load_image path
    g = create_graphics i.width, i.height
    g.begin_draw {|g| g.image i, 0, 0}
    g
  rescue
    g = create_graphics sprite_image_width, sprite_image_height
    g.begin_draw {|g| g.background 0, 0, 0}
    g
  end

end# Project

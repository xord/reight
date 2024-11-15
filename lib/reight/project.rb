using Reight


class Reight::Project

  def initialize(project_dir)
    raise 'the project directory is required' unless project_dir
    @project_dir = project_dir
    @settings    = {}
    load
  end

  attr_reader :project_dir, :settings

  def project_path = "#{project_dir}/project.json"

  def font      = @font ||= create_font(nil, font_size)

  def font_size = 8

  def chips_path = "#{project_dir}/chips.json"

  def chips()
    @chips ||=
      if File.file? chips_path
        ChipList.restore JSON.parse(File.read chips_path), chips_image
      else
        ChipList.new chips_image
      end
  end

  def chips_image_width  = 1024

  def chips_image_height = 1024

  def chips_image_path   = "#{project_dir}/chips.png"

  def chips_image()
    @chips_image ||=
      begin
        i = load_image chips_image_path
        create_graphics(i.width, i.height).tap do |g|
          g.begin_draw {g.image i, 0, 0}
        end
      rescue => e
        create_graphics(chips_image_width, chips_image_height).tap do |g|
          g.begin_draw {g.background 0, 0, 0}
        end
      end
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
  end

  def save()
    File.write project_path, @settings.to_json
  end

end# Project

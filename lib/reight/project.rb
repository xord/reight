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

  def code_paths = ['game.rb']

  def codes()
    code_paths.map {File.read _1 rescue nil}
  end

  def chips_path = "#{project_dir}/chips.json"

  def chips()
    @chips ||= load_chips
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

  def maps_path = "#{project_dir}/maps.json"

  def maps()
    @maps ||= load_maps
  end

  def palette_colors = %w[
    #000000 #1D2B53 #7E2553 #008751 #AB5236 #5F574F #C2C3C7 #FFF1E8
    #FF004D #FFA300 #FFEC27 #00E436 #29ADFF #83769C #FF77A8 #FFCCAA
  ]

  def save()
    File.write project_path, @settings.to_json
    save_chips
    save_maps
  end

  private

  def load()
    @settings = JSON.parse File.read(project_path), symbolize_names: true
  end

  def save_chips()
    File.write chips_path, chips.to_hash.to_json
  end

  def load_chips()
    if File.file? chips_path
      json = JSON.parse File.read(chips_path), symbolize_names: true
      Reight::ChipList.restore json, chips_image
    else
      Reight::ChipList.new chips_image
    end
  end

  def save_maps()
    File.write maps_path, maps.map {_1.to_hash}.to_json
  end

  def load_maps()
    if File.file? maps_path
      json = JSON.parse File.read(maps_path), symbolize_names: true
      json.map {Reight::Map.restore _1, chips}
    else
      [Reight::Map.new]
    end
  end

end# Project

using Reight


class Reight::Project

  include Xot::Inspectable

  def initialize(project_dir)
    raise 'the project directory is required' unless project_dir
    @project_dir = project_dir
    @settings    = {}
    load
  end

  attr_reader :project_dir, :settings

  def project_path = "#{project_dir}/project.json"

  def code_paths   = settings[__method__]&.then {[_1].flatten} || ['game.rb']

  def codes()
    code_paths
      .map {File.expand_path _1, project_dir}
      .map {File.read _1 rescue nil}
  end

  def chips_json_name   = settings[__method__] || 'chips.json'

  def chips_json_path   = "#{project_dir}/#{chips_json_name}"

  def chips()
    @chips ||= load_chips
  end

  def chips_image_name   = settings[__method__] || 'chips.png'

  def chips_image_path   = "#{project_dir}/#{chips_image_name}"

  def chips_image_width  = settings[__method__] || 1024

  def chips_image_height = settings[__method__] || 1024

  def chips_image()
    @chips_image ||= -> {
      create_graphics(chips_image_width, chips_image_height).tap do |g|
        g.begin_draw {g.background 0, 0, 0, 0}
        img = load_image chips_image_path
        g.begin_draw {g.image img, 0, 0}
      rescue Rays::RaysError
      end
    }.call
  end

  def maps_json_name = settings[__method__] || 'maps.json'

  def maps_json_path = "#{project_dir}/#{maps_json_name}"

  def maps()
    @maps ||= load_maps
  end

  def sounds_json_name = settings[__method__] || 'sounds.json'

  def sounds_json_path = "#{project_dir}/#{sounds_json_name}"

  def sounds()
    @sounds ||= load_sounds
  end

  def font           = @font ||= create_font(nil, font_size)

  def font_size      = 8

  def palette_colors = Reight::App::PALETTE_COLORS.dup

  def clear_all_sprites()
    chips.each(&:clear_sprite)
    maps.each(&:clear_sprites)
  end

  def save()
    File.write project_path, to_json_string(@settings)
    save_chips
    save_maps
    save_sounds
  end

  private

  def load()
    @settings = JSON.parse File.read(project_path), symbolize_names: true
  rescue Errno::ENOENT
    @settings = {}
  end

  def save_chips()
    File.write chips_json_path, to_json_string(chips.to_hash)
  end

  def load_chips()
    if File.file? chips_json_path
      json = JSON.parse File.read(chips_json_path), symbolize_names: true
      Reight::ChipList.restore json, chips_image
    else
      Reight::ChipList.new chips_image
    end
  end

  def save_maps()
    File.write maps_json_path, to_json_string(maps.map {_1.to_hash})
  end

  def load_maps()
    if File.file? maps_json_path
      json = JSON.parse File.read(maps_json_path), symbolize_names: true
      json.map {Reight::Map.restore _1, chips}
    else
      [Reight::Map.new]
    end
  end

  def save_sounds()
    File.write sounds_json_path, to_json_string(sounds.map {_1.to_hash})
  end

  def load_sounds()
    if File.file? sounds_json_path
      json = JSON.parse File.read(sounds_json_path), symbolize_names: true
      json.map {Reight::Sound.restore _1}
    else
      [Reight::Sound.new]
    end
  end

  def to_json_string(obj, readable: true)
    if readable
      JSON.pretty_generate obj
    else
      JSON.generate obj
    end
  end

end# Project

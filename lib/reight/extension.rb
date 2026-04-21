module Reight


  # @private
  module Extension

    module_function

    def name(downcase = false)
      super().split('::')[-2].then {|s|
        downcase ? s.gsub(/([a-z])([A-Z])/) {"#{$1}-#{$2}"}.downcase : s
      }
    end

    def version()
      File.read(root_dir 'VERSION')[/[\d\.]+/]
    end

    def root_dir(path = '')
      File.expand_path "../../#{path}", __dir__
    end

  end# Extension


end# Reight

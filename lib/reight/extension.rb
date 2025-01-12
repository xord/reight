module Reight


  # @private
  module Extension

    module_function

    def name()
      super.split('::')[-2]
    end

    def version()
      File.read(root_dir 'VERSION')[/[\d\.]+/]
    end

    def root_dir(path = '')
      File.expand_path "../../#{path}", __dir__
    end

  end# Extension


end# Reight

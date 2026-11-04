require 'reflex/packager/rake'
require 'reight/packager/profile'


module Reight


  module Packager


    # The tasks of reflex-packager, by the profile of Reight.
    #
    module Rake

      def package_application()
        super PROFILE
      end

    end# Rake


  end# Packager


end# Reight


include Reight::Packager::Rake

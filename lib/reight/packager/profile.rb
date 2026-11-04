require 'reight/extension'
require 'reflex/packager/profile'


module Reight


  # @private
  module Packager


    # The profile to package a game of Reight with.
    #
    PROFILE = Reflex::Packager::Profile.new(
      extension:    Reight::Extension,
      config_files: %w[reight.yml reight.yaml r8.yml r8.yaml],
      templates:    File.expand_path('templates/new', __dir__),
      rake:         'reight/packager/rake',
      command:      'r8',
      executable:   File.expand_path('../../../bin/r8', __dir__),
      main:         'game.rb',
      run:          'r8 run .',
      boot:         <<~BOOT)
        require 'reight/cli'
        Reight::CLI.new.run %w[run .]
      BOOT


  end# Packager


end# Reight

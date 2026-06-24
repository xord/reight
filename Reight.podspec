# -*- mode: ruby -*-


Pod::Spec.new do |s|
  s.name         = "Reight"
  s.version      = File.read(File.expand_path 'VERSION', __dir__)[/[\d\.]+/]
  s.summary      = "A Retro Game Engine for Ruby"
  s.description  = "A Retro Game Engine for Ruby"
  s.license      = "MIT"
  s.source       = {:git => "https://github.com/xord/reight.git"}
  s.author       = {"xordog" => "xordog@gmail.com"}
  s.homepage     = "https://github.com/xord/reight"

  s.osx.deployment_target = "10.10"
  s.ios.deployment_target = "12.0"

  root = "${PODS_ROOT}/#{s.name}"
  exts = File.read(File.expand_path 'Rakefile', __dir__)
    .lines(chomp: true)
    .map {_1[%r|require\s*['"](\w+)/extension['"]|, 1]}
    .compact - [s.name.downcase]

  incdirs = exts.map {"#{root}/#{_1}/include"}.concat %W[
    #{root}/beeps/vendor/stk/include
    #{root}/beeps/vendor/AudioFile
    #{root}/beeps/vendor/r8brain-free-src
    #{root}/beeps/vendor/signalsmith-stretch
    #{root}/rays/vendor/glm
    #{root}/rays/vendor/clipper/cpp
    #{root}/rays/vendor/earcut.hpp/include/mapbox
    #{root}/rays/vendor/splines-lib
    #{root}/reflex/vendor/box2d/include
    #{root}/reflex/vendor/box2d/src
    #{root}/reflex/vendor/rtmidi/rtmidi
    ${PODS_ROOT}/CRuby/CRuby/include
  ]

  s.prepare_command    = 'rake -f pod.rake setup'
  s.preserve_paths     = exts
  s.requires_arc       = false
  s.osx.compiler_flags = "-DOSX"
  s.ios.compiler_flags = "-DIOS"
  s.library            = %w[c++]
  s.xcconfig           = {
    "CLANG_CXX_LANGUAGE_STANDARD"  => 'c++20',
    "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) B2_MAX_WORLDS=256',
    "HEADER_SEARCH_PATHS"          => incdirs.join(' ')
  }

  #s.dependency = 'CRuby', git: 'https://github.com/xord/cruby'

  s.resource_bundles =
    exts.each_with_object({'Reight' => %w[lib res VERSION]}) do |ext, hash|
      hash[ext.capitalize] = %W[#{ext}/lib #{ext}/VERSION]
    end

  s.subspec "Xot" do |spec|
    spec.source_files = "xot/src/*.cpp"
  end

  s.subspec "Rucy" do |spec|
    spec.source_files = "rucy/src/*.cpp"

    spec.subspec "Ext" do |ext|
      ext.source_files = "rucy/ext/rucy/*.cpp"
    end
  end

  s.subspec "Beeps" do |spec|
    spec    .source_files = "beeps/src/*.cpp"
    spec.osx.source_files = "beeps/src/osx/*.{cpp,mm}"
    spec.ios.source_files = "beeps/src/osx/*.{cpp,mm}"
    spec.frameworks       = %w[OpenAL AVFoundation]

    spec.subspec "STK" do |sub|
      sub.source_files  = "beeps/vendor/stk/src/*.cpp"
      sub.exclude_files = %w[Tcp Udp Socket Thread Mutex InetWv Rt].map {|s|
        "beeps/vendor/stk/src/#{s}*.cpp"
      }
    end

    spec.subspec "R8BrainFreeSrc" do |sub|
      sub.source_files  = "beeps/vendor/r8brain-free-src/*.cpp"
      sub.exclude_files = %w[example pffft_double/].map {|s|
        "beeps/vendor/r8brain-free-src/#{s}*.cpp"
      }
    end

    spec.subspec "Ext" do |ext|
      ext.source_files = "beeps/ext/beeps/*.cpp"
    end
  end

  s.subspec "Rays" do |spec|
    spec    .source_files = "rays/src/*.cpp", "rays/src/opengl/*.cpp"
    spec.osx.source_files = "rays/src/**/osx/*.{cpp,mm}"
    spec.ios.source_files = "rays/src/**/ios/*.{cpp,mm}"
    spec.osx.frameworks   = %w[AppKit OpenGL CoreImage CoreVideo CoreMedia AVFoundation]
    spec.ios.frameworks   = %w[GLKit MobileCoreServices AVFoundation]# ImageIO

    spec.subspec "Clipper" do |sub|
      sub.source_files = "rays/vendor/clipper/cpp/*.cpp"
    end

    spec.subspec "SplineLib" do |sub|
      sub.source_files = "rays/vendor/splines-lib/Splines.cpp"
    end

    spec.subspec "Ext" do |ext|
      ext.source_files = "rays/ext/rays/*.cpp"
    end
  end

  s.subspec "Reflex" do |spec|
    spec    .source_files = "reflex/src/*.cpp"
    spec.osx.source_files = "reflex/src/osx/*.{cpp,mm}"
    spec.ios.source_files = "reflex/src/ios/*.{cpp,mm}"
    spec.osx.frameworks   = %w[Cocoa IOKit GameController]
    spec.ios.frameworks   = %w[CoreMotion GameController]

    spec.subspec "Box2D" do |sub|
      sub.source_files = "reflex/vendor/box2d/src/**/*.c"
    end

    spec.subspec "RtMidi" do |sub|
      sub.source_files   = "reflex/vendor/rtmidi/rtmidi/**/*.cpp"
      sub.compiler_flags = '-D__MACOSX_CORE__'
      sub.osx.frameworks = %w[CoreAudio CoreMIDI]
      sub.ios.frameworks = %w[CoreMIDI]
    end

    spec.subspec "Ext" do |ext|
      ext.source_files = "reflex/ext/reflex/*.cpp"
    end
  end
end

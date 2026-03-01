Pod::Spec.new do |s|
  s.name             = 'flutter_litert_flex'
  s.version          = '1.0.0'
  s.summary          = 'FlexDelegate (SELECT_TF_OPS) addon for flutter_litert.'
  s.description      = <<-DESC
Adds the TensorFlow Lite Flex delegate native library to your macOS app,
enabling SELECT_TF_OPS support for on-device training models with gradient
ops like Conv2DBackpropFilter, Save, and Restore.
                       DESC
  s.homepage         = 'https://github.com/hugocornellier/flutter_litert'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hugo Cornellier' => 'hugo@hugocornellier.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # Download the FlexDelegate dylib if not present.
  # ~123 MB download, cached after first pod install.
  require 'fileutils'
  res_dir = File.join(__dir__, 'Resources')
  FileUtils.mkdir_p(res_dir) unless File.exist?(res_dir)

  lib_name = 'libtensorflowlite_flex-mac.dylib'
  lib_path = File.join(res_dir, lib_name)

  unless File.exist?(lib_path)
    puts '[flutter_litert_flex] Downloading FlexDelegate macOS dylib...'
    system("curl -sL 'https://github.com/hugocornellier/flutter_litert/releases/download/flex-v1.0.0/#{lib_name}' -o '#{lib_path}'")
    abort '[flutter_litert_flex] ERROR: Failed to download FlexDelegate macOS dylib. Check your internet connection.' unless $?.success?
    puts '[flutter_litert_flex] FlexDelegate macOS dylib installed.'
  end

  s.resources = [lib_path]
end

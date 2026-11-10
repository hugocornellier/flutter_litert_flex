Pod::Spec.new do |s|
  s.name             = 'flutter_litert_flex'
  s.version          = '2.1.0'
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

  s.platform = :osx, '10.15'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # Download the FlexDelegate dylib if not present.
  # ~132 MB download, checked against flex_sha256 and cached after the first
  # pod install. A cached copy with another hash is downloaded again.
  # The dylib (arm64) needs macOS 12.0 or newer at run time.
  require 'digest'
  require 'fileutils'
  res_dir = File.join(__dir__, 'Resources')
  FileUtils.mkdir_p(res_dir) unless File.exist?(res_dir)

  lib_name = 'libtensorflowlite_flex-mac.dylib'
  lib_path = File.join(res_dir, lib_name)
  flex_url = "https://github.com/hugocornellier/flutter_litert/releases/download/flex-v2.0.0/#{lib_name}"
  flex_sha256 = 'cbff725f8da03638e2c4d2b8dbb169cb7fd147e09f34309f9b3c4ad90e7df925'

  unless File.exist?(lib_path) && Digest::SHA256.file(lib_path).hexdigest == flex_sha256
    puts '[flutter_litert_flex] Downloading FlexDelegate macOS dylib...'
    tmp_path = "#{lib_path}.download"
    system("curl -fsSL --retry 3 '#{flex_url}' -o '#{tmp_path}'")
    abort '[flutter_litert_flex] ERROR: Failed to download FlexDelegate macOS dylib. Check your internet connection.' unless $?.success?
    actual_sha256 = Digest::SHA256.file(tmp_path).hexdigest
    unless actual_sha256 == flex_sha256
      File.delete(tmp_path)
      abort "[flutter_litert_flex] ERROR: FlexDelegate macOS dylib SHA-256 mismatch: expected #{flex_sha256}, got #{actual_sha256}."
    end
    File.rename(tmp_path, lib_path)
    puts '[flutter_litert_flex] FlexDelegate macOS dylib installed.'
  end

  s.resources = ["Resources/#{lib_name}"]
end

require 'fileutils'

Pod::Spec.new do |s|
  s.name             = 'flutter_litert_flex'
  s.version          = '0.0.1'
  s.summary          = 'FlexDelegate (SELECT_TF_OPS) addon for flutter_litert.'
  s.description      = <<-DESC
Adds the TensorFlow Lite Flex delegate native library to your iOS app,
enabling SELECT_TF_OPS support for on-device training models with gradient
ops like Conv2DBackpropFilter, Save, and Restore.
                       DESC
  s.homepage         = 'https://github.com/hugocornellier/flutter_litert'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hugo Cornellier' => 'hugo@hugocornellier.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'

  s.platform = :ios, '12.0'
  s.static_framework = true
  s.swift_version = '5.0'

  s.libraries = 'c++'
  s.weak_frameworks = 'CoreML'

  # ---------------------------------------------------------------------------
  # Download the FlexDelegate xcframework if not present.
  # ~492 MB download, cached after first pod install.
  # ---------------------------------------------------------------------------
  framework_dir = __dir__
  flex_xcfw = 'TensorFlowLiteFlex.xcframework'
  marker = File.join(framework_dir, flex_xcfw, 'ios-arm64',
                     'TensorFlowLiteFlex.framework', 'TensorFlowLiteFlex')

  unless File.exist?(marker)
    puts '[flutter_litert_flex] Downloading FlexDelegate iOS xcframework...'
    zip = File.join(framework_dir, '_flex_ios.zip')
    system("curl -sL 'https://github.com/hugocornellier/flutter_litert/releases/download/flex-v1.0.0/TensorFlowLiteFlex-ios.xcframework.zip' -o '#{zip}'")
    abort '[flutter_litert_flex] ERROR: Failed to download FlexDelegate iOS xcframework. Check your internet connection.' unless $?.success?
    system("unzip -qo '#{zip}' -d '#{framework_dir}'")
    File.delete(zip) if File.exist?(zip)

    # The release xcframework has a fat simulator binary (arm64+x86_64).
    # CocoaPods' ruby-macho can't parse fat archives, so we extract the
    # arm64 slice into a separate thin simulator directory.
    fat_sim = File.join(framework_dir, flex_xcfw, 'ios-arm64_x86_64-simulator',
                        'TensorFlowLiteFlex.framework')
    if File.exist?(fat_sim)
      thin_sim = File.join(framework_dir, flex_xcfw, 'ios-arm64-simulator',
                           'TensorFlowLiteFlex.framework')
      FileUtils.mkdir_p(File.join(thin_sim, 'Modules'))
      system("lipo -thin arm64 '#{File.join(fat_sim, 'TensorFlowLiteFlex')}' " \
             "-output '#{File.join(thin_sim, 'TensorFlowLiteFlex')}'")
      modulemap = File.join(fat_sim, 'Modules', 'module.modulemap')
      FileUtils.cp(modulemap, File.join(thin_sim, 'Modules')) if File.exist?(modulemap)
      FileUtils.rm_rf(File.join(framework_dir, flex_xcfw, 'ios-arm64_x86_64-simulator'))

      # Update Info.plist for thin slices
      File.write(File.join(framework_dir, flex_xcfw, 'Info.plist'), <<~PLIST)
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        	<key>AvailableLibraries</key>
        	<array>
        		<dict>
        			<key>LibraryIdentifier</key>
        			<string>ios-arm64</string>
        			<key>LibraryPath</key>
        			<string>TensorFlowLiteFlex.framework</string>
        			<key>SupportedArchitectures</key>
        			<array><string>arm64</string></array>
        			<key>SupportedPlatform</key>
        			<string>ios</string>
        		</dict>
        		<dict>
        			<key>LibraryIdentifier</key>
        			<string>ios-arm64-simulator</string>
        			<key>LibraryPath</key>
        			<string>TensorFlowLiteFlex.framework</string>
        			<key>SupportedArchitectures</key>
        			<array><string>arm64</string></array>
        			<key>SupportedPlatform</key>
        			<string>ios</string>
        			<key>SupportedPlatformVariant</key>
        			<string>simulator</string>
        		</dict>
        	</array>
        	<key>CFBundlePackageType</key>
        	<string>XFWK</string>
        	<key>XCFrameworkFormatVersion</key>
        	<string>1.0</string>
        </dict>
        </plist>
      PLIST
    end

    puts '[flutter_litert_flex] FlexDelegate iOS xcframework installed.'
  end

  # ---------------------------------------------------------------------------
  # Deduplicate Bazel-built .o archives.
  # Bazel creates hashed duplicates (e.g. metrics.o + metrics_<hash>.o).
  # With -all_load both copies are loaded, causing duplicate symbol errors.
  # Remove the hashed copies, keeping the plain-named versions.
  # ---------------------------------------------------------------------------
  dedup_marker = File.join(framework_dir, flex_xcfw, '.deduped')
  unless File.exist?(dedup_marker)
    ['ios-arm64', 'ios-arm64-simulator'].each do |arch|
      flex_binary = File.join(framework_dir, flex_xcfw, arch,
                              'TensorFlowLiteFlex.framework', 'TensorFlowLiteFlex')
      next unless File.exist?(flex_binary)

      members = `xcrun ar t '#{flex_binary}' 2>/dev/null`.lines.map(&:strip)

      plain_names = {}
      members.each do |m|
        if m.end_with?('.o') && m !~ /_[0-9a-f]{20,}\.o$/
          base = m.sub(/\.o$/, '')
          plain_names[base] = true
        end
      end

      to_remove = []
      members.each do |m|
        if m =~ /\A(.+)_[0-9a-f]{20,}\.o\z/
          base = $1
          to_remove << m if plain_names[base]
        end
      end

      if to_remove.any?
        puts "[flutter_litert_flex] Removing #{to_remove.size} duplicate .o files from #{arch} slice..."
        to_remove.each_slice(50) do |batch|
          system("xcrun ar d '#{flex_binary}' #{batch.join(' ')}")
        end
        system("xcrun ranlib '#{flex_binary}'")
      end
    end

    File.write(dedup_marker, 'done')
    puts '[flutter_litert_flex] Archive deduplication complete.'
  end

  s.vendored_frameworks = flex_xcfw

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
  }

  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }
end

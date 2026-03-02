require 'fileutils'

Pod::Spec.new do |s|
  s.name             = 'flutter_litert_flex'
  s.version          = '0.0.4'
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

  # Download the FlexDelegate xcframework if not present.
  # ~123 MB download, cached after first pod install.
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

  # The Bazel-built archive has two issues that prevent -force_load:
  # 1. Same-named .o members from different source dirs (causes duplicate symbols)
  # 2. .o files referencing external libs (WebP, ICU, protobuf compiler) not
  #    included in the framework
  #
  # Fix: extract all members with unique indexed names (preserving all content),
  # remove .o files that reference unavailable external symbols, then rebuild.
  dedup_marker = File.join(framework_dir, flex_xcfw, '.deduped')
  unless File.exist?(dedup_marker)
    ['ios-arm64', 'ios-arm64-simulator'].each do |arch|
      flex_binary = File.join(framework_dir, flex_xcfw, arch,
                              'TensorFlowLiteFlex.framework', 'TensorFlowLiteFlex')
      next unless File.exist?(flex_binary)

      tmp_dir = File.join(framework_dir, '_dedup_tmp')
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)

      # Use Python to extract all .o members with unique indexed names.
      # BSD ar uses #1/NN prefix for long names; we parse this to get real names.
      # Indexed extraction avoids same-name overwrites that lose content.
      system("python3 -c \"
import os, struct
archive = '#{flex_binary}'
outdir = '#{tmp_dir}'
with open(archive, 'rb') as f:
    f.read(8)  # magic
    idx = 0
    while True:
        hdr = f.read(60)
        if len(hdr) < 60: break
        raw = hdr[:16].decode('ascii', errors='replace').strip().rstrip('/')
        size = int(hdr[48:58].decode('ascii').strip())
        data = f.read(size)
        if size % 2: f.read(1)
        name = raw
        real_data = data
        if raw.startswith('#1/'):
            nl = int(raw[3:])
            name = data[:nl].decode('ascii', errors='replace').rstrip(chr(0))
            real_data = data[nl:]
        if name.endswith('.o'):
            out = os.path.join(outdir, f'{idx:05d}_{name}')
            open(out, 'wb').write(real_data)
            idx += 1
\"")

      extracted = Dir.glob(File.join(tmp_dir, '*.o'))
      original_count = extracted.size
      next unless extracted.any?

      # Step 1: Bazel produces hash-suffixed .o copies (e.g. env.o +
      # env_84ffcf39.o) from different source dirs that duplicate all strong
      # symbols. Loading both with -force_load causes duplicate symbol errors.
      # However, unrelated modules may share the same base name (e.g. two
      # different context.o). Fix: only delete a file if ALL its strong
      # symbols are already defined in another file with the same base name.
      #
      # Group by base name (strip index prefix and hash suffix)
      by_base = {}
      extracted.each do |f|
        raw = File.basename(f).sub(/\A(\d+_)+/, '')
        base = raw.sub(/_[a-f0-9]{32}\.o\z/, '.o')
        by_base[base] ||= []
        by_base[base] << f
      end

      # Helper to get strong defined symbols
      get_strong = ->(path) {
        `xcrun nm -gU '#{path}' 2>/dev/null`.lines.map { |l|
          parts = l.strip.split(/\s+/)
          parts.last if parts.size >= 3 && parts[-2] =~ /\A[TDBS]\z/
        }.compact
      }

      # Cache symbol sets per file
      sym_cache = {}
      by_base.each do |base, files|
        next if files.size < 2
        # Get strong symbols for each file in the group
        files.each { |f| sym_cache[f] ||= get_strong.call(f) }
        # For each file, check if ALL its strong symbols exist in another file
        files.each do |f|
          next unless File.exist?(f)
          my_syms = sym_cache[f]
          next if my_syms.empty?
          # Check against every OTHER file in the group
          is_dup = files.any? { |other|
            next false if other == f || !File.exist?(other)
            other_syms = Set.new(sym_cache[other])
            other_syms.size >= my_syms.size &&
              my_syms.all? { |s| other_syms.include?(s) }
          }
          if is_dup
            File.delete(f)
          end
        end
      end

      # Step 2: Remove .o files that reference symbols from external libraries
      # not bundled in the framework (WebP, ICU, protobuf compiler).
      external_patterns = %w[
        _WebP _VP8 _GetColorPalette
        _icu_69
        10tensorflow4webp
        N6google8protobuf8compiler
        N6google8protobuf13json_internal
      ]
      remaining_files = Dir.glob(File.join(tmp_dir, '*.o'))
      to_remove = []
      remaining_files.each do |f|
        undef_syms = `xcrun nm -u '#{f}' 2>/dev/null`
        if external_patterns.any? { |pat| undef_syms.include?(pat) }
          to_remove << f
        end
      end
      to_remove.each { |f| File.delete(f) }
      remaining = Dir.glob(File.join(tmp_dir, '*.o'))

      puts "[flutter_litert_flex] Rebuilding #{arch} archive: #{original_count} -> #{remaining.size} members..."

      FileUtils.rm_f(flex_binary)
      remaining.each_slice(200) do |batch|
        system("xcrun ar rcs '#{flex_binary}' #{batch.map { |f| "'#{f}'" }.join(' ')}")
      end

      FileUtils.rm_rf(tmp_dir)
    end

    File.write(dedup_marker, 'done')
    puts '[flutter_litert_flex] Archive rebuild complete.'
  end

  s.vendored_frameworks = flex_xcfw

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
  }

  # -force_load ensures ALL .o files from TensorFlowLiteFlex are loaded,
  # including C++ static initializers that register TF op kernels. Without
  # this, the linker only loads .o files referenced by other code, and TF op
  # registrations never run — causing NULL function pointer crashes at runtime.
  # We use SDK-conditional paths since the xcframework has per-platform slices.
  flex_src = '$(PODS_ROOT)/../.symlinks/plugins/flutter_litert_flex/ios/TensorFlowLiteFlex.xcframework'
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => "$(inherited) -ObjC -force_load \"#{flex_src}/ios-arm64/TensorFlowLiteFlex.framework/TensorFlowLiteFlex\"",
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => "$(inherited) -ObjC -force_load \"#{flex_src}/ios-arm64-simulator/TensorFlowLiteFlex.framework/TensorFlowLiteFlex\"",
  }
end

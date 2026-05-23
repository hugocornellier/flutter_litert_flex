#!/usr/bin/env bash
# Preprocesses TensorFlowLiteFlex.xcframework for SPM compatibility.
#
# What this does (mirroring the CocoaPods podspec logic):
#   1. Downloads the raw xcframework from GitHub Releases
#   2. Splits the fat simulator binary (arm64+x86_64) into a thin arm64 slice
#   3. Deduplicates .o members: removes files whose strong symbols are fully
#      covered by another file with the same base name (Bazel build artefact)
#   4. Removes .o members that reference external symbols unavailable in the
#      framework (WebP, ICU, protobuf compiler) — these cause linker errors
#   5. Rebuilds the static archive
#   6. Zips the result ready for a GitHub Release upload
#
# Output: TensorFlowLiteFlex-spm.xcframework.zip  (in the current directory)
# Usage:  bash scripts/preprocess_flex_xcframework.sh

set -euo pipefail

DOWNLOAD_URL="https://github.com/hugocornellier/flutter_litert/releases/download/flex-v1.0.0/TensorFlowLiteFlex-ios.xcframework.zip"
XCFW="TensorFlowLiteFlex.xcframework"
OUT_ZIP="TensorFlowLiteFlex-spm.xcframework.zip"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "[preprocess] Working in $WORK_DIR"

# 1. Download
echo "[preprocess] Downloading xcframework (~123 MB)..."
curl -sL "$DOWNLOAD_URL" -o "$WORK_DIR/raw.zip"

# 2. Unzip
echo "[preprocess] Extracting..."
unzip -qo "$WORK_DIR/raw.zip" -d "$WORK_DIR"

XCFW_DIR="$WORK_DIR/$XCFW"

# 3. Split fat simulator slice → thin arm64
FAT_SIM="$XCFW_DIR/ios-arm64_x86_64-simulator/TensorFlowLiteFlex.framework"
if [ -d "$FAT_SIM" ]; then
  echo "[preprocess] Thinning simulator slice..."
  THIN_SIM="$XCFW_DIR/ios-arm64-simulator/TensorFlowLiteFlex.framework"
  mkdir -p "$THIN_SIM/Modules"
  lipo -thin arm64 "$FAT_SIM/TensorFlowLiteFlex" -output "$THIN_SIM/TensorFlowLiteFlex"
  [ -f "$FAT_SIM/Modules/module.modulemap" ] && cp "$FAT_SIM/Modules/module.modulemap" "$THIN_SIM/Modules/"
  rm -rf "$XCFW_DIR/ios-arm64_x86_64-simulator"

  # Update Info.plist to reflect thin slices
  cat > "$XCFW_DIR/Info.plist" <<'PLIST'
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
fi

# 4 & 5. Dedup + remove external-symbol .o files, rebuild archive
for ARCH in ios-arm64 ios-arm64-simulator; do
  BINARY="$XCFW_DIR/$ARCH/TensorFlowLiteFlex.framework/TensorFlowLiteFlex"
  [ -f "$BINARY" ] || continue

  echo "[preprocess] Processing $ARCH archive..."
  TMP="$WORK_DIR/dedup_$ARCH"
  rm -rf "$TMP"; mkdir -p "$TMP"

  # Extract all .o members with unique indexed names (handles BSD ar long names)
  python3 - "$BINARY" "$TMP" <<'PYEOF'
import os, sys
archive, outdir = sys.argv[1], sys.argv[2]
with open(archive, 'rb') as f:
    f.read(8)  # magic
    idx = 0
    while True:
        hdr = f.read(60)
        if len(hdr) < 60: break
        raw  = hdr[:16].decode('ascii', errors='replace').strip().rstrip('/')
        size = int(hdr[48:58].decode('ascii').strip())
        data = f.read(size)
        if size % 2: f.read(1)
        name, real_data = raw, data
        if raw.startswith('#1/'):
            nl = int(raw[3:])
            name = data[:nl].decode('ascii', errors='replace').rstrip('\x00')
            real_data = data[nl:]
        if name.endswith('.o'):
            out = os.path.join(outdir, f'{idx:05d}_{name}')
            open(out, 'wb').write(real_data)
            idx += 1
PYEOF

  ALL_O=( "$TMP"/*.o )
  ORIGINAL=${#ALL_O[@]}

  # Dedup: for each group sharing a base name, remove files whose strong symbols
  # are fully covered by another file in the group.
  python3 - "$TMP" <<'PYEOF'
import os, subprocess, sys
from collections import defaultdict

tmp = sys.argv[1]
files = sorted(f for f in os.listdir(tmp) if f.endswith('.o'))

def base(name):
    raw = name.lstrip('0123456789').lstrip('_')
    import re
    return re.sub(r'_[a-f0-9]{32}\.o$', '.o', raw)

def strong_syms(path):
    out = subprocess.run(['xcrun', 'nm', '-gU', path],
                         capture_output=True, text=True).stdout
    syms = []
    for line in out.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3 and parts[-2] in ('T','D','B','S'):
            syms.append(parts[-1])
    return syms

by_base = defaultdict(list)
for f in files:
    by_base[base(f)].append(os.path.join(tmp, f))

sym_cache = {}
for grp in by_base.values():
    if len(grp) < 2:
        continue
    for p in grp:
        if p not in sym_cache:
            sym_cache[p] = set(strong_syms(p))
    for p in grp:
        if not os.path.exists(p):
            continue
        my = sym_cache[p]
        if not my:
            continue
        for other in grp:
            if other == p or not os.path.exists(other):
                continue
            if sym_cache[other] >= my and len(sym_cache[other]) >= len(my):
                os.remove(p)
                break
PYEOF

  # Remove .o files referencing external unavailable symbols
  EXTERNAL_PATTERNS=("_WebP" "_VP8" "_GetColorPalette" "_icu_69" "10tensorflow4webp" "N6google8protobuf8compiler" "N6google8protobuf13json_internal")
  for OBJ in "$TMP"/*.o; do
    [ -f "$OBJ" ] || continue
    UNDEFS=$(xcrun nm -u "$OBJ" 2>/dev/null || true)
    for PAT in "${EXTERNAL_PATTERNS[@]}"; do
      if echo "$UNDEFS" | grep -q "$PAT"; then
        rm -f "$OBJ"
        break
      fi
    done
  done

  # Remove .o files that DEFINE XNNPack delegate symbols.
  # TensorFlowLiteC already provides these symbols globally; keeping them in
  # TFLiteFlex would cause duplicate-symbol linker errors when both archives
  # are linked together. TFLiteFlex's internal references to XNNPack will
  # resolve to TFLiteC's definitions at link time.
  # Remove .o files that DEFINE XNNPack delegate symbols (T = global text symbol).
  # TensorFlowLiteC already provides these symbols globally; keeping them in
  # TFLiteFlex causes duplicate-symbol linker errors. TFLiteFlex's internal
  # XNNPack references resolve to TFLiteC's definitions at link time.
  for OBJ in "$TMP"/*.o; do
    [ -f "$OBJ" ] || continue
    if xcrun nm -gU "$OBJ" 2>/dev/null | grep -qE ' T _TfLiteXNNPackDelegate'; then
      rm -f "$OBJ"
    fi
  done

  REMAINING=( "$TMP"/*.o )
  echo "[preprocess]   $ARCH: $ORIGINAL → ${#REMAINING[@]} members"

  # Rebuild the archive
  rm -f "$BINARY"
  # Process in batches to avoid ARG_MAX
  BATCH=()
  for OBJ in "${REMAINING[@]}"; do
    BATCH+=("$OBJ")
    if [ ${#BATCH[@]} -ge 200 ]; then
      xcrun ar rcs "$BINARY" "${BATCH[@]}"
      BATCH=()
    fi
  done
  [ ${#BATCH[@]} -gt 0 ] && xcrun ar rcs "$BINARY" "${BATCH[@]}"
done

# 6. Zip
echo "[preprocess] Zipping..."
(cd "$WORK_DIR" && zip -qr - "$XCFW") > "$OUT_ZIP"
CHECKSUM=$(shasum -a 256 "$OUT_ZIP" | awk '{print $1}')

echo ""
echo "=========================================="
echo "Output:   $OUT_ZIP"
echo "SHA-256:  $CHECKSUM"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Upload $OUT_ZIP to a GitHub release (e.g. flex-v1.1.0)"
echo "  2. Update ios/Package.swift:"
echo "       url: \"<release-download-url>\""
echo "       checksum: \"$CHECKSUM\""

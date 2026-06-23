#!/usr/bin/env bash
#
# Regenerates the README assets in docs/screenshots/:
#   classic.png / glass.png / disabled.png  — static variant stills
#   demo.gif                                — a real slide-to-confirm gesture
#   confirmed.png                           — the confirmed state (GIF tail frame)
#
# Stills are staged by launching the Example app with -UI-SCREENSHOTS and a
# SNAPSHOT_SCENE env var (see SnapshotStaging.swift), then captured with
# `simctl io screenshot`. The animation needs a real gesture, so it is recorded
# while the SlideToXExampleUITests drag test runs.
#
# Usage:  Scripts/make-screenshots.sh ["iPhone 17 Pro"]
# Requires: Xcode, a booted-capable iOS 26 simulator, and ffmpeg on PATH.

set -euo pipefail

DEVICE_NAME="${1:-iPhone 17 Pro}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Example/SlideToXExample.xcodeproj"
APP_SCHEME="SlideToXExample"
UITEST_SCHEME="SlideToXExampleUITests"
BUNDLE_ID="com.example.SlideToXExample"
DD="$ROOT/build/screenshots-dd"
OUT="$ROOT/docs/screenshots"
mkdir -p "$OUT"

command -v ffmpeg >/dev/null || { echo "error: ffmpeg not on PATH"; exit 1; }

# --- Resolve a simulator UDID (prefer an iOS 26 runtime) ---------------------
UDID="$(python3 - "$DEVICE_NAME" <<'PY'
import json, sys, subprocess
name = sys.argv[1]
data = json.loads(subprocess.run(["xcrun","simctl","list","devices","available","--json"],
                                 capture_output=True, text=True).stdout)
best = None
for runtime, devices in data["devices"].items():
    for d in devices:
        if d["name"] != name:
            continue
        score = (1 if "iOS-26" in runtime else 0, d["udid"])
        if best is None or score > best[0]:
            best = (score, d["udid"])
print(best[1] if best else "")
PY
)"
[ -n "$UDID" ] || { echo "error: no available simulator named '$DEVICE_NAME'"; exit 1; }
echo "▸ Simulator: $DEVICE_NAME ($UDID)"

cleanup() { xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1 || true; }
trap cleanup EXIT

xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

# --- Build & install the app -------------------------------------------------
echo "▸ Building app…"
xcodebuild build \
  -project "$PROJECT" -scheme "$APP_SCHEME" \
  -configuration Debug -destination "id=$UDID" \
  -derivedDataPath "$DD" -quiet
APP="$DD/Build/Products/Debug-iphonesimulator/SlideToXExample.app"
xcrun simctl install "$UDID" "$APP"

# --- Clean status bar (09:41, full battery/signal, Wi-Fi) --------------------
xcrun simctl status_bar "$UDID" override \
  --time "09:41" --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --dataNetwork wifi --wifiBars 3

# --- Static variant stills ---------------------------------------------------
shoot() {
  local scene="$1"
  echo "▸ Still: $scene"
  SIMCTL_CHILD_SNAPSHOT_SCENE="$scene" \
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" -UI-SCREENSHOTS >/dev/null
  sleep 3
  xcrun simctl io "$UDID" screenshot "$OUT/$scene.png" >/dev/null 2>&1
}
shoot classic
shoot glass
shoot disabled
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

# --- Animated gesture: record while the drag test runs -----------------------
echo "▸ Recording slide gesture…"
MOV="$OUT/demo.mov"
XCRESULT="$DD/uitest.xcresult"
rm -rf "$MOV" "$XCRESULT"
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$MOV" &
REC_PID=$!
# Wall-clock when capture begins — anchors the GIF to the confirm timestamp.
REC_START="$(python3 -c 'import time; print(time.time())')"
sleep 1

xcodebuild test \
  -project "$PROJECT" -scheme "$UITEST_SCHEME" \
  -destination "id=$UDID" -derivedDataPath "$DD" \
  -resultBundlePath "$XCRESULT" -quiet

sleep 1
kill -INT "$REC_PID" 2>/dev/null || true
wait "$REC_PID" 2>/dev/null || true

# --- Pull the confirmed still out of the result bundle -----------------------
# The manifest also carries the wall-clock timestamp of the screenshot, which
# we use to locate the gesture inside the recording (the `xcodebuild test`
# build/launch overhead means the app only appears late in the video).
echo "▸ Extracting confirmed.png…"
ATTACH="$DD/attachments"
rm -rf "$ATTACH"
xcrun xcresulttool export attachments --path "$XCRESULT" --output-path "$ATTACH" >/dev/null
GIF_START="$(python3 - "$ATTACH" "$OUT/confirmed.png" "$REC_START" <<'PY'
import json, os, shutil, sys
attach, dest, rec_start = sys.argv[1], sys.argv[2], float(sys.argv[3])
manifest = json.load(open(os.path.join(attach, "manifest.json")))
src = ts = None
for test in manifest:
    for a in test.get("attachments", []):
        if a.get("suggestedHumanReadableName", "").startswith("confirmed"):
            src, ts = a["exportedFileName"], a.get("timestamp")
if not src:
    sys.exit("error: no 'confirmed' attachment in result bundle")
shutil.copyfile(os.path.join(attach, src), dest)
# Confirm happened at `ts`; the drag is the ~2.6s before it. Clamp at 0.
offset = max(0.0, (ts - rec_start) - 2.6) if ts else 0.0
print(f"{offset:.2f}")
PY
)"

# --- Convert the gesture window of the recording to a GIF --------------------
echo "▸ Encoding demo.gif (from ${GIF_START}s)…"
ffmpeg -y -loglevel error -ss "$GIF_START" -t 4.0 -i "$MOV" \
  -vf "fps=24,scale=360:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" \
  -loop 0 "$OUT/demo.gif"
rm -f "$MOV"

# --- Downscale the stills to a retina-friendly width -------------------------
# Full device res (~1206px) is overkill for a README shown at <200px, and the
# glass gradient balloons to multiple MB as a full-size PNG. 620px stays crisp
# at 3x while keeping every asset small.
for f in classic glass disabled confirmed; do
  sips --resampleWidth 620 "$OUT/$f.png" >/dev/null
done

echo "✓ Wrote: $(cd "$OUT" && ls -1 classic.png glass.png disabled.png confirmed.png demo.gif 2>/dev/null | tr '\n' ' ')"
echo "  → $OUT"

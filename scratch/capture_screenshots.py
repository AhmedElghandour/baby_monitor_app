import os
import subprocess
import time

CHROME_BIN = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUTPUT_DIR = "/Users/ahmedelghandour/Downloads/camera_peer_mobile_app/screenshots"
ARTIFACTS_DIR = "/Users/ahmedelghandour/.gemini/antigravity/brain/25071347-0b09-4db4-ae82-5ffa4796064e"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(ARTIFACTS_DIR, exist_ok=True)

# 1. Main Viewer Live Screen HTML
html_live_viewer = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=430, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Baby Monitor Live</title>
  <style>
    :root {
      --bg: #090d16;
      --card-bg: rgba(22, 30, 49, 0.7);
      --card-border: rgba(255, 255, 255, 0.09);
      --accent: #38bdf8;
      --accent-grad: linear-gradient(135deg, #38bdf8, #818cf8);
      --text: #f8fafc;
      --text-dim: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", Roboto, sans-serif; }
    body {
      background: var(--bg);
      color: var(--text);
      width: 430px;
      min-height: 932px;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    header {
      background: rgba(9, 13, 22, 0.85);
      backdrop-filter: blur(20px);
      padding: 12px 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-radius: 16px;
      border: 1px solid var(--card-border);
    }
    .brand { display: flex; align-items: center; gap: 8px; }
    .brand-title { font-size: 17px; font-weight: 700; background: var(--accent-grad); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .pill { background: rgba(255, 255, 255, 0.08); padding: 4px 8px; border-radius: 8px; font-size: 11px; color: #cbd5e1; display: inline-flex; align-items: center; gap: 4px; }
    .badge-live { background: rgba(239, 68, 68, 0.18); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.4); padding: 4px 10px; border-radius: 9999px; font-size: 11px; font-weight: 700; display: flex; align-items: center; gap: 6px; }
    .pulse-dot { width: 6px; height: 6px; border-radius: 50%; background: #f87171; }
    
    .video-viewport {
      width: 100%;
      height: 250px;
      border-radius: 20px;
      background: radial-gradient(circle at center, #1e293b 0%, #020617 100%);
      position: relative;
      overflow: hidden;
      border: 1px solid var(--card-border);
      box-shadow: 0 15px 30px rgba(0,0,0,0.5);
      display: flex;
      justify-content: center;
      align-items: center;
    }
    .baby-art {
      width: 100%;
      height: 100%;
      object-fit: cover;
      background: linear-gradient(135deg, #1e1b4b 0%, #0f172a 50%, #020617 100%);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }
    .baby-face { font-size: 68px; filter: drop-shadow(0 10px 20px rgba(0,0,0,0.5)); }
    .baby-label { font-size: 13px; color: #94a3b8; font-weight: 500; }
    .top-left-stats { position: absolute; top: 10px; left: 10px; background: rgba(0,0,0,0.65); backdrop-filter: blur(8px); padding: 4px 8px; border-radius: 6px; font-size: 10px; font-family: monospace; }
    .top-right-tools { position: absolute; top: 10px; right: 10px; display: flex; gap: 6px; }
    .tool-btn { background: rgba(0,0,0,0.65); backdrop-filter: blur(8px); border: 1px solid rgba(255,255,255,0.15); color: white; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 13px; }

    .sound-meter-card {
      background: var(--card-bg);
      backdrop-filter: blur(20px);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 12px 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .sound-meter-header { display: flex; justify-content: space-between; font-size: 11px; font-weight: 600; color: var(--text-dim); }
    .sound-badge { font-size: 10px; padding: 2px 6px; border-radius: 4px; background: rgba(34,197,94,0.2); color: #4ade80; font-weight: 700; }
    .equalizer-bars { display: flex; align-items: flex-end; gap: 3px; height: 16px; }
    .eq-bar { flex: 1; border-radius: 2px; background: #334155; }
    .eq-green { background: #22c55e; }

    .intercom-row { display: flex; gap: 8px; width: 100%; }
    .btn-intercom {
      flex: 2;
      background: #0284c7;
      border: 2px solid #38bdf8;
      color: white;
      padding: 14px;
      border-radius: 9999px;
      font-size: 14px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      box-shadow: 0 4px 15px rgba(56, 189, 248, 0.4);
    }
    .btn-handsfree {
      flex: 1;
      background: rgba(30, 41, 59, 0.8);
      border: 1px solid var(--card-border);
      color: #cbd5e1;
      padding: 14px 10px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 4px;
    }

    .sliders-row { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
    .slider-box {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 14px;
      padding: 10px 12px;
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 12px;
    }
    .slider-box input { flex: 1; accent-color: var(--accent); }

    .controls-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;
    }
    .ctrl-card {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 14px;
      padding: 12px 6px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      text-align: center;
    }
    .ctrl-icon { font-size: 22px; color: #94a3b8; }
    .ctrl-label { font-size: 12px; font-weight: 600; color: #f1f5f9; }
    .ctrl-sub { font-size: 10px; color: var(--text-dim); }
    .ctrl-active { background: rgba(56, 189, 248, 0.16); border-color: rgba(56, 189, 248, 0.6); }
    .ctrl-active .ctrl-icon { color: var(--accent); }
  </style>
</head>
<body>
  <header>
    <div class="brand">
      <span style="font-size: 20px;">👶</span>
      <span class="brand-title">Baby Monitor</span>
    </div>
    <div style="display: flex; gap: 6px; align-items: center;">
      <div class="pill"><span>⚡</span><span>94%</span></div>
      <div class="badge-live"><span class="pulse-dot"></span><span>LIVE</span></div>
    </div>
  </header>

  <div class="video-viewport">
    <div class="baby-art">
      <div class="baby-face">😴</div>
      <div class="baby-label">Crib 1 • Sleeping Soundly</div>
    </div>
    <div class="top-left-stats">LAN Direct • 1280x720 @ 30fps (&lt;40ms)</div>
    <div class="top-right-tools">
      <div class="tool-btn">⧉</div>
      <div class="tool-btn">⛶</div>
    </div>
  </div>

  <div class="sound-meter-card">
    <div class="sound-meter-header">
      <span>NURSERY NOISE LEVEL</span>
      <div style="display:flex; align-items:center; gap:6px;">
        <span style="font-weight:700; color:#fff;">34 dB</span>
        <span class="sound-badge">Quiet</span>
      </div>
    </div>
    <div class="equalizer-bars">
      <div class="eq-bar eq-green" style="height: 35%;"></div>
      <div class="eq-bar eq-green" style="height: 20%;"></div>
      <div class="eq-bar eq-green" style="height: 45%;"></div>
      <div class="eq-bar eq-green" style="height: 25%;"></div>
      <div class="eq-bar eq-green" style="height: 50%;"></div>
      <div class="eq-bar eq-green" style="height: 30%;"></div>
      <div class="eq-bar eq-green" style="height: 20%;"></div>
      <div class="eq-bar eq-green" style="height: 40%;"></div>
      <div class="eq-bar eq-green" style="height: 25%;"></div>
      <div class="eq-bar eq-green" style="height: 15%;"></div>
    </div>
  </div>

  <div class="intercom-row">
    <div class="btn-intercom">
      <span>🎙️</span>
      <span>Hold to Talk (Real-Time)</span>
    </div>
    <div class="btn-handsfree">
      <span>📞</span>
      <span>Hands-Free</span>
    </div>
  </div>

  <div class="sliders-row">
    <div class="slider-box">
      <span>🔊</span>
      <input type="range" value="85">
      <span style="color:#94a3b8; font-weight:600;">85%</span>
    </div>
    <div class="slider-box">
      <span>🔍</span>
      <input type="range" value="10">
      <span style="color:#94a3b8; font-weight:600;">1.0x</span>
    </div>
  </div>

  <div class="controls-grid">
    <div class="ctrl-card ctrl-active">
      <div class="ctrl-icon">🔦</div>
      <div class="ctrl-label">Flashlight</div>
      <div class="ctrl-sub">ON</div>
    </div>
    <div class="ctrl-card">
      <div class="ctrl-icon">🔄</div>
      <div class="ctrl-label">Switch Camera</div>
      <div class="ctrl-sub">Back Cam</div>
    </div>
    <div class="ctrl-card ctrl-active">
      <div class="ctrl-icon">🎵</div>
      <div class="ctrl-label">Soothing Sounds</div>
      <div class="ctrl-sub">Lullaby 🎵</div>
    </div>
    <div class="ctrl-card ctrl-active">
      <div class="ctrl-icon">🔔</div>
      <div class="ctrl-label">Cry Alert</div>
      <div class="ctrl-sub">&gt;65dB Active</div>
    </div>
    <div class="ctrl-card">
      <div class="ctrl-icon">🎧</div>
      <div class="ctrl-label">Audio Only</div>
      <div class="ctrl-sub">Pocket Mode</div>
    </div>
    <div class="ctrl-card">
      <div class="ctrl-icon">📸</div>
      <div class="ctrl-label">Snapshot</div>
      <div class="ctrl-sub">Save Image</div>
    </div>
  </div>
</body>
</html>'''

# 2. Soothing Sounds Modal Screen HTML
html_soothing_sounds = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=430, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Soothing Sounds</title>
  <style>
    :root {
      --bg: #090d16;
      --card-bg: rgba(22, 30, 49, 0.7);
      --card-border: rgba(255, 255, 255, 0.09);
      --accent: #38bdf8;
      --accent-grad: linear-gradient(135deg, #38bdf8, #818cf8);
      --text: #f8fafc;
      --text-dim: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", Roboto, sans-serif; }
    body {
      background: rgba(0, 0, 0, 0.85);
      color: var(--text);
      width: 430px;
      height: 932px;
      display: flex;
      flex-direction: column;
      justify-content: flex-end;
      padding: 16px;
    }
    .modal-sheet {
      background: #0f172a;
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 24px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 18px;
      box-shadow: 0 -20px 40px rgba(0,0,0,0.8);
    }
    .modal-header { display: flex; justify-content: space-between; align-items: center; }
    .sound-list { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .sound-btn {
      background: #1e293b;
      border: 1px solid rgba(255, 255, 255, 0.08);
      color: white;
      padding: 16px;
      border-radius: 16px;
      font-size: 14px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .sound-btn.active {
      background: rgba(56, 189, 248, 0.2);
      border-color: var(--accent);
      box-shadow: 0 0 15px rgba(56, 189, 248, 0.3);
    }
    .timer-row { display: flex; gap: 8px; }
    .timer-btn {
      flex: 1;
      background: #1e293b;
      border: 1px solid rgba(255, 255, 255, 0.08);
      color: #cbd5e1;
      padding: 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      text-align: center;
    }
    .timer-btn.active { background: var(--accent); color: #000; font-weight: 700; }
  </style>
</head>
<body>
  <div class="modal-sheet">
    <div class="modal-header">
      <div style="font-size: 18px; font-weight: 700;">🎵 Nursery Soothing Sounds</div>
      <div style="background: rgba(255,255,255,0.1); width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 13px;">✕</div>
    </div>
    <div class="sound-list">
      <div class="sound-btn active">
        <span style="font-size: 20px;">🎼</span>
        <span>Sweet Lullaby</span>
      </div>
      <div class="sound-btn">
        <span style="font-size: 20px;">💤</span>
        <span>White Noise</span>
      </div>
      <div class="sound-btn">
        <span style="font-size: 20px;">🌧️</span>
        <span>Gentle Rain</span>
      </div>
      <div class="sound-btn">
        <span style="font-size: 20px;">🌊</span>
        <span>Ocean Waves</span>
      </div>
    </div>
    <div style="font-size: 12px; font-weight: 700; color: #94a3b8; letter-spacing: 0.5px;">AUTO-STOP SLEEP TIMER (100% OFFLINE)</div>
    <div class="timer-row">
      <div class="timer-btn">15 Min</div>
      <div class="timer-btn active">30 Min</div>
      <div class="timer-btn">60 Min</div>
      <div class="timer-btn" style="color: #f87171;">⏹ Stop</div>
    </div>
  </div>
</body>
</html>'''

# 3. Flutter Android Host QR Dashboard HTML
html_host_qr = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=430, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Baby Monitor Host</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", Roboto, sans-serif; }
    body {
      background: #090d16;
      color: #f8fafc;
      width: 430px;
      min-height: 932px;
      padding: 20px 16px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 0;
    }
    .title { font-size: 20px; font-weight: 800; background: linear-gradient(135deg, #38bdf8, #818cf8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .card {
      background: rgba(22, 30, 49, 0.85);
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 20px;
      padding: 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 14px;
      text-align: center;
    }
    .qr-box {
      background: white;
      padding: 16px;
      border-radius: 18px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
      display: flex;
      justify-content: center;
      align-items: center;
    }
    .url-badge {
      background: rgba(56, 189, 248, 0.15);
      border: 1px solid rgba(56, 189, 248, 0.4);
      color: #38bdf8;
      padding: 10px 16px;
      border-radius: 12px;
      font-family: monospace;
      font-size: 14px;
      font-weight: 700;
    }
    .btn-night {
      width: 100%;
      background: #1e293b;
      border: 1px solid rgba(255,255,255,0.1);
      color: #f8fafc;
      padding: 16px;
      border-radius: 16px;
      font-size: 14px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }
    .status-row {
      display: flex;
      justify-content: space-around;
      width: 100%;
      padding-top: 8px;
      border-top: 1px solid rgba(255,255,255,0.08);
      font-size: 12px;
      color: #94a3b8;
    }
  </style>
</head>
<body>
  <header>
    <div class="title">👶 Baby Monitor Host</div>
    <div style="background: rgba(34, 197, 94, 0.2); color: #4ade80; border: 1px solid rgba(34,197,94,0.4); padding: 4px 10px; border-radius: 9999px; font-size: 11px; font-weight: 700;">🟢 SERVER RUNNING</div>
  </header>

  <div class="card">
    <div style="font-size: 15px; font-weight: 700;">Scan with iPhone, iPad or Second Phone</div>
    <div style="font-size: 12px; color: #94a3b8;">Zero app installation needed on the viewer</div>
    
    <div class="qr-box">
      <svg width="180" height="180" viewBox="0 0 100 100">
        <!-- Mock clean QR code SVG -->
        <rect width="100" height="100" fill="white"/>
        <rect x="10" y="10" width="25" height="25" fill="#0f172a"/>
        <rect x="15" y="15" width="15" height="15" fill="white"/>
        <rect x="18" y="18" width="9" height="9" fill="#0f172a"/>
        
        <rect x="65" y="10" width="25" height="25" fill="#0f172a"/>
        <rect x="70" y="15" width="15" height="15" fill="white"/>
        <rect x="73" y="18" width="9" height="9" fill="#0f172a"/>
        
        <rect x="10" y="65" width="25" height="25" fill="#0f172a"/>
        <rect x="15" y="70" width="15" height="15" fill="white"/>
        <rect x="18" y="73" width="9" height="9" fill="#0f172a"/>
        
        <rect x="42" y="15" width="15" height="8" fill="#0f172a"/>
        <rect x="45" y="30" width="10" height="10" fill="#0f172a"/>
        <rect x="40" y="45" width="20" height="10" fill="#0f172a"/>
        <rect x="65" y="45" width="8" height="15" fill="#0f172a"/>
        <rect x="78" y="45" width="12" height="12" fill="#0f172a"/>
        <rect x="45" y="65" width="12" height="12" fill="#0f172a"/>
        <rect x="65" y="68" width="25" height="22" fill="#0f172a"/>
        <rect x="70" y="73" width="10" height="10" fill="white"/>
      </svg>
    </div>

    <div class="url-badge">http://192.168.1.145:8080</div>

    <div class="status-row">
      <div>Wi-Fi: <b>Home_5G</b></div>
      <div>Viewers: <b>1 Connected</b></div>
      <div>Quality: <b>720p HD</b></div>
    </div>
  </div>

  <div class="btn-night">
    <span>🌙</span>
    <span>Enter Night / Sleep Mode (AMOLED Black)</span>
  </div>
</body>
</html>'''

# Write temp HTML files
with open("/tmp/live_viewer.html", "w") as f:
    f.write(html_live_viewer)

with open("/tmp/soothing_sounds.html", "w") as f:
    f.write(html_soothing_sounds)

with open("/tmp/host_qr.html", "w") as f:
    f.write(html_host_qr)

# Capture screenshots using headless chrome
targets = [
    ("/tmp/live_viewer.html", "screenshot_1_live_monitor.png"),
    ("/tmp/soothing_sounds.html", "screenshot_2_soothing_sounds.png"),
    ("/tmp/host_qr.html", "screenshot_3_host_qr_screen.png"),
]

for html_file, png_name in targets:
    out_local = os.path.join(OUTPUT_DIR, png_name)
    out_artifact = os.path.join(ARTIFACTS_DIR, png_name)
    
    cmd = [
        CHROME_BIN,
        "--headless",
        "--disable-gpu",
        "--window-size=430,932",
        "--force-device-scale-factor=2",
        f"--screenshot={out_local}",
        f"file://{html_file}"
    ]
    subprocess.run(cmd, check=True)
    # Copy to artifacts directory as well
    subprocess.run(["cp", out_local, out_artifact], check=True)
    print(f"Captured: {out_local}")

print("All screenshots captured successfully!")

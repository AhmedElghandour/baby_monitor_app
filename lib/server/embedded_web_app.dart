// Embedded Single Page Application for Zero-Install Browser Viewers with Low-Latency & Auto-Recovery

class EmbeddedWebApp {
  static String getHtml({
    required String hostName,
    required int port,
    required bool isPinRequired,
  }) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <meta name="theme-color" content="#090d16">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="Baby Monitor">
  <link rel="manifest" href="/manifest.json">
  <title>Baby Monitor Live</title>
  <style>
    :root {
      --bg: #090d16;
      --card-bg: rgba(22, 30, 49, 0.7);
      --card-border: rgba(255, 255, 255, 0.09);
      --accent: #38bdf8;
      --accent-grad: linear-gradient(135deg, #38bdf8, #818cf8);
      --danger: #ef4444;
      --success: #22c55e;
      --warning: #f59e0b;
      --text: #f8fafc;
      --text-dim: #94a3b8;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      -webkit-tap-highlight-color: transparent;
      user-select: none;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      overflow-x: hidden;
      padding-bottom: env(safe-area-inset-bottom, 20px);
    }

    /* Frosted Header */
    header {
      background: rgba(9, 13, 22, 0.85);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      padding: 12px 18px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--card-border);
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .brand-icon {
      font-size: 24px;
      animation: gentle-bounce 3s ease-in-out infinite;
    }
    @keyframes gentle-bounce {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-3px); }
    }
    .brand-title {
      font-size: 17px;
      font-weight: 700;
      letter-spacing: -0.3px;
      background: var(--accent-grad);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .header-status {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 5px 12px;
      border-radius: 9999px;
      font-weight: 600;
      font-size: 12px;
      letter-spacing: 0.2px;
    }
    .badge-live {
      background: rgba(239, 68, 68, 0.18);
      color: #f87171;
      border: 1px solid rgba(239, 68, 68, 0.4);
    }
    .badge-connecting {
      background: rgba(245, 158, 11, 0.18);
      color: #fde047;
      border: 1px solid rgba(245, 158, 11, 0.4);
    }
    .badge-disconnected {
      background: rgba(100, 116, 139, 0.18);
      color: #94a3b8;
      border: 1px solid rgba(100, 116, 139, 0.4);
    }
    .pulse-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background-color: currentColor;
      animation: pulse 1.5s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.3; transform: scale(0.7); }
    }
    .pill {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      background: rgba(255, 255, 255, 0.08);
      padding: 4px 8px;
      border-radius: 8px;
      font-size: 12px;
      color: #cbd5e1;
    }

    /* Main Content */
    main {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 14px;
      max-width: 960px;
      margin: 0 auto;
      width: 100%;
      gap: 16px;
    }

    /* Video Container & Zoom */
    .video-viewport {
      width: 100%;
      position: relative;
      background: #02040a;
      border-radius: 22px;
      overflow: hidden;
      aspect-ratio: 16 / 10;
      max-height: 65vh;
      display: flex;
      justify-content: center;
      align-items: center;
      box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.7);
      border: 1px solid var(--card-border);
      touch-action: none;
    }
    .video-wrapper {
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
      transition: transform 0.1s ease-out;
      transform-origin: center center;
    }
    video {
      width: 100%;
      height: 100%;
      object-fit: cover;
      background: #000;
    }
    .audio-only-placeholder {
      display: none;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 12px;
      width: 100%;
      height: 100%;
      background: linear-gradient(180deg, #0f172a, #020617);
      color: var(--text);
    }

    /* Video Overlays */
    .overlay-audio-prompt {
      position: absolute;
      inset: 0;
      background: rgba(9, 13, 22, 0.85);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      gap: 14px;
      cursor: pointer;
      z-index: 25;
    }
    .audio-prompt-btn {
      background: var(--accent-grad);
      color: white;
      border: none;
      padding: 14px 28px;
      border-radius: 9999px;
      font-size: 15px;
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 10px;
      box-shadow: 0 8px 20px rgba(56, 189, 248, 0.4);
      cursor: pointer;
      transform: scale(1);
      transition: transform 0.2s;
    }
    .audio-prompt-btn:active {
      transform: scale(0.96);
    }
    .top-left-stats {
      position: absolute;
      top: 12px;
      left: 12px;
      background: rgba(0, 0, 0, 0.65);
      backdrop-filter: blur(8px);
      padding: 5px 10px;
      border-radius: 8px;
      font-size: 11px;
      color: #cbd5e1;
      font-family: ui-monospace, monospace;
      border: 1px solid rgba(255, 255, 255, 0.1);
      pointer-events: none;
      z-index: 10;
    }
    .top-right-tools {
      position: absolute;
      top: 12px;
      right: 12px;
      display: flex;
      gap: 8px;
      z-index: 10;
    }
    .tool-btn {
      background: rgba(0, 0, 0, 0.65);
      backdrop-filter: blur(8px);
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: white;
      width: 36px;
      height: 36px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      font-size: 15px;
      transition: all 0.2s;
    }
    .tool-btn:active {
      transform: scale(0.9);
    }

    /* Sound Level Visualizer & Decibel Meter */
    .sound-meter-card {
      width: 100%;
      background: var(--card-bg);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid var(--card-border);
      border-radius: 18px;
      padding: 14px 18px;
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .sound-meter-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 13px;
      font-weight: 600;
      color: var(--text-dim);
    }
    .sound-level-value {
      font-weight: 700;
      color: var(--text);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .equalizer-bars {
      display: flex;
      align-items: flex-end;
      gap: 4px;
      height: 20px;
    }
    .eq-bar {
      flex: 1;
      background: #334155;
      border-radius: 3px;
      height: 20%;
      transition: height 0.08s ease, background 0.2s;
    }
    .eq-bar.active-green { background: #22c55e; }
    .eq-bar.active-yellow { background: #f59e0b; }
    .eq-bar.active-red { background: #ef4444; box-shadow: 0 0 10px #ef4444; }

    /* Push-to-Talk & Realtime Intercom */
    .intercom-box {
      width: 100%;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 10px;
      padding: 6px 0;
    }
    .intercom-actions-row {
      width: 100%;
      display: flex;
      gap: 10px;
      max-width: 480px;
    }
    .btn-intercom {
      flex: 2;
      background: rgba(30, 41, 59, 0.8);
      border: 2px solid rgba(56, 189, 248, 0.4);
      color: white;
      padding: 16px 20px;
      border-radius: 9999px;
      font-size: 15px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
      transition: all 0.2s ease;
      touch-action: none;
    }
    .btn-intercom.talking {
      background: #0284c7 !important;
      border-color: #38bdf8 !important;
      box-shadow: 0 0 25px rgba(56, 189, 248, 0.8);
      transform: scale(1.02);
      animation: talk-glow 0.8s infinite alternate;
    }
    .btn-handsfree {
      flex: 1;
      background: rgba(30, 41, 59, 0.8);
      border: 1px solid var(--card-border);
      color: #cbd5e1;
      padding: 16px 12px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn-handsfree.active {
      background: rgba(34, 197, 94, 0.2);
      border-color: var(--success);
      color: #4ade80;
    }
    @keyframes talk-glow {
      from { box-shadow: 0 0 15px rgba(56, 189, 248, 0.5); }
      to { box-shadow: 0 0 30px rgba(56, 189, 248, 0.9); }
    }

    /* Grid of Control Cards */
    .controls-grid {
      width: 100%;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
      gap: 12px;
    }
    .ctrl-card {
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 14px 10px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 6px;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .ctrl-card:active {
      transform: scale(0.95);
    }
    .ctrl-card.active {
      background: rgba(56, 189, 248, 0.16);
      border-color: rgba(56, 189, 248, 0.6);
    }
    .ctrl-card.active .ctrl-icon {
      color: var(--accent);
    }
    .ctrl-icon {
      font-size: 26px;
      color: #94a3b8;
    }
    .ctrl-label {
      font-size: 13px;
      font-weight: 600;
      color: #e2e8f0;
      text-align: center;
    }
    .ctrl-sub {
      font-size: 11px;
      color: var(--text-dim);
    }

    /* Volume & Zoom Sliders */
    .sliders-row {
      width: 100%;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 12px;
    }
    .slider-box {
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 12px 16px;
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .slider-box input[type="range"] {
      flex: 1;
      height: 6px;
      border-radius: 3px;
      background: #334155;
      outline: none;
      accent-color: var(--accent);
    }

    /* Modal Sheet for Lullabies & Sounds */
    .modal-backdrop {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      display: none;
      justify-content: center;
      align-items: flex-end;
      z-index: 100;
    }
    .modal-backdrop.open {
      display: flex;
    }
    .modal-sheet {
      background: #0f172a;
      border: 1px solid var(--card-border);
      border-radius: 24px 24px 0 0;
      width: 100%;
      max-width: 600px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 18px;
      animation: slide-up 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes slide-up {
      from { transform: translateY(100%); }
      to { transform: translateY(0); }
    }
    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .sound-list {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }
    .sound-btn {
      background: #1e293b;
      border: 1px solid rgba(255, 255, 255, 0.08);
      color: white;
      padding: 14px;
      border-radius: 14px;
      font-size: 14px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 10px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .sound-btn.active {
      background: rgba(56, 189, 248, 0.2);
      border-color: var(--accent);
    }
    .timer-row {
      display: flex;
      gap: 8px;
    }
    .timer-btn {
      flex: 1;
      background: #1e293b;
      border: 1px solid rgba(255, 255, 255, 0.08);
      color: #cbd5e1;
      padding: 10px;
      border-radius: 10px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
    }
    .timer-btn.active {
      background: var(--accent);
      color: #000;
    }

    /* Modal for HTTPS / Intercom Help */
    .https-modal-sheet {
      background: #0f172a;
      border: 1px solid var(--card-border);
      border-radius: 24px 24px 0 0;
      width: 100%;
      max-width: 600px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .btn-switch-https {
      background: var(--accent-grad);
      color: white;
      border: none;
      padding: 14px;
      border-radius: 14px;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }

    /* PIN Lock Screen */
    .pin-overlay {
      position: fixed;
      inset: 0;
      background: #090d16;
      display: ${isPinRequired ? 'flex' : 'none'};
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 24px;
      z-index: 200;
      padding: 24px;
    }
    .pin-title {
      font-size: 20px;
      font-weight: 700;
    }
    .pin-dots {
      display: flex;
      gap: 14px;
    }
    .pin-dot {
      width: 16px;
      height: 16px;
      border-radius: 50%;
      border: 2px solid #64748b;
      transition: all 0.2s;
    }
    .pin-dot.filled {
      background: var(--accent);
      border-color: var(--accent);
      box-shadow: 0 0 10px var(--accent);
    }
    .keypad {
      display: grid;
      grid-template-columns: repeat(3, 72px);
      gap: 16px;
    }
    .keypad-btn {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: #1e293b;
      border: 1px solid rgba(255, 255, 255, 0.1);
      color: white;
      font-size: 24px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: transform 0.1s, background 0.2s;
    }
    .keypad-btn:active {
      transform: scale(0.92);
      background: #334155;
    }

    /* Toast Notification */
    .toast {
      position: fixed;
      bottom: calc(24px + env(safe-area-inset-bottom, 0px));
      left: 50%;
      transform: translateX(-50%) translateY(100px);
      background: rgba(15, 23, 42, 0.95);
      border: 1px solid rgba(255, 255, 255, 0.18);
      color: #f8fafc;
      padding: 12px 24px;
      border-radius: 9999px;
      font-size: 14px;
      font-weight: 600;
      box-shadow: 0 10px 30px rgba(0,0,0,0.6);
      opacity: 0;
      transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      z-index: 300;
      pointer-events: none;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .toast.show {
      transform: translateX(-50%) translateY(0);
      opacity: 1;
    }
    footer {
      text-align: center;
      padding: 16px;
      font-size: 11px;
      color: #475569;
    }
  </style>
</head>
<body>

  <!-- PIN Lock Screen -->
  <div class="pin-overlay" id="pinOverlay">
    <div style="font-size: 44px;">🔒</div>
    <div class="pin-title">Enter 4-Digit Security PIN</div>
    <div class="pin-dots">
      <div class="pin-dot" id="dot0"></div>
      <div class="pin-dot" id="dot1"></div>
      <div class="pin-dot" id="dot2"></div>
      <div class="pin-dot" id="dot3"></div>
    </div>
    <div class="keypad">
      <button class="keypad-btn" onclick="pressKey('1')">1</button>
      <button class="keypad-btn" onclick="pressKey('2')">2</button>
      <button class="keypad-btn" onclick="pressKey('3')">3</button>
      <button class="keypad-btn" onclick="pressKey('4')">4</button>
      <button class="keypad-btn" onclick="pressKey('5')">5</button>
      <button class="keypad-btn" onclick="pressKey('6')">6</button>
      <button class="keypad-btn" onclick="pressKey('7')">7</button>
      <button class="keypad-btn" onclick="pressKey('8')">8</button>
      <button class="keypad-btn" onclick="pressKey('9')">9</button>
      <button class="keypad-btn" style="font-size: 14px;" onclick="clearPin()">Clear</button>
      <button class="keypad-btn" onclick="pressKey('0')">0</button>
      <button class="keypad-btn" style="font-size: 18px;" onclick="deleteKey()">⌫</button>
    </div>
  </div>

  <!-- Header -->
  <header>
    <div class="brand">
      <div class="brand-icon">👶</div>
      <div>
        <div class="brand-title">Baby Monitor</div>
      </div>
    </div>
    <div class="header-status">
      <div id="batteryIndicator" class="pill" style="display:none;">
        <span id="batteryIcon">🔋</span>
        <span id="batteryText">--%</span>
      </div>
      <div id="statusBadge" class="badge badge-connecting">
        <span class="pulse-dot"></span>
        <span id="statusText">Connecting...</span>
      </div>
    </div>
  </header>

  <!-- Main View -->
  <main>
    <!-- Video Player Container -->
    <div class="video-viewport" id="videoViewport">
      <div class="video-wrapper" id="videoWrapper">
        <video id="remoteVideo" autoplay playsinline muted></video>
        <div class="audio-only-placeholder" id="audioOnlyPlaceholder">
          <div style="font-size: 54px;">🎧</div>
          <div style="font-size: 16px; font-weight: 600;">Audio-Only Monitor Active</div>
          <div style="font-size: 12px; color: #94a3b8;">Video is hidden to conserve battery</div>
        </div>
      </div>

      <!-- Tap to Play Audio Overlay -->
      <div class="overlay-audio-prompt" id="audioPrompt" style="display: none;">
        <button class="audio-prompt-btn" id="enableAudioBtn">
          <span>🔊</span>
          <span>Tap to Enable Live Audio</span>
        </button>
        <span style="font-size: 12px; color: #94a3b8;">Browser requires a tap to play live nursery sound</span>
      </div>

      <!-- Top Overlays -->
      <div class="top-left-stats" id="videoStats">LAN Direct • Ultra-Low Latency</div>
      <div class="top-right-tools">
        <button class="tool-btn" id="pipBtn" title="Picture-in-Picture">⧉</button>
        <button class="tool-btn" id="fullscreenBtn" title="Fullscreen">⛶</button>
      </div>
    </div>

    <!-- Live Sound & Cry Visualizer -->
    <div class="sound-meter-card">
      <div class="sound-meter-header">
        <span>NURSERY NOISE LEVEL</span>
        <div class="sound-level-value">
          <span id="soundLevelText">-- dB</span>
          <span id="soundStatusBadge" style="font-size: 11px; padding: 2px 6px; border-radius: 4px; background: rgba(34,197,94,0.2); color: #4ade80;">Quiet</span>
        </div>
      </div>
      <div class="equalizer-bars" id="eqBars">
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
        <div class="eq-bar"></div>
      </div>
    </div>

    <!-- Push-to-Talk & Real-Time Intercom -->
    <div class="intercom-box">
      <div class="intercom-actions-row">
        <button class="btn-intercom" id="btnIntercom">
          <span id="intercomIcon">🎙️</span>
          <span id="intercomText">Hold to Talk (Real-Time)</span>
        </button>
        <button class="btn-handsfree" id="btnHandsfree" title="Toggle Live Hands-Free Two-Way">
          <span>📞</span>
          <span id="handsfreeText">Hands-Free</span>
        </button>
      </div>
      <span style="font-size: 11px; color: #64748b;">Instant sub-second live voice streaming via WebRTC</span>
    </div>

    <!-- Sliders for Volume & Digital Zoom -->
    <div class="sliders-row">
      <div class="slider-box">
        <span id="audioMuteIcon" style="font-size: 18px; cursor: pointer;">🔊</span>
        <input type="range" id="volumeSlider" min="0" max="1" step="0.05" value="1">
        <span id="volumePercent" style="font-size: 12px; font-weight: 600; color: #94a3b8; width: 36px;">100%</span>
      </div>
      <div class="slider-box">
        <span style="font-size: 16px;">🔍</span>
        <input type="range" id="zoomSlider" min="1" max="4" step="0.1" value="1">
        <span id="zoomLabel" style="font-size: 12px; font-weight: 600; color: #94a3b8; width: 36px;">1.0x</span>
      </div>
    </div>

    <!-- Main Control Buttons Grid -->
    <div class="controls-grid">
      <!-- Flashlight / Torch -->
      <div class="ctrl-card" id="btnTorch">
        <div class="ctrl-icon" id="torchIcon">🔦</div>
        <div class="ctrl-label">Flashlight</div>
        <div class="ctrl-sub" id="torchSub">Off</div>
      </div>

      <!-- Switch Camera -->
      <div class="ctrl-card" id="btnFlipCamera">
        <div class="ctrl-icon">🔄</div>
        <div class="ctrl-label">Switch Camera</div>
        <div class="ctrl-sub" id="camFacingSub">Back Cam</div>
      </div>

      <!-- Lullabies & Soothing Sounds -->
      <div class="ctrl-card" id="btnOpenLullaby">
        <div class="ctrl-icon">🎵</div>
        <div class="ctrl-label">Soothing Sounds</div>
        <div class="ctrl-sub" id="lullabySub">Lullaby / Rain</div>
      </div>

      <!-- Sound Alerts Toggle -->
      <div class="ctrl-card" id="btnAlerts">
        <div class="ctrl-icon">🔔</div>
        <div class="ctrl-label">Cry Alert</div>
        <div class="ctrl-sub" id="alertsSub">Active (>65dB)</div>
      </div>

      <!-- Audio-Only Mode -->
      <div class="ctrl-card" id="btnAudioOnly">
        <div class="ctrl-icon">🎧</div>
        <div class="ctrl-label">Audio Only</div>
        <div class="ctrl-sub" id="audioOnlySub">Pocket Mode</div>
      </div>

      <!-- Snapshot Photo -->
      <div class="ctrl-card" id="btnSnapshot">
        <div class="ctrl-icon">📸</div>
        <div class="ctrl-label">Snapshot</div>
        <div class="ctrl-sub">Save Image</div>
      </div>
    </div>
  </main>

  <!-- Lullaby & Soothing Sound Modal Sheet -->
  <div class="modal-backdrop" id="lullabyModal">
    <div class="modal-sheet">
      <div class="modal-header">
        <div style="font-size: 17px; font-weight: 700;">🎵 Nursery Soothing Sounds</div>
        <button class="tool-btn" id="btnCloseLullaby">✕</button>
      </div>
      <div class="sound-list">
        <button class="sound-btn" onclick="playLullaby('lullaby')">🎼 Sweet Lullaby</button>
        <button class="sound-btn" onclick="playLullaby('white_noise')">💤 White Noise</button>
        <button class="sound-btn" onclick="playLullaby('rain')">🌧️ Gentle Rain</button>
        <button class="sound-btn" onclick="playLullaby('ocean')">🌊 Ocean Waves</button>
      </div>
      <div style="font-size: 13px; font-weight: 600; color: #94a3b8;">AUTO-STOP SLEEP TIMER</div>
      <div class="timer-row">
        <button class="timer-btn" onclick="setLullabyTimer(15)">15 Min</button>
        <button class="timer-btn" onclick="setLullabyTimer(30)">30 Min</button>
        <button class="timer-btn" onclick="setLullabyTimer(60)">60 Min</button>
        <button class="timer-btn" onclick="playLullaby('stop')" style="color: #f87171;">⏹ Stop</button>
      </div>
    </div>
  </div>

  <!-- HTTPS Intercom Permission Helper Modal -->
  <div class="modal-backdrop" id="httpsModal">
    <div class="https-modal-sheet">
      <div class="modal-header">
        <div style="font-size: 17px; font-weight: 700;">🔒 Enable Two-Way Intercom</div>
        <button class="tool-btn" id="btnCloseHttps">✕</button>
      </div>
      <div style="font-size: 13px; color: #cbd5e1; line-height: 1.5;">
        Mobile browsers (Safari & Chrome) require <strong>HTTPS (Secure Mode)</strong> to access the microphone for real-time live intercom.
      </div>
      <button class="btn-switch-https" id="btnSwitchHttps">
        <span>🔒 Switch to Secure Mode (HTTPS)</span>
      </button>
      <div style="font-size: 11px; color: #64748b; line-height: 1.4;">
        Note: When opening HTTPS on your local network, tap "Advanced ➔ Proceed to site" to grant microphone access.
      </div>
    </div>
  </div>

  <!-- Toast Notification -->
  <div class="toast" id="toast"></div>

  <footer>
    Direct P2P LAN • 100% Private • Ultra-Low Latency WebRTC
  </footer>

  <script>
    const host = window.location.hostname;
    const port = window.location.port || '8080';
    const isHttps = window.location.protocol === 'https:';
    const wsUrl = (isHttps ? 'wss://' : 'ws://') + host + ':' + port + '/ws';

    const remoteVideo = document.getElementById('remoteVideo');
    const videoWrapper = document.getElementById('videoWrapper');
    const audioOnlyPlaceholder = document.getElementById('audioOnlyPlaceholder');
    const statusBadge = document.getElementById('statusBadge');
    const statusText = document.getElementById('statusText');
    const videoStats = document.getElementById('videoStats');
    const audioPrompt = document.getElementById('audioPrompt');
    const enableAudioBtn = document.getElementById('enableAudioBtn');
    const fullscreenBtn = document.getElementById('fullscreenBtn');
    const pipBtn = document.getElementById('pipBtn');
    const videoViewport = document.getElementById('videoViewport');
    const volumeSlider = document.getElementById('volumeSlider');
    const volumePercent = document.getElementById('volumePercent');
    const audioMuteIcon = document.getElementById('audioMuteIcon');
    const zoomSlider = document.getElementById('zoomSlider');
    const zoomLabel = document.getElementById('zoomLabel');
    const batteryIndicator = document.getElementById('batteryIndicator');
    const batteryText = document.getElementById('batteryText');
    const batteryIcon = document.getElementById('batteryIcon');
    const toast = document.getElementById('toast');

    // Controls
    const btnTorch = document.getElementById('btnTorch');
    const torchSub = document.getElementById('torchSub');
    const btnFlipCamera = document.getElementById('btnFlipCamera');
    const camFacingSub = document.getElementById('camFacingSub');
    const btnSnapshot = document.getElementById('btnSnapshot');
    const btnIntercom = document.getElementById('btnIntercom');
    const intercomText = document.getElementById('intercomText');
    const btnHandsfree = document.getElementById('btnHandsfree');
    const handsfreeText = document.getElementById('handsfreeText');
    const btnOpenLullaby = document.getElementById('btnOpenLullaby');
    const btnCloseLullaby = document.getElementById('btnCloseLullaby');
    const lullabyModal = document.getElementById('lullabyModal');
    const httpsModal = document.getElementById('httpsModal');
    const btnCloseHttps = document.getElementById('btnCloseHttps');
    const btnSwitchHttps = document.getElementById('btnSwitchHttps');
    const btnAlerts = document.getElementById('btnAlerts');
    const alertsSub = document.getElementById('alertsSub');
    const btnAudioOnly = document.getElementById('btnAudioOnly');
    const audioOnlySub = document.getElementById('audioOnlySub');

    // Sound Visualizer Elements
    const soundLevelText = document.getElementById('soundLevelText');
    const soundStatusBadge = document.getElementById('soundStatusBadge');
    const eqBars = document.getElementById('eqBars').children;

    // PIN Elements
    const pinOverlay = document.getElementById('pinOverlay');
    let enteredPin = '';
    const isPinRequired = $isPinRequired;

    let ws = null;
    let pc = null;
    let isTorchOn = false;
    let currentFacing = 'back';
    let statsInterval = null;
    let heartbeatInterval = null;
    let audioContext = null;
    let analyser = null;
    let isAudioOnly = false;
    let soundAlertsEnabled = true;
    let lastAlertTime = 0;
    
    // Live Real-Time WebRTC Two-Way Audio
    let localTalkStream = null;
    let localAudioSender = null;
    let isHandsfreeOn = false;
    let isTalkingLive = false;

    // Stream watchdog for frozen video detection
    let lastVideoTimestamp = 0;
    let freezeDetectionCount = 0;
    let watchdogInterval = null;

    function showToast(msg) {
      toast.textContent = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 2500);
    }

    function setStatus(state, text) {
      statusBadge.className = 'badge badge-' + state;
      statusText.textContent = text;
    }

    // PIN Logic
    function pressKey(num) {
      if (enteredPin.length < 4) {
        enteredPin += num;
        updatePinDots();
        if (enteredPin.length === 4) {
          sendPinValidation(enteredPin);
        }
      }
    }
    function deleteKey() {
      enteredPin = enteredPin.slice(0, -1);
      updatePinDots();
    }
    function clearPin() {
      enteredPin = '';
      updatePinDots();
    }
    function updatePinDots() {
      for (let i = 0; i < 4; i++) {
        document.getElementById('dot' + i).classList.toggle('filled', i < enteredPin.length);
      }
    }
    function sendPinValidation(pin) {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'verify_pin', pin: pin }));
      }
    }

    // Acquire Local Microphone for Real-Time Talk
    async function acquireMicrophone() {
      if (localTalkStream) return localTalkStream;
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        return null;
      }
      try {
        localTalkStream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true
          }
        });
        localTalkStream.getAudioTracks().forEach(t => t.enabled = false);
        return localTalkStream;
      } catch (e) {
        console.warn('Microphone access note:', e);
        return null;
      }
    }

    // Initialize WebRTC Peer Connection with Low-Latency Playout
    async function createPeerConnection() {
      const config = {
        iceServers: [{ urls: 'stun:stun.l.google.com:19302' }],
        sdpSemantics: 'unified-plan'
      };

      pc = new RTCPeerConnection(config);

      if (localTalkStream) {
        const audioTrack = localTalkStream.getAudioTracks()[0];
        if (audioTrack) {
          localAudioSender = pc.addTrack(audioTrack, localTalkStream);
        }
      } else {
        pc.addTransceiver('audio', { direction: 'sendrecv' });
      }

      pc.addTransceiver('video', { direction: 'recvonly' });

      pc.ontrack = (event) => {
        // Enforce 0 playout delay hint on receiver to eliminate browser jitter buffer delay
        if (event.receiver && 'playoutDelayHint' in event.receiver) {
          event.receiver.playoutDelayHint = 0;
        }
        if (event.receiver && 'jitterBufferTarget' in event.receiver) {
          event.receiver.jitterBufferTarget = 0;
        }

        if (event.streams && event.streams[0]) {
          remoteVideo.srcObject = event.streams[0];
          setupAudioAnalyser(event.streams[0]);
        }

        remoteVideo.play().then(() => {
          audioPrompt.style.display = 'none';
        }).catch(err => {
          audioPrompt.style.display = 'flex';
        });
      };

      pc.onicecandidate = (event) => {
        if (event.candidate && ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({
            type: 'candidate',
            candidate: {
              sdpMLineIndex: event.candidate.sdpMLineIndex,
              sdpMid: event.candidate.sdpMid,
              candidate: event.candidate.candidate
            }
          }));
        }
      };

      pc.onconnectionstatechange = () => {
        if (pc.connectionState === 'connected') {
          setStatus('live', 'LIVE');
          startStatsMonitor();
          startWatchdog();
        } else if (pc.connectionState === 'disconnected' || pc.connectionState === 'failed') {
          setStatus('disconnected', 'Reconnecting...');
          stopStatsMonitor();
          stopWatchdog();
          // Auto recover
          setTimeout(() => {
            if (ws && ws.readyState === WebSocket.OPEN) {
              initiateWebRTC();
            }
          }, 1500);
        }
      };
    }

    // Auto-Recovery Watchdog: Checks if video frames freeze and automatically recovers stream
    function startWatchdog() {
      stopWatchdog();
      watchdogInterval = setInterval(() => {
        if (!remoteVideo || !pc || pc.connectionState !== 'connected' || isAudioOnly) return;

        if (remoteVideo.readyState >= 2 && !remoteVideo.paused) {
          if (remoteVideo.currentTime === lastVideoTimestamp && remoteVideo.currentTime > 0) {
            freezeDetectionCount++;
            if (freezeDetectionCount >= 3) {
              console.warn('Watchdog detected frozen frame. Re-syncing stream...');
              freezeDetectionCount = 0;
              remoteVideo.play().catch(() => {});
              if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: 'client_ready' }));
              }
            }
          } else {
            lastVideoTimestamp = remoteVideo.currentTime;
            freezeDetectionCount = 0;
          }
        }
      }, 1000);
    }

    function stopWatchdog() {
      if (watchdogInterval) {
        clearInterval(watchdogInterval);
        watchdogInterval = null;
      }
    }

    // Setup Web Audio Analyser for Decibel Meter
    function setupAudioAnalyser(stream) {
      try {
        if (!audioContext) {
          audioContext = new (window.AudioContext || window.webkitAudioContext)();
        }
        if (audioContext.state === 'suspended') {
          audioContext.resume();
        }
        const source = audioContext.createMediaStreamSource(stream);
        analyser = audioContext.createAnalyser();
        analyser.fftSize = 64;
        source.connect(analyser);

        const dataArray = new Uint8Array(analyser.frequencyBinCount);

        function updateVisualizer() {
          if (!analyser) return;
          analyser.getByteFrequencyData(dataArray);

          let sum = 0;
          for (let i = 0; i < dataArray.length; i++) {
            sum += dataArray[i];
          }
          const avg = sum / dataArray.length;
          const db = Math.round(30 + (avg / 255) * 60);

          soundLevelText.textContent = `\${db} dB`;

          if (db < 45) {
            soundStatusBadge.textContent = 'Quiet';
            soundStatusBadge.style.background = 'rgba(34,197,94,0.2)';
            soundStatusBadge.style.color = '#4ade80';
          } else if (db < 65) {
            soundStatusBadge.textContent = 'Activity';
            soundStatusBadge.style.background = 'rgba(245,158,11,0.2)';
            soundStatusBadge.style.color = '#fde047';
          } else {
            soundStatusBadge.textContent = 'Crying / Loud!';
            soundStatusBadge.style.background = 'rgba(239,68,68,0.25)';
            soundStatusBadge.style.color = '#f87171';

            if (soundAlertsEnabled && (Date.now() - lastAlertTime > 10000)) {
              lastAlertTime = Date.now();
              if (navigator.vibrate) navigator.vibrate([300, 150, 300]);
              showToast('⚠️ Sound Alert: Baby noise detected!');
            }
          }

          for (let i = 0; i < eqBars.length; i++) {
            const val = dataArray[i % dataArray.length] / 255;
            const barHeight = Math.max(15, Math.round(val * 100));
            eqBars[i].style.height = barHeight + '%';
            eqBars[i].className = 'eq-bar ' + (db < 45 ? 'active-green' : (db < 65 ? 'active-yellow' : 'active-red'));
          }

          requestAnimationFrame(updateVisualizer);
        }

        updateVisualizer();
      } catch (e) {
        console.warn('Audio analyser notice:', e);
      }
    }

    function startStatsMonitor() {
      stopStatsMonitor();
      statsInterval = setInterval(async () => {
        if (!pc) return;
        try {
          const stats = await pc.getStats();
          stats.forEach(report => {
            if (report.type === 'inbound-rtp' && report.kind === 'video') {
              const fps = Math.round(report.framesPerSecond || 30);
              const resolution = (remoteVideo.videoWidth && remoteVideo.videoHeight)
                ? `\${remoteVideo.videoWidth}x\${remoteVideo.videoHeight}`
                : 'HD';
              videoStats.textContent = `LAN Direct • \${resolution} @ \${fps}fps (<50ms)`;
            }
          });
        } catch (e) {}
      }, 1000);
    }

    function stopStatsMonitor() {
      if (statsInterval) {
        clearInterval(statsInterval);
        statsInterval = null;
      }
    }

    // Connect to WebSocket Server with Heartbeat
    function connectWebSocket() {
      setStatus('connecting', 'Connecting...');
      ws = new WebSocket(wsUrl);

      ws.onopen = async () => {
        startHeartbeat();
        if (!isPinRequired) {
          await initiateWebRTC();
        }
      };

      ws.onmessage = async (event) => {
        try {
          const data = JSON.parse(event.data);

          if (data.type === 'pong') {
            return;
          }

          if (data.type === 'pin_result') {
            if (data.success) {
              pinOverlay.style.display = 'none';
              showToast('Unlocked!');
              await initiateWebRTC();
            } else {
              showToast('Incorrect PIN');
              clearPin();
            }
          } else if (data.type === 'offer') {
            await pc.setRemoteDescription(new RTCSessionDescription(data.offer));
            const answer = await pc.createAnswer();
            await pc.setLocalDescription(answer);
            ws.send(JSON.stringify({
              type: 'answer',
              answer: { sdp: answer.sdp, type: answer.type }
            }));
          } else if (data.type === 'candidate') {
            if (data.candidate && data.candidate.candidate) {
              await pc.addIceCandidate(new RTCIceCandidate(data.candidate));
            }
          } else if (data.type === 'state_update') {
            handleStateUpdate(data);
          }
        } catch (err) {
          console.error('Error handling WS message:', err);
        }
      };

      ws.onclose = () => {
        stopHeartbeat();
        stopWatchdog();
        setStatus('disconnected', 'Reconnecting...');
        stopStatsMonitor();
        if (pc) { pc.close(); pc = null; }
        setTimeout(connectWebSocket, 2000);
      };
    }

    function startHeartbeat() {
      stopHeartbeat();
      heartbeatInterval = setInterval(() => {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'ping' }));
        }
      }, 4000);
    }

    function stopHeartbeat() {
      if (heartbeatInterval) {
        clearInterval(heartbeatInterval);
        heartbeatInterval = null;
      }
    }

    async function initiateWebRTC() {
      if (isHttps) {
        await acquireMicrophone();
      }
      if (pc) {
        pc.close();
        pc = null;
      }
      await createPeerConnection();
      ws.send(JSON.stringify({ type: 'client_ready' }));
    }

    function handleStateUpdate(data) {
      if (data.battery !== undefined) {
        batteryIndicator.style.display = 'inline-flex';
        batteryText.textContent = `\${data.battery}%`;
        batteryIcon.textContent = data.charging ? '⚡' : (data.battery > 20 ? '🔋' : '🪫');
      }
      if (data.torch !== undefined) {
        isTorchOn = data.torch;
        btnTorch.classList.toggle('active', isTorchOn);
        torchSub.textContent = isTorchOn ? 'ON' : 'Off';
      }
      if (data.facing !== undefined) {
        currentFacing = data.facing;
        camFacingSub.textContent = (currentFacing === 'front') ? 'Front Cam' : 'Back Cam';
      }
      if (data.lullabyActive !== undefined) {
        btnOpenLullaby.classList.toggle('active', data.lullabyActive);
        lullabySub.textContent = data.lullabyActive ? 'Playing 🎵' : 'Lullaby / Rain';
      }
    }

    // REAL-TIME TWO-WAY INTERCOM (Sub-50ms Instant WebRTC Streaming)
    async function enableRealtimeMic() {
      if (!localTalkStream) {
        await acquireMicrophone();
      }

      if (!localTalkStream) {
        if (!isHttps) {
          httpsModal.classList.add('open');
        } else {
          showToast('Please allow microphone access in browser settings');
        }
        return false;
      }

      const audioTrack = localTalkStream.getAudioTracks()[0];
      if (audioTrack) {
        audioTrack.enabled = true;

        if (pc) {
          const senders = pc.getSenders();
          localAudioSender = senders.find(s => s.track && s.track.kind === 'audio');
          if (localAudioSender) {
            localAudioSender.replaceTrack(audioTrack);
          } else {
            pc.addTrack(audioTrack, localTalkStream);
          }
        }
        return true;
      }
      return false;
    }

    function disableRealtimeMic() {
      if (localTalkStream) {
        localTalkStream.getAudioTracks().forEach(t => t.enabled = false);
      }
    }

    // Push-to-Talk (Hold to Talk Real-Time)
    async function startHoldToTalk() {
      if (isHandsfreeOn) return;
      const success = await enableRealtimeMic();
      if (success) {
        isTalkingLive = true;
        btnIntercom.classList.add('talking');
        intercomText.textContent = 'LIVE SPEAKING...';
      }
    }

    function stopHoldToTalk() {
      if (isHandsfreeOn) return;
      if (isTalkingLive) {
        disableRealtimeMic();
        isTalkingLive = false;
        btnIntercom.classList.remove('talking');
        intercomText.textContent = 'Hold to Talk (Real-Time)';
      }
    }

    btnIntercom.addEventListener('mousedown', startHoldToTalk);
    btnIntercom.addEventListener('mouseup', stopHoldToTalk);
    btnIntercom.addEventListener('mouseleave', stopHoldToTalk);
    btnIntercom.addEventListener('touchstart', (e) => { e.preventDefault(); startHoldToTalk(); });
    btnIntercom.addEventListener('touchend', (e) => { e.preventDefault(); stopHoldToTalk(); });
    btnIntercom.addEventListener('touchcancel', (e) => { e.preventDefault(); stopHoldToTalk(); });

    // Hands-Free Realtime Two-Way Toggle
    btnHandsfree.addEventListener('click', async () => {
      if (!isHandsfreeOn) {
        const success = await enableRealtimeMic();
        if (success) {
          isHandsfreeOn = true;
          btnHandsfree.classList.add('active');
          handsfreeText.textContent = 'Live Active';
          btnIntercom.classList.add('talking');
          intercomText.textContent = 'Live Call Active';
          showToast('🎙️ Hands-Free Live Intercom ON');
        }
      } else {
        disableRealtimeMic();
        isHandsfreeOn = false;
        btnHandsfree.classList.remove('active');
        handsfreeText.textContent = 'Hands-Free';
        btnIntercom.classList.remove('talking');
        intercomText.textContent = 'Hold to Talk (Real-Time)';
        showToast('Hands-Free Intercom OFF');
      }
    });

    // Switch to HTTPS Modal Handler
    btnSwitchHttps.addEventListener('click', () => {
      window.location.href = 'https://' + host + ':8443';
    });
    btnCloseHttps.addEventListener('click', () => httpsModal.classList.remove('open'));
    httpsModal.addEventListener('click', (e) => {
      if (e.target === httpsModal) httpsModal.classList.remove('open');
    });

    // Digital Zoom
    zoomSlider.addEventListener('input', (e) => {
      const zoom = parseFloat(e.target.value);
      videoWrapper.style.transform = `scale(\${zoom})`;
      zoomLabel.textContent = zoom.toFixed(1) + 'x';
    });

    // Audio Unmute Prompt
    enableAudioBtn.addEventListener('click', () => {
      remoteVideo.muted = false;
      remoteVideo.volume = parseFloat(volumeSlider.value);
      if (audioContext && audioContext.state === 'suspended') {
        audioContext.resume();
      }
      remoteVideo.play().then(() => {
        audioPrompt.style.display = 'none';
        showToast('Live nursery audio enabled');
      });
    });

    // Volume Slider & Mute
    volumeSlider.addEventListener('input', (e) => {
      const val = parseFloat(e.target.value);
      remoteVideo.volume = val;
      remoteVideo.muted = (val === 0);
      volumePercent.textContent = Math.round(val * 100) + '%';
      audioMuteIcon.textContent = (val === 0) ? '🔇' : (val < 0.5 ? '🔉' : '🔊');
    });

    // Flashlight Toggle
    btnTorch.addEventListener('click', () => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'command', action: 'toggle_torch' }));
        showToast('Toggling flashlight...');
      }
    });

    // Flip Camera
    btnFlipCamera.addEventListener('click', () => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'command', action: 'switch_camera' }));
        showToast('Switching camera...');
      }
    });

    // Sound Alerts Toggle
    btnAlerts.addEventListener('click', () => {
      soundAlertsEnabled = !soundAlertsEnabled;
      btnAlerts.classList.toggle('active', soundAlertsEnabled);
      alertsSub.textContent = soundAlertsEnabled ? 'Active (>65dB)' : 'Muted';
      showToast(soundAlertsEnabled ? 'Cry alerts enabled' : 'Cry alerts muted');
    });

    // Audio Only / Pocket Mode Toggle
    btnAudioOnly.addEventListener('click', () => {
      isAudioOnly = !isAudioOnly;
      btnAudioOnly.classList.toggle('active', isAudioOnly);
      audioOnlySub.textContent = isAudioOnly ? 'Audio Active' : 'Pocket Mode';
      remoteVideo.style.display = isAudioOnly ? 'none' : 'block';
      audioOnlyPlaceholder.style.display = isAudioOnly ? 'flex' : 'none';
      showToast(isAudioOnly ? 'Audio-only mode (saves battery)' : 'Video restored');
    });

    // Snapshot
    btnSnapshot.addEventListener('click', () => {
      if (!remoteVideo.videoWidth || !remoteVideo.videoHeight) {
        showToast('Video feed not ready');
        return;
      }
      const canvas = document.createElement('canvas');
      canvas.width = remoteVideo.videoWidth;
      canvas.height = remoteVideo.videoHeight;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(remoteVideo, 0, 0, canvas.width, canvas.height);
      const link = document.createElement('a');
      link.download = `baby_monitor_\${new Date().toISOString().replace(/[:.]/g, '-')}.jpg`;
      link.href = canvas.toDataURL('image/jpeg', 0.95);
      link.click();
      showToast('📸 Snapshot saved!');
    });

    // Picture-in-Picture (PiP)
    pipBtn.addEventListener('click', async () => {
      try {
        if (document.pictureInPictureElement) {
          await document.exitPictureInPicture();
        } else if (remoteVideo.requestPictureInPicture) {
          await remoteVideo.requestPictureInPicture();
        } else if (remoteVideo.webkitSetPresentationMode) {
          remoteVideo.webkitSetPresentationMode('picture-in-picture');
        }
      } catch (err) {
        showToast('PiP not supported on this browser');
      }
    });

    // Fullscreen
    fullscreenBtn.addEventListener('click', () => {
      if (!document.fullscreenElement) {
        if (videoViewport.requestFullscreen) videoViewport.requestFullscreen();
        else if (remoteVideo.webkitEnterFullscreen) remoteVideo.webkitEnterFullscreen();
      } else {
        if (document.exitFullscreen) document.exitFullscreen();
      }
    });

    // Lullaby Modal Handlers
    btnOpenLullaby.addEventListener('click', () => lullabyModal.classList.add('open'));
    btnCloseLullaby.addEventListener('click', () => lullabyModal.classList.remove('open'));
    lullabyModal.addEventListener('click', (e) => {
      if (e.target === lullabyModal) lullabyModal.classList.remove('open');
    });

    function playLullaby(soundType) {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'command', action: 'play_sound', sound: soundType }));
        showToast('Playing ' + soundType + ' on monitor');
      }
    }

    function setLullabyTimer(minutes) {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'command', action: 'sound_timer', minutes: minutes }));
        showToast(`Timer set for \${minutes} minutes`);
      }
    }

    // Start WebSocket
    connectWebSocket();
  </script>
</body>
</html>
''';
  }

  static String getManifestJson() {
    return '''{
  "name": "Baby Monitor Live",
  "short_name": "BabyMonitor",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#090d16",
  "theme_color": "#090d16",
  "orientation": "any",
  "icons": [
    {
      "src": "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>👶</text></svg>",
      "sizes": "192x192 512x512",
      "type": "image/svg+xml"
    }
  ]
}''';
  }
}

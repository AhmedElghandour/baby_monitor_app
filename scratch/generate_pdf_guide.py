import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT

def create_pdf(output_path):
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()

    # Custom styles
    primary_color = colors.HexColor("#0284c7")
    secondary_color = colors.HexColor("#0f172a")
    accent_color = colors.HexColor("#38bdf8")
    dark_text = colors.HexColor("#1e293b")
    light_bg = colors.HexColor("#f8fafc")
    card_border = colors.HexColor("#e2e8f0")

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=primary_color,
        alignment=TA_CENTER,
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'DocSubTitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#64748b"),
        alignment=TA_CENTER,
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=secondary_color,
        spaceBefore=12,
        spaceAfter=6,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=14,
        textColor=primary_color,
        spaceBefore=6,
        spaceAfter=3,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=dark_text,
        spaceAfter=5
    )

    bullet_style = ParagraphStyle(
        'BulletDark',
        parent=body_style,
        leftIndent=14,
        firstLineIndent=-10,
        spaceAfter=3
    )

    tip_style = ParagraphStyle(
        'TipText',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=9,
        leading=12.5,
        textColor=colors.HexColor("#0369a1")
    )

    story = []

    # Title & Header
    story.append(Paragraph("👶 Baby & Kid Monitor", title_style))
    story.append(Paragraph("Complete Setup & User Guide • Standalone Android Host + Zero-Install Web Viewer", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=primary_color, spaceBefore=0, spaceAfter=12))

    # Highlights box
    highlights_data = [[
        Paragraph(
            "<b>Key Highlights:</b> 100% Private Local Wi-Fi • No Cloud or Subscription • "
            "Zero Installation on Viewer (iPhone, iPad, Android, PC) • Two-Way Live Audio • "
            "Offline Lullabies & White Noise • Cry Decibel Alerts • Night / Sleep Mode",
            tip_style
        )
    ]]
    highlights_table = Table(highlights_data, colWidths=[540])
    highlights_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#f0f9ff")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#bae6fd")),
        ('PADDING', (0, 0), (-1, -1), 8),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    story.append(highlights_table)
    story.append(Spacer(1, 10))

    # Section 1: Installation on Android
    story.append(Paragraph("1. Installing the App on your Android Phone", h1_style))
    story.append(Paragraph("The Android phone serves as the camera and microphone host:", body_style))
    story.append(Paragraph("• <b>Transfer APK:</b> Send <code>app-release.apk</code> to your Android device (via WhatsApp, Google Drive, AirDrop-alternative, or USB).", bullet_style))
    story.append(Paragraph("• <b>Install:</b> Tap the APK file. If prompted with <i>'Install unknown apps'</i>, tap Settings and toggle <b>Allow from this source</b>.", bullet_style))
    story.append(Paragraph("• <b>Permissions:</b> Open <b>Baby Monitor</b> and tap <b>Allow</b> for Camera and Microphone permissions.", bullet_style))
    story.append(Paragraph("• <b>Server Ready:</b> The app will automatically launch its embedded local web server and display a large QR Code and your local stream URL (e.g., <code>http://192.168.1.50:8080</code>).", bullet_style))
    story.append(Spacer(1, 8))

    # Section 2: Connecting the Viewer
    story.append(Paragraph("2. Viewing from iPhone, iPad, Android, or Computer (Zero Install!)", h1_style))
    story.append(Paragraph("No app needs to be installed on any device you use to watch your baby:", body_style))
    story.append(Paragraph("• <b>Same Wi-Fi:</b> Ensure both devices are connected to the same home Wi-Fi network.", bullet_style))
    story.append(Paragraph("• <b>Scan QR Code:</b> Open the Camera app on your iPhone or secondary phone and point it at the QR Code on the Android screen.", bullet_style))
    story.append(Paragraph("• <b>Or Type URL:</b> You can also open Safari, Chrome, or Edge on any laptop/phone and type the URL shown on screen (e.g. <code>http://192.168.1.50:8080</code>).", bullet_style))
    story.append(Paragraph("• <b>Add to Home Screen (PWA):</b> On iOS Safari (tap Share ➔ Add to Home Screen) or Android Chrome (tap 3 dots ➔ Install App) to run in full-screen native app mode without browser bars.", bullet_style))
    story.append(Spacer(1, 8))

    # Section 3: Live Nursery Features & Controls
    story.append(Paragraph("3. Remote Nursery Controls (From Web Viewer)", h1_style))
    
    features_data = [
        [Paragraph("<b>Feature</b>", h2_style), Paragraph("<b>How to Use & What it Does</b>", h2_style)],
        [
            Paragraph("🎙️ <b>Real-Time Intercom</b>", body_style),
            Paragraph("Hold <b>'Hold to Talk'</b> to speak to your baby through the phone speaker with sub-50ms latency. Or tap <b>'📞 Hands-Free'</b> for continuous two-way call.", body_style)
        ],
        [
            Paragraph("📊 <b>Cry & Noise Alerts</b>", body_style),
            Paragraph("Real-time 10-bar decibel meter shows room noise level (Quiet, Activity, Crying). Plays alert chime and vibrates if noise exceeds threshold (>65dB).", body_style)
        ],
        [
            Paragraph("🎵 <b>Soothing Sounds</b>", body_style),
            Paragraph("Tap 'Soothing Sounds' to play <b>Sweet Lullaby</b>, <b>White Noise</b>, <b>Gentle Rain</b>, or <b>Ocean Waves</b> on the phone. Includes 15/30/60 min sleep timers (100% offline).", body_style)
        ],
        [
            Paragraph("🔦 <b>Remote Flashlight</b>", body_style),
            Paragraph("Tap 'Flashlight' to turn on the Android phone's rear torch remotely to check on the baby in the dark without walking into the room.", body_style)
        ],
        [
            Paragraph("🔄 <b>Switch Camera</b>", body_style),
            Paragraph("Switch between Front and Back cameras remotely from the browser with 1 tap.", body_style)
        ],
        [
            Paragraph("🔍 <b>Digital Zoom</b>", body_style),
            Paragraph("Use the zoom slider (1.0x to 4.0x) or pinch on touchscreen to zoom closely into the crib.", body_style)
        ],
        [
            Paragraph("⧉ <b>Picture-in-Picture</b>", body_style),
            Paragraph("Tap the <b>⧉</b> icon to pop the live stream into a floating mini-window while using WhatsApp, browsing, or working on other apps.", body_style)
        ],
        [
            Paragraph("📸 <b>Snapshot Photo</b>", body_style),
            Paragraph("Tap 'Snapshot' to capture and download high-resolution photos of cute moments.", body_style)
        ],
        [
            Paragraph("🔋 <b>Battery Indicator</b>", body_style),
            Paragraph("Live percentage & charging status of the camera phone displayed in the header.", body_style)
        ],
    ]

    features_table = Table(features_data, colWidths=[140, 400])
    features_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#e2e8f0")),
        ('TEXTCOLOR', (0, 0), (-1, 0), secondary_color),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#cbd5e1")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#94a3b8")),
        ('PADDING', (0, 0), (-1, -1), 4.5),
    ]))
    story.append(features_table)
    story.append(Spacer(1, 10))

    # Section 4: Night Mode & Travel Mode
    story.append(Paragraph("4. Baby Night Mode & Travel / Hotel Setup", h1_style))
    story.append(Paragraph("• <b>🌙 AMOLED Black Screen Mode:</b> Tap <i>'Enter Night / Sleep Mode'</i> on the Android host. The screen turns pitch black with a dim clock so it does not illuminate the dark nursery or disturb the baby. Tap anywhere on screen to wake.", bullet_style))
    story.append(Paragraph("• <b>✈️ Travel / Hotel Hotspot Mode:</b> In hotels or vacation rentals without open Wi-Fi, turn on <b>'Personal Hotspot'</b> on the Android phone. Connect your viewer phone to this hotspot and scan the QR code — it will stream with <b>zero internet or router required</b>.", bullet_style))
    story.append(Paragraph("• <b>🔒 4-Digit Security PIN:</b> In the host app, tap <i>'Set PIN'</i> to require a 4-digit code (e.g. <code>1234</code>) before anyone can view the camera feed.", bullet_style))
    story.append(Spacer(1, 8))

    # Section 5: Troubleshooting & Tips
    story.append(Paragraph("5. Tips & Troubleshooting", h1_style))
    story.append(Paragraph("• <b>Microphone Access for Intercom:</b> Mobile browsers require HTTPS for microphone permissions. Open <code>https://&lt;ip&gt;:8443</code> and tap <i>'Advanced ➔ Proceed to site'</i> to accept the local LAN certificate.", bullet_style))
    story.append(Paragraph("• <b>Battery & Heat:</b> We recommend keeping the camera phone plugged into a charger and enabling Night Mode to keep the device cool and save battery.", bullet_style))
    story.append(Paragraph("• <b>Zero Latency:</b> Ensure both devices are on a 5GHz Wi-Fi network for sub-50ms instant response.", bullet_style))

    story.append(Spacer(1, 12))
    story.append(HRFlowable(width="100%", thickness=0.8, color=colors.HexColor("#cbd5e1"), spaceBefore=0, spaceAfter=6))
    story.append(Paragraph("100% Private Peer-to-Peer Baby Monitor", subtitle_style))

    doc.build(story)
    print(f"PDF successfully created at: {output_path}")

if __name__ == "__main__":
    pdf_path = "/Users/ahmedelghandour/Downloads/camera_peer_mobile_app/Baby_Monitor_User_Guide.pdf"
    create_pdf(pdf_path)

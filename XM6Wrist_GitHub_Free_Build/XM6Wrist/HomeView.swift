import SwiftUI
import WatchKit

// XM6 Wrist is an independent watchOS app. The Sony-specific controls are
// deliberately instructions, not fake controls: Sony's private RFCOMM
// configuration protocol isn't available via a documented watchOS API.
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "earbuds")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("XM6 Wrist")
                                .font(.headline)
                            Text("WF-1000XM6 • Unofficial")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 4)

                    NavigationLink {
                        // Apple's full-screen Now Playing view controls the
                        // current audio source (Watch or paired iPhone).
                        NowPlayingView()
                    } label: {
                        ActionLabel(icon: "play.circle.fill",
                                    title: "Now Playing",
                                    detail: "Pause, skip & media volume",
                                    color: .cyan)
                    }

                    NavigationLink {
                        VolumePage()
                    } label: {
                        ActionLabel(icon: "speaker.wave.2.fill",
                                    title: "Volume",
                                    detail: "Watch or iPhone audio",
                                    color: .green)
                    }

                    NavigationLink {
                        EarbudGesturesPage()
                    } label: {
                        ActionLabel(icon: "hand.tap.fill",
                                    title: "Earbud Touches",
                                    detail: "ANC, ambient & music gestures",
                                    color: .orange)
                    }

                    NavigationLink {
                        DiagnosticsView()
                    } label: {
                        ActionLabel(icon: "antenna.radiowaves.left.and.right",
                                    title: "Bluetooth Probe",
                                    detail: "Check direct Watch connection",
                                    color: .yellow)
                    }

                    NavigationLink {
                        SonySettingsPage()
                    } label: {
                        ActionLabel(icon: "slider.horizontal.3",
                                    title: "Sony Settings",
                                    detail: "What requires Sound Connect",
                                    color: .purple)
                    }

                    Text("Direct Sony controls remain experimental. Probe tests Watch-accessible Bluetooth services, not ANC/EQ commands.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 2)
            }
            .navigationTitle("XM6 Wrist")
        }
        .tint(.cyan)
    }
}

private struct ActionLabel: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VolumePage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Use the Digital Crown after selecting a volume control.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 7) {
                    Label("Apple Watch audio", systemImage: "applewatch")
                        .font(.caption.weight(.semibold))
                    VolumeDial(origin: .local)
                        .frame(height: 38)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 7) {
                    Label("Paired iPhone audio", systemImage: "iphone")
                        .font(.caption.weight(.semibold))
                    VolumeDial(origin: .companion)
                        .frame(height: 38)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                Text("The volume buttons affect the selected audio source, not Sony's private headphone settings.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Volume")
    }
}

// Apple provides the only supported public volume control for watchOS apps.
struct VolumeDial: WKInterfaceObjectRepresentable {
    let origin: WKInterfaceVolumeControl.Origin

    func makeWKInterfaceObject(context: Context) -> WKInterfaceVolumeControl {
        WKInterfaceVolumeControl(origin: origin)
    }

    func updateWKInterfaceObject(_ object: WKInterfaceVolumeControl, context: Context) { }
}

struct EarbudGesturesPage: View {
    var body: some View {
        List {
            Section("Left earbud") {
                InstructionRow("1 tap", "Switch Noise Canceling / Ambient Sound")
                InstructionRow("4+ taps", "Lower volume")
                InstructionRow("Touch & hold", "Quick Attention")
            }
            Section("Right earbud") {
                InstructionRow("1 tap", "Play or pause")
                InstructionRow("2 taps", "Next track")
                InstructionRow("3 taps", "Previous/current track")
                InstructionRow("4+ taps", "Raise volume")
            }
            Section {
                Text("Touch actions can be customized in Sony | Sound Connect, so yours may differ from these factory defaults.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Touch Guide")
    }
}

private struct InstructionRow: View {
    let gesture: String
    let meaning: String

    init(_ gesture: String, _ meaning: String) {
        self.gesture = gesture
        self.meaning = meaning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(gesture)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.cyan)
            Text(meaning)
                .font(.caption)
        }
    }
}

struct SonySettingsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Label("Settings unavailable on Watch", systemImage: "lock.shield")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                Text("Sony's WF-1000XM6 uses private device commands for these features. This app does not send unverified commands.")
                    .font(.caption)

                Text("Set these in Sony | Sound Connect on your iPhone:")
                    .font(.caption.weight(.semibold))

                ForEach(["Noise Canceling / Ambient level",
                         "Equalizer and Clear Bass",
                         "Speak-to-Chat",
                         "DSEE Extreme",
                         "Touch sensor customization",
                         "Connection quality & multipoint",
                         "Firmware updates"], id: \.self) { feature in
                    Label(feature, systemImage: "circle.small")
                        .font(.caption)
                }

                Text("After configuration, many headphone settings remain active when you listen from the Watch.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Sony Settings")
    }
}

import SwiftUI

/// First hardware feasibility step, NOT a Sony settings controller.
struct DiagnosticsView: View {
    @StateObject private var probe = BluetoothProbe()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Bluetooth diagnostic")
                    .font(.headline)
                Text("Find your WF-1000XM6 and inspect services the Watch can use. Read-only; no Sony settings will change.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(probe.status)
                    .font(.caption)
                    .foregroundStyle(.cyan)

                Button {
                    if probe.isScanning { probe.stopScan() }
                    else { probe.scan() }
                } label: {
                    Label(probe.isScanning ? "Stop scan" : "Scan for earbuds",
                          systemImage: probe.isScanning ? "stop.circle" : "waveform.path")
                }
                .buttonStyle(.borderedProminent)

                if !probe.devices.isEmpty {
                    Text("Discovered devices (tap one)")
                        .font(.caption.weight(.semibold))
                    ForEach(probe.devices) { device in
                        Button {
                            probe.inspect(device.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.caption.weight(device.isLikelySony ? .bold : .regular))
                                Text("RSSI \(device.rssi) • \(device.id.uuidString.prefix(8))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                if !device.advertisedServices.isEmpty {
                                    Text(device.advertisedServices)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if probe.connectionName != nil {
                    Button("Disconnect") { probe.disconnect() }
                        .buttonStyle(.bordered)
                }

                Text("Diagnostic report")
                    .font(.caption.weight(.semibold))
                ShareLink(item: probe.report) {
                    Label("Share report", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                Text(probe.report)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 3)
        }
        .navigationTitle("GATT Probe")
    }
}

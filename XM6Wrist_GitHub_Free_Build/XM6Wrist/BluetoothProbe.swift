import Foundation
import Combine
import CoreBluetooth

/// Read-only Core Bluetooth inspector for an Apple Watch.
/// Sony's known settings protocol uses RFCOMM. Core Bluetooth exposes GATT,
/// NOT a general-purpose RFCOMM socket. This tool checks whether the earbuds
/// offer any additional, watch-accessible GATT services.
final class BluetoothProbe: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    struct NearbyDevice: Identifiable {
        let id: UUID
        var name: String
        var rssi: Int
        var advertisedServices: String
        var isLikelySony: Bool {
            let n = name.lowercased()
            return n.contains("sony") || n.contains("wf-1000") || n.contains("le_wf") || n.contains("le-wf")
        }
    }

    @Published private(set) var devices: [NearbyDevice] = []
    @Published private(set) var status = "Starting Bluetooth…"
    @Published private(set) var isScanning = false
    @Published private(set) var connectionName: String? = nil
    @Published private(set) var events: [String] = ["Read-only GATT probe: no data is written to earbuds."]

    private var manager: CBCentralManager!
    private var discovered: [UUID: CBPeripheral] = [:]
    private var advertisements: [UUID: [String: Any]] = [:]
    private var connected: CBPeripheral?

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: .main)
    }

    var report: String {
        (["XM6 Wrist — Bluetooth GATT diagnostic", "Watch-side, read-only", "Bluetooth state: \(status)", ""] + events).joined(separator: "\n")
    }

    func scan() {
        guard manager.state == .poweredOn else {
            status = "Bluetooth unavailable (\(stateDescription(manager.state)))."
            record(status)
            return
        }
        devices.removeAll()
        discovered.removeAll()
        advertisements.removeAll()
        // Foreground scan, no UUID filter: the Sony advertisement UUID is unknown.
        manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        isScanning = true
        status = "Scanning nearby Bluetooth GATT devices…"
        record("Scan started. Keep the earbuds awake and nearby.")
    }

    func stopScan() {
        manager.stopScan()
        isScanning = false
        status = "Scan stopped • \(devices.count) device(s)"
        record(status)
    }

    func inspect(_ id: UUID) {
        guard let target = discovered[id] else {
            record("Selected device no longer available; scan again.")
            return
        }
        stopScan()
        if let previous = connected, previous.identifier != id {
            manager.cancelPeripheralConnection(previous)
        }
        connected = target
        target.delegate = self
        connectionName = devices.first(where: { $0.id == id })?.name ?? target.name ?? "Unnamed device"
        record("Selected: \(connectionName!) (\(id.uuidString))")
        if let info = advertisements[id] {
            let keys = info.keys.sorted()
            for key in keys {
                if key == CBAdvertisementDataManufacturerDataKey, let data = info[key] as? Data {
                    record("  manufacturer data: \(data.map { String(format: "%02X", $0) }.joined())")
                } else if key == CBAdvertisementDataServiceUUIDsKey,
                          let services = info[key] as? [CBUUID] {
                    record("  advertised UUIDs: \(services.map(\.uuidString).joined(separator: ", "))")
                } else if key == CBAdvertisementDataLocalNameKey,
                          let value = info[key] as? String {
                    record("  advertised name: \(value)")
                }
            }
        }
        status = "Connecting to \(connectionName!)…"
        manager.connect(target, options: nil)
    }

    func disconnect() {
        guard let connected else { return }
        manager.cancelPeripheralConnection(connected)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        status = stateDescription(central.state)
        record("Bluetooth: \(status)")
        if central.state != .poweredOn { isScanning = false }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let id = peripheral.identifier
        discovered[id] = peripheral
        advertisements[id] = advertisementData
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name ?? "Unnamed \(id.uuidString.prefix(8))"
        let advertised = ((advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? [])
            .map(\.uuidString).joined(separator: ", ")
        let entry = NearbyDevice(id: id, name: name, rssi: RSSI.intValue, advertisedServices: advertised)
        if let index = devices.firstIndex(where: { $0.id == id }) {
            devices[index] = entry
        } else if devices.count < 60 {
            devices.append(entry)
        }
        devices.sort { lhs, rhs in
            if lhs.isLikelySony != rhs.isLikelySony { return lhs.isLikelySony }
            return lhs.rssi > rhs.rssi
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        status = "Connected (GATT)"
        record("Connected to \(peripheral.name ?? peripheral.identifier.uuidString)")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        status = "Connection failed"
        record("Connection failed: \(error?.localizedDescription ?? "Unknown error")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        status = "Disconnected"
        record("Disconnected: \(error?.localizedDescription ?? "normal")")
        if connected?.identifier == peripheral.identifier { connected = nil }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            record("Service discovery failed: \(error.localizedDescription)")
            return
        }
        let services = peripheral.services ?? []
        record("GATT services: \(services.count)")
        if services.isEmpty { record("No GATT services exposed.") }
        for service in services {
            record("SERVICE \(service.uuid.uuidString)\(service.isPrimary ? " [primary]" : " [secondary]")")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error {
            record("Characteristics for \(service.uuid.uuidString): \(error.localizedDescription)")
            return
        }
        let chars = service.characteristics ?? []
        if chars.isEmpty { record("  No characteristics for \(service.uuid.uuidString)") }
        for characteristic in chars {
            let props = characteristic.properties
            var flags: [String] = []
            if props.contains(.read) { flags.append("R") }
            if props.contains(.write) { flags.append("W") }
            if props.contains(.writeWithoutResponse) { flags.append("WNR") }
            if props.contains(.notify) { flags.append("N") }
            if props.contains(.indicate) { flags.append("I") }
            record("  CHAR \(characteristic.uuid.uuidString) [\(flags.joined(separator: ","))]")
        }
        // No characteristic reads, subscriptions, writes or private Sony commands.
    }

    private func record(_ message: String) {
        events.append(message)
        if events.count > 200 { events.removeFirst(events.count - 200) }
    }

    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOn: return "Bluetooth ready"
        case .poweredOff: return "Bluetooth is off"
        case .unauthorized: return "Bluetooth permission denied"
        case .unsupported: return "Bluetooth unsupported"
        case .resetting: return "Bluetooth resetting"
        case .unknown: return "Bluetooth state unknown"
        @unknown default: return "Unknown Bluetooth state"
        }
    }
}

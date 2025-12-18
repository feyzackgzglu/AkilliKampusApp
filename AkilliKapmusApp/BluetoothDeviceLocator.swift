//
//  BluetoothDeviceLocator.swift
//  AkilliKapmusApp
//
//  Created by Feyza on 18.12.2025.
//

import DeviceDiscoveryExtension
import CoreBluetooth
import UniformTypeIdentifiers

/// A DeviceLocator that searches for devices using CoreBluetooth.
class BluetoothDeviceLocator: NSObject, DeviceLocator, CBCentralManagerDelegate {
    
    /// The central manger for Bluetooth communications.
    private var centralManager: CBCentralManager
    
    override init() {
        // Create a central Bluetooth manager to search for devices.
        
        centralManager = CBCentralManager(delegate: nil, queue: nil, options: [:])
        
        super.init()
        
        centralManager.delegate = self
    }
    
    /// The event handler that passes events back to the session.
    var eventHandler: DDEventHandler?
    
    /// Start scanning for devices using Bluetooth.
    func startScanning() {
        
        // An example Bluetooth service ID for the device for which to scan.
        // This must match a value contained within the NSBluetoothServices array in the extension's Info.plist.
        let exampleServiceID = CBUUID(string: "488F9CCA-0E72-4469-B855-DBC43F14D01B")
        
        // Start the central manager.
        
        centralManager.scanForPeripherals(withServices: [exampleServiceID])
    }
    
    /// Stop scanning for devices using Bluetooth.
    func stopScanning() {
        
        // Stop the central manager.
        
        centralManager.stopScan()
    }
    
    /// The devices known to this locator.
    private var knownDevices: [DDDevice] = []
    
    /// Inform the session of the device state represented by the discovered peripheral.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // If no event handler is set, don't report anything.
        
        guard let eventHandler = eventHandler else {
            return
        }
        
        // An example device identifier and name for the discovered device.
        // It's important that this come from or be associated with the device itself.
        let exampleDeviceUUID = UUID()
        let exampleDeviceIdentifier = exampleDeviceUUID.uuidString
        let exampleDeviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        
        // An example protocol for the discovered device.
        // This must match the type declared in the extension's Info.plist.
        guard let exampleDeviceProtocol = UTType("com.example.example-protocol") else {
            fatalError("Misconfiguration: UTType for protocol not defined.")
        }
        
        // Create a DDDevice instance representing the device.
        let device = DDDevice(displayName: exampleDeviceName, category: .hifiSpeaker, protocolType: exampleDeviceProtocol, identifier: exampleDeviceIdentifier)
        device.bluetoothIdentifier = exampleDeviceUUID
        
        knownDevices.append(device)
        
        // Pass it to the event handler.
        
        let event = DDDeviceEvent(eventType: .deviceFound, device: device)
        eventHandler(event)
    }
    
    /// Handle state updates for the central manager itself.
    /// This required protocol method can be used to detect when Bluetooth status changes, by checking the central manager's state property.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        // Handle Bluetooth state changes, for example by informing the eventHandler that the devices that were previously discovered are no longer available.
        
        switch central.state {
        case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
            if let eventHandler = eventHandler {
                for device in knownDevices {
                    let event = DDDeviceEvent(eventType: .deviceLost, device: device)
                    eventHandler(event)
                }
            }
            knownDevices.removeAll()
            
        case .poweredOn:
            knownDevices = []
            
        @unknown default:
            break
        }
    }
}

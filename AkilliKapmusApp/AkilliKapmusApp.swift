//
//  AkilliKapmusApp.swift
//  AkilliKapmusApp
//
//  Created by Feyza on 18.12.2025.
//

import DeviceDiscoveryExtension

@main
class AkilliKapmusApp: DDDiscoveryExtension {
    
    /// A DeviceLocator that searches for devices via Bluetooth.
    private var bluetoothDeviceLocator: DeviceLocator
    
    required init() {
        
        // Create a DeviceLocator to look for Bluetooth devices.
        
        bluetoothDeviceLocator = BluetoothDeviceLocator()
    }
    
    /// Start searching for devices.
    func startDiscovery(session: DDDiscoverySession) {
        
        // Set up an event handler so the device locators can inform the session about devices.
        
        let eventHandler: DDEventHandler = { event in
            session.report(event)
        }
        
        bluetoothDeviceLocator.eventHandler = eventHandler
        
        // Start scanning for devices.
        
        bluetoothDeviceLocator.startScanning()
    }
    
    /// Stop searching for devices.
    func stopDiscovery(session: DDDiscoverySession) {
        // Stop scanning for devices.
        
        bluetoothDeviceLocator.stopScanning()
        
        // Ensure no more events are reported.
        
        bluetoothDeviceLocator.eventHandler = nil
    }
}

/// A DeviceLocator knows how to scan for devices and encapsulates the details about how it does so.
protocol DeviceLocator {
    
    /// Start scanning for devices.
    func startScanning()
    
    /// Stop scanning for devices.
    func stopScanning()
    
    /// When a device changes state, the DeviceLocator will invoke this handler. The extension can then pass the given event back to its session.
    var eventHandler: DDEventHandler? { get set }
}

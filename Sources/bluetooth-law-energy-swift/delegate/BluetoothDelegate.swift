//
//  BluetoothDelegateHandler.swift
//
//
//  Created by Igor on 12.07.24.
//

import Combine
import CoreBluetooth

extension BluetoothLEManager {

    class BluetoothDelegate: NSObject, CBCentralManagerDelegate {
        
        /// A subject to publish Bluetooth state updates.
        private let stateSubject = PassthroughSubject<CBManagerState, Never>()
        
        /// A subject to publish discovered Bluetooth peripherals.
        private let peripheralSubject = CurrentValueSubject<[CBPeripheral], Never>([])
                
        private let service: RegistrationService<Void> = .init(type: .connection)
        
        // MARK: - API
        
        /// Connects to a given peripheral.
        ///
        /// - Parameters:
        ///   - peripheral: The `CBPeripheral` instance to connect to.
        ///   - manager: The `CBCentralManager` used to manage the connection.
        ///   - timeout: The time interval to wait before timing out the connection attempt.
        /// - Returns: The connected `CBPeripheral`.
        /// - Throws: A `BluetoothLEManager.Errors` error if the connection fails.
        public func register(
            to id: UUID,
            name : String,
            with continuation : CheckedContinuation<Void, Error>) async throws{
                try await service.register(to: id, name: name, with: continuation)
        }
        
        
        /// A publisher for Bluetooth state updates, applying custom operators to handle initial powered-off state and receive on the main thread.
        public var statePublisher: AnyPublisher<CBManagerState, Never> {
            stateSubject
                .dropFirstIfPoweredOff()
        }
        
        /// A publisher for discovered Bluetooth peripherals, ensuring updates are received on the main thread.
        public var peripheralPublisher: AnyPublisher<[CBPeripheral], Never> {
            peripheralSubject
                .eraseToAnyPublisher()
        }
        
        // MARK: - Delegate API methods
        
        /// Called when the central manager's state is updated.
        ///
        /// - Parameter central: The central manager whose state has been updated.
        public func centralManagerDidUpdateState(_ central: CBCentralManager) {
            // Send state updates through the state subject
            stateSubject.send(central.state)
        }
        
        /// Called when a peripheral is discovered during a scan.
        ///
        /// - Parameters:
        ///   - central: The central manager that discovered the peripheral.
        ///   - peripheral: The discovered peripheral.
        ///   - advertisementData: A dictionary containing advertisement data.
        ///   - RSSI: The signal strength of the peripheral.
        public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            var peripherals = peripheralSubject.value
            // Add the peripheral to the list if it hasn't been discovered before
            if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                peripherals.append(peripheral)
                peripheralSubject.send(peripherals)
            }
        }
        
        /// Called when a connection to a peripheral is successful.
        ///
        /// - Parameters:
        ///   - central: The central manager managing the connection.
        ///   - peripheral: The peripheral that has successfully connected.
        public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            Task{
                await service.handleResult(for: peripheral, result: .success(Void()))
            }
        }
        
        /// Called when a connection attempt to a peripheral fails.
        ///
        /// - Parameters:
        ///   - central: The central manager managing the connection.
        ///   - peripheral: The peripheral that failed to connect.
        ///   - error: The error that occurred during the connection attempt.
        public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            Task{
                await service.handleResult(for: peripheral, result: .failure(BluetoothLEManager.Errors.connection(peripheral, error)))
            }
        }
        
        /// Called when a peripheral disconnects.
        ///
        /// - Parameters:
        ///   - central: The central manager managing the connection.
        ///   - peripheral: The peripheral that has disconnected.
        ///   - error: The error that occurred during the disconnection, if any.
        public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            // TODO: implement
        }
    }
}

//
//  ViewController.swift
//  blue_test
//
//  Created by HamiltonMac on 10/12/16.
//  Copyright © 2016 HamiltonMac. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var onBtn: UIButton!
    @IBOutlet weak var offBtn: UIButton!
    @IBOutlet weak var textLbl: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    var centralManager:CBCentralManager!
    var arduino:CBPeripheral?
    var dataBuffer:NSMutableData!
    var scanAfterDisconnecting:Bool = true
    
    //Core Bluetooth properties
    var ledCharacteristic:CBCharacteristic?
    var stateCharacteristic:CBCharacteristic?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and start the central manager
        // Without State Preservation and Restoration:
        centralManager = CBCentralManager(delegate: self, queue: nil)
  
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.textLbl.text = "Device Not Found"
        dataBuffer = NSMutableData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopScanning()
        scanAfterDisconnecting = false
        disconnect()
    }

  
    private func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        
        //---------------------------------------------------------------------------
        // We don't need these, but it's good to know that they exist.
        //---------------------------------------------------------------------------
        // Retrive array of service UUIDs (represented by CBUUID objects) that
        // contains all the services the central manager was scanning for at the time
        // the app was terminated by the system.
        //
        //let scanServices = dict[CBCentralManagerRestoredStateScanServicesKey]
        
        // Retrieve dictionary containing all of the peripheral scan options that
        // were being used by the central manager at the time the app was terminated
        // by the system.
        //
        //let scanOptions = dict[CBCentralManagerRestoredStateScanOptionsKey]
        //---------------------------------------------------------------------------
        
        /*
         Retrieve array of CBPeripheral objects containing all of the peripherals that were connected to the central manager
         (or that had a connection pending) at the time the app was terminated by the system.
         
         When possible, all the information about a peripheral is restored, including any discovered services, characteristics,
         characteristic descriptors, and characteristic notification states.
         */
        
        if let peripheralsObject = dict[CBCentralManagerRestoredStatePeripheralsKey] {
            let peripherals = peripheralsObject as! Array<CBPeripheral>
            if peripherals.count > 0 {
                // Just grab the first one in this case. If we had maintained an array of
                // multiple peripherals then we would just add them to our array and set the delegate...
                arduino = peripherals[0]
                arduino?.delegate = self
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager State Updated: \(central.state)")
        
        // We showed more detailed handling of this in Zero-to-BLE Part 2, so please refer to that if you would like more information.
        // We will just handle it the easy way here: if Bluetooth is on, proceed...
        if central.state != .poweredOn {
            self.arduino = nil
            print("something happened7")
            return
        }
        
        startScanning()
        print("something happened1")
        //--------------------------------------------------------------
        // If the app has been restored with the peripheral in centralManager(_:, willRestoreState:),
        // we start subscribing to updates again to the Transfer Characteristic.
        //--------------------------------------------------------------
        // check for a peripheral object
        guard let arduino = self.arduino else {
            print("something happened3 new")
            return
        }
        
        // see if that peripheral is connected
        guard arduino.state == .connected else {
            print("something happened4")
            return
        }
        
        // make sure the peripheral has services
        guard let peripheralServices = arduino.services else {
            print("something happened5")
            return
        }
        print("something happened2")
        // we have services, but we need to check for the Transfer Service
        // (honestly, this may be overkill for our project but it demonstrates how to make this process more bulletproof...)
        // Also: Pardon the pyramid.
        let serviceUUID = CBUUID(string: Device.TransferService)
        if let serviceIndex = peripheralServices.index(where: {$0.uuid == serviceUUID}) {
            // we have the service, but now we check to see if we have a characteristic that we've subscribed to...
            let transferService = peripheralServices[serviceIndex]
            let characteristicUUID = CBUUID(string: Device.TransferCharacteristic)
            if let characteristics = transferService.characteristics {
                if let characteristicIndex = characteristics.index(where: {$0.uuid == characteristicUUID}) {
                    // Because this is a characteristic that we subscribe to in the standard workflow,
                    // we need to check if we are currently subscribed, and if not, then call the
                    // setNotifyValue like we did before.
                    let characteristic = characteristics[characteristicIndex]
                    if !characteristic.isNotifying {
                        arduino.setNotifyValue(true, for: characteristic)
                    }
                } else {
                    // if we have not discovered the characteristic yet, then call discoverCharacteristics, and the delegate method will get called as in the standard workflow...
                    arduino.discoverCharacteristics([characteristicUUID], for: transferService)
                }
            }
        } else {
            // we have a CBPeripheral object, but we have not discovered the services yet,
            // so we call discoverServices and the delegate method will handle the rest...
            arduino.discoverServices([serviceUUID])
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //print("Name : \(advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? )!")
        //print(peripheral.name!)
        if (advertisementData[CBAdvertisementDataLocalNameKey] as? String) != nil {
        
        if peripheral.name != "AutoRide"
        {
            print(peripheral.name!)
            return;
        }
        
        print("Discovered \(peripheral.name!) at \(RSSI)")
        rssiLabel.text = RSSI.stringValue
        
        // Reject if the signal strength is too low to be close enough ("close" is around -22dB)
        if RSSI.intValue < -35 {
            rssiLabel.textColor = UIColor.red
            //return;
        }
        
        print("Device is in acceptable range!!")
        rssiLabel.textColor = UIColor.green
        // stopScanning() This gets done after didConnect
        // check to see if we've already saved a reference to this peripheral
        if peripheral != arduino {
            
            // save a reference to the peripheral object so Core Bluetooth doesn't get rid of it
            arduino = peripheral
            
            // connect to the peripheral
            //print("Connecting to peripheral: \(peripheral.services)")
            centralManager?.connect(arduino!, options: nil)
            print("Connecting to peripheral: \(String(describing: arduino?.name))")
        }
        
        self.centralManager.stopScan()
        print("Scanning Stopped!")
    }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected!!!")
        
        //connectionIndicatorView.layer.backgroundColor = UIColor.greenColor().CGColor
        
        // Stop scanning
        
        textLbl.text = peripheral.name
        // Clear any cached data...
        dataBuffer.length = 0
        
        
        arduino = peripheral
        arduino!.delegate = self
        
        // IMPORTANT: Set the delegate property, otherwise we won't receive the discovery callbacks, like peripheral(_:didDiscoverServices)
        //self.peripheral = peripheral
    
        // Now that we've successfully connected to the peripheral, let's discover the services.
        // This time, we will search for the transfer service UUID
        print("Looking for Transfer Service...\(String(describing: arduino))")
        print("\([CBUUID.init(string: Device.TransferService)])")
        //self.peripheral!.discoverServices([CBUUID.init(string: Device.TransferService)])
        arduino!.discoverServices(nil)

        
    }
    
    // MARK: Central management methods
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func startScanning() {
        if centralManager.isScanning {
            print("Central Manager is already scanning!!")
            return;
        }
        //centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        //centralManager.scanForPeripherals(withServices: [CBUUID]?, options: <#T##[String : Any]?#>)
        print("Scanning Started!")
        
        
    }
    func disconnect() {
        // verify we have a peripheral
        guard let arduino = self.arduino else {
            print("Peripheral object has not been created yet.")
            return
        }
        
        // check to see if the peripheral is connected
        if arduino.state != .connected {
            print("Peripheral exists but is not connected.")
            self.arduino = nil
            return
        }
        
        guard let services = arduino.services else {
            // disconnect directly
            centralManager.cancelPeripheralConnection(arduino)
            return
        }
        
        for service in services {
            // iterate through characteristics
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    // find the Transfer Characteristic we defined in our Device struct
                    if characteristic.uuid == CBUUID.init(string: Device.TransferCharacteristic) {
                        // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                        // didUpdateNotificationStateForCharacteristic method will be called automatically
                        arduino.setNotifyValue(false, for: characteristic)
                        return
                    }
                }
            }
        }
        
        // We have a connection to the device but we are not subscribed to the Transfer Characteristic for some reason.
        // Therefore, we will just disconnect from the peripheral
        centralManager.cancelPeripheralConnection(arduino)
    }

    
    //MARK: - CBPeripheralDelegate methods
    
    /*
     Invoked when you discover the peripheral’s available services.
     
     This method is invoked when your app calls the discoverServices: method.
     If the services of the peripheral are successfully discovered, you can access them
     through the peripheral’s services property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        print("Discovered Services!!!")
        
        if error != nil {
            print("Error discovering services: \(String(describing: error?.localizedDescription))")
            disconnect()
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            
            
            
            for service in services {
                print("Discovered service \(service)")
                
                // If we found either the transfer service, discover the transfer characteristic
                if (service.uuid == CBUUID(string: Device.TransferService)) {
                    let transferCharacteristicUUID = CBUUID.init(string: Device.TransferCharacteristic)
                    peripheral.discoverCharacteristics([transferCharacteristicUUID], for: service)
                }
            }
        }
    }
    
    /*
     Invoked when you discover the characteristics of a specified service.
     
     If the characteristics of the specified service are successfully discovered, you can access
     them through the service's characteristics property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("You almost there...Good Sunday work!!!")
        
        
        print(service)
        
        
        if error != nil {
            print("Error discovering characteristics: \(String(describing: error?.localizedDescription))")
            return
        }
        print("didDiscover")
        if let characteristics = service.characteristics {
            
            //var enableValue:UInt8 = 1
            //let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
            
            for characteristic in characteristics {
                // Transfer Characteristic
                if characteristic.uuid == CBUUID(string: Device.TransferCharacteristic) {
                    // subscribe to dynamic changes
                    arduino?.setNotifyValue(true, for: characteristic)
                    ledCharacteristic = characteristic
                    print(characteristic)
                }
                
                //Write value to turn LED on
                /*
                if characteristic.uuid == CBUUID(string: Device.TransferCharacteristic) {
                    arduino?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                    
                }
                */
                
            }
        }
    }
    
    
    /*
     Invoked when you retrieve a specified characteristic’s value,
     or when the peripheral device notifies your app that the characteristic’s value has changed.
     
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for
     which notifications and indications are enabled has changed.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueForCharacteristic: \(NSDate())")
        print("something happened3")
        // if there was an error then print it and bail out
        if error != nil {
            print("Error updating value for characteristic: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        // make sure we have a characteristic value
        guard let value = characteristic.value else {
            print("Characteristic Value is nil on this go-round")
            return
        }
        
        print("Bytes transferred: \(value.count)")
        
        // make sure we have a characteristic value
        guard let nextChunk = String(data: value, encoding: String.Encoding.utf8) else {
            print("Next chunk of data is nil.")
            return
        }
        
        print("Next chunk: \(nextChunk)")
        
        // If we get the EOM tag, we fill the text view
        if (nextChunk == Device.EOM) {
            if let message = String(data: dataBuffer as Data, encoding: String.Encoding.utf8) {
                textLbl.text = message
                print("Final message: \(message)")
                
                // truncate our buffer now that we received the EOM signal!
                dataBuffer.length = 0
            }
        } else {
            dataBuffer.append(value)
            print("Next chunk received: \(nextChunk)")
            if let buffer = self.dataBuffer {
                print("Transfer buffer: \(String(describing: String(data: buffer as Data, encoding: String.Encoding.utf8)))")
            }
        }
    }
    
    /*
     Invoked when the peripheral receives a request to start or stop providing notifications
     for a specified characteristic’s value.
     
     This method is invoked when your app calls the setNotifyValue:forCharacteristic: method.
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
     func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // if there was an error then print it and bail out
        print("didDiscover2")
        if error != nil {
            print("Error changing notification state: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if characteristic.isNotifying {
            // notification started
            print("Notification STARTED on characteristic: \(characteristic)")
        } else {
            // notification stopped
            print("Notification STOPPED on characteristic: \(characteristic)")
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
        
    }
    
    private func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("didDiscover11")
    }
    
    @IBAction func onBtnTapped(_ sender: Any) {
        print("On Button Tapped")
        if let char = ledCharacteristic {
            print("ledCharacteristic")
            var enableValue:UInt8 = 1
            let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)

            arduino?.writeValue(enableBytes as Data, for: char, type: .withResponse)
            
            }
    }
    @IBAction func offBtnTapped(_ sender: Any) {
        
        if let char = ledCharacteristic {
            
            var enableValue:UInt8 = 0
            let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
            
            arduino?.writeValue(enableBytes as Data, for: char, type: .withResponse)
            
        }
    }
    
    
    
}


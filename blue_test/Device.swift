//
//  Device.swift
//  blue_test
//
//  Created by HamiltonMac on 10/12/16.
//  Copyright © 2016 HamiltonMac. All rights reserved to Hamilton
//

import Foundation

struct Device {
    
    // UUIDs

    static let TransferService = "FF10"
    static let TransferCharacteristic = "FF11"
    
    // Tags
    static let EOM = "{{{EOM}}}"
    
    // We have a 20-byte limit for data transfer
    static let notifyMTU = 20
    
    static let centralRestoreIdentifier = "io.cloudcity.BLEConnect.CentralManager"
    static let peripheralRestoreIdentifier = "io.cloudcity.BLEConnect.PeripheralManager"
    

}

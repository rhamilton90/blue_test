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
    
    static let TransferService = "9bc808c2-0515-46fb-ea5b-0234443807c8"
    static let TransferCharacteristic = "a60b8389-74ef-40f2-ee8d-b90c9a9e7656"
    
    // Tags
    static let EOM = "{{{EOM}}}"
    
    // We have a 20-byte limit for data transfer
    //static let notifyMTU = 20
    
    //static let centralRestoreIdentifier = "io.cloudcity.BLEConnect.CentralManager"
    //static let peripheralRestoreIdentifier = "io.cloudcity.BLEConnect.PeripheralManager"
    

}

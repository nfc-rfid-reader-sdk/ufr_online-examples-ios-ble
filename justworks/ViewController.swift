//
//  ViewController.swift
//  justworks
//
//  Created by D-Logic on 3/5/21.
//

import UIKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
 
    
   
    var manager : CBCentralManager!
    var device = [CBPeripheral]()
    var characteristics = [CBCharacteristic]()
    var connected = false
    var result = [""]
    var justScan = false

    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var btnConnect: UIButton!
    @IBOutlet weak var btnBeep: UIButton!
    
    var deviceName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnBeep.isEnabled = false
        btnBeep.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        
        btnConnect.isEnabled = false
        btnConnect.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        txtName.inputView = pickerView
        manager = CBCentralManager(delegate: self, queue: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        // Do any additional setup after loading the view.
        view.addGestureRecognizer(tap);
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        var msg = ""
        switch central.state {
        case .poweredOff:
            msg = "Bluetooth is Off"
        case .poweredOn:
            msg = "Bluetooth is On"
            manager.scanForPeripherals(withServices: nil, options: nil)
        case .unsupported:
            msg = "Not Supported"
        default:
            msg = "😔"
        }
        print("STATE: " + msg)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
       
        if(justScan)
        {
            let dev = peripheral.name ?? ""
            if(!result.contains(dev) && dev != "" && dev.starts(with: "ON"))
            {
                result.append(peripheral.name!)
                if(txtName.text == "")
                {
                    txtName.text = dev
                    btnConnect.isEnabled = true
                    btnConnect.backgroundColor = #colorLiteral(red: 0.6222038269, green: 0.8074405193, blue: 0.3299235404, alpha: 1)
                }
                    
            }
        }
        else
        {
            if(peripheral.name == deviceName)
            {
                print("Device found")
                manager.stopScan()
                peripheral.delegate = self
                device.append(peripheral)
                manager.connect(peripheral, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if(peripheral.name == deviceName)
        {
            connected = true
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if(peripheral.name == deviceName)
        {
            connected = false
            btnConnect.setTitle("Connect", for: .normal)
            btnBeep.isEnabled = false
            btnBeep.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
            print("Disconnected")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        print("Service discovered")
        guard let services = peripheral.services else  {return}
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Characteristics discovered")
        guard let ch = service.characteristics else {return}
        characteristics = ch
        btnConnect.setTitle("Connected", for: .normal)
        btnBeep.isEnabled = true
        btnBeep.backgroundColor = #colorLiteral(red: 0.6222038269, green: 0.8074405193, blue: 0.3299235404, alpha: 1)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

    }
    
    func beep() {

        if (connected) {
            let value: [UInt8] = [0x55, 0x26, 0xAA, 0x00, 0x01, 0x02, 0xE1]
            device[0].writeValue(Data(value), for: characteristics[0], type: CBCharacteristicWriteType.withResponse)


        } else {
            print("Not connected")
        }
    }
    
    @IBAction func scanBtn(_ sender: Any) {
        justScan = true
        result.removeAll()
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey:
        NSNumber(value: false)]
        manager.scanForPeripherals(withServices: nil, options: options)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.manager.stopScan()
            if(self.result.count == 0)
            {
                self.btnConnect.isEnabled = false
                self.btnConnect.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                self.txtName.text = ""
            }
        }
    }
    
    @IBAction func connectBtn(_ sender: Any) {
     
        if(!connected)
        {
            justScan = false
            device.removeAll()
            characteristics.removeAll()
            deviceName = txtName.text!
            let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey:
            NSNumber(value: false)]
            manager.scanForPeripherals(withServices: nil, options: options)
        }
        else
        {
            manager.cancelPeripheralConnection(device[0])
        }
      
    }
    
    @IBAction func beepBtn(_ sender: Any) {
        if(connected)
        {
            beep()
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return result.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return result[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        txtName.text = result[row]
    }
    

     
    

}


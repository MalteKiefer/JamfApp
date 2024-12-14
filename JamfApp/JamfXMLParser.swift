import SwiftUI
import Combine

class JamfXMLParser: NSObject, XMLParserDelegate {
    var devices: [JamfDevice] = []
    var mobildevices: [JamfMobileDevice] = []
    var mobildevicesdetails: JamfMobileDeviceDetails?
    private var currentElement = ""
    private var currentId: String = ""
    private var currentName: String = ""
    private var currentModel: String = ""
    private var currentUsername: String = ""
    private var currentDeviceType:String = "" // Entweder "computer" oder "mobile_device"
    private var currentPhoneNumber:String = ""
    private var currentOsBuild:String = ""
    private var currentOsVersion:String = ""
    private var currentReportDateEpoch: String = ""
    private var currentManaged: String = ""
    private var currentSupervised: String = ""
    private var currentModelIdentifier: String = ""
    private var currentModelNumber: String = ""
    private var currentSerialNumber: String = ""

    func parse(data: Data, forType type: JamfDeviceType) -> Any {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        switch type {
        case .jamfDevice:
            return devices
        case .jamfMobileDevice:
            return mobildevices
        case .jamfMobileDeviceDetails:
            return mobildevicesdetails
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        
        // Prüfen, ob ein neues Geräteobjekt beginnt
        if elementName == "computer" || elementName == "mobile_device" {
            currentDeviceType = elementName
            currentId = ""
            currentName = ""
            currentModel = ""
            currentUsername = ""
            currentOsVersion = ""
            currentOsBuild = ""
            currentPhoneNumber = ""
            currentReportDateEpoch = ""
            currentManaged = ""
            currentSupervised = ""
            currentModelIdentifier = ""
            currentModelNumber = ""
            currentSerialNumber = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }

        switch currentElement {
        case "id":
            currentId = trimmedString
        case "name":
            currentName = trimmedString
        case "model":
            currentModel = trimmedString
        case "username":
            currentUsername = trimmedString
        case "os_version":
            currentOsVersion = trimmedString
        case "os_build":
            currentOsBuild = trimmedString
        case "phone_number":
            currentPhoneNumber = trimmedString
        case "report_date_epoch":
            currentReportDateEpoch = trimmedString
        case "managed":
            currentManaged = trimmedString
        case "supervised":
            currentSupervised = trimmedString
        case "model_identifier":
            currentModelIdentifier = trimmedString
        case "model_number":
            currentModelNumber = trimmedString
        case "serial_number":
            currentSerialNumber = trimmedString
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "computer" {
            let device = JamfDevice(id: currentId, name: currentName, model: currentModel, report_date_epoch: currentReportDateEpoch, managed: currentManaged)
            devices.append(device)
            currentDeviceType = ""
        }
        if elementName == "mobile_device" {
            let device = JamfMobileDevice(id: currentId, name: currentName, model : currentModel, username: currentUsername, managed: currentManaged, supervised: currentSupervised)
            mobildevices.append(device)
            currentDeviceType = ""
        }
        if elementName == "general" {
            print("general")
            let device = JamfMobileDeviceDetails(id: currentId, name: currentName, model: currentModel, username: currentUsername, osversion: currentOsVersion, osbuild: currentOsBuild, phonenumber: currentPhoneNumber, model_identifier: currentModelIdentifier, model_number: currentModelNumber, serial_number: currentSerialNumber)
            mobildevicesdetails = device
            currentDeviceType = ""
        }
    }
}

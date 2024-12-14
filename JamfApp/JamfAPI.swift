import Foundation
import Combine

class JamfAPI: ObservableObject {
    @Published var computers: [JamfDevice] = []
    @Published var mobileDevices: [JamfMobileDevice] = []
    @Published var mobileDeviceDetails: JamfMobileDeviceDetails?
    @Published var mobileDeviceDetailsJson: [String: Any]?
    
    internal var authToken: String?
    
    public var username: String = ""
    public var password: String = ""
    public var jamfURL: String = ""

    func configure(username: String, password: String, jamfURL: String) {
        self.username = username
        self.password = password
        self.jamfURL = jamfURL
    }

    func authenticate(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(jamfURL)/api/v1/auth/token") else {
            print("Invalid URL")
            completion(false)
            return
        }
        print("Authenticating with URL: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            print("Failed to encode login data")
            completion(false)
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Authentication error: \(error)")
                completion(false)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    completion(false)
                    return
                }
            }
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.authToken = decodedResponse.token
                        print("Auth token received: \(decodedResponse.token)")
                        completion(true)
                    }
                } catch {
                    print("Error decoding auth response: \(error)")
                    completion(false)
                }
            }
        }.resume()
    }

    func fetchComputers() {
        guard let url = URL(string: "\(jamfURL)/JSSResource/computers/subset/basic") else {
            print("Invalid URL")
            return
        }
        print("Fetching computers from URL: \(url)")

        guard let token = authToken else {
            print("Auth token is missing. Authenticate first.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            if let data = data {
                let parser = JamfXMLParser()
                if let computers = (parser.parse(data: data, forType: .jamfDevice) as? [JamfDevice]) {
                    let sortedComputers = computers.map {
                        JamfDevice(id: $0.id, name: $0.name, model: $0.model, report_date_epoch: $0.report_date_epoch, managed: $0.managed)
                    }.sorted { $0.name < $1.name }

                    DispatchQueue.main.async {
                        self.computers = sortedComputers
                    }
                }
            }
        }.resume()
    }

    func fetchMobileDevices() {
        guard let url = URL(string: "\(jamfURL)/JSSResource/mobiledevices") else {
            print("Invalid URL for mobile devices")
            return
        }
        print("Fetching mobile devices from URL: \(url)")

        guard let token = authToken else {
            print("Auth token is missing. Authenticate first.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching mobile devices: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            if let data = data {
                let parser = JamfXMLParser()
                if let mobileDevices = (parser.parse(data: data, forType: .jamfMobileDevice) as? [JamfMobileDevice]) {
                    let sortedDevices = mobileDevices.map {
                        JamfMobileDevice(id: $0.id, name: $0.name, model: $0.model, username: $0.username, managed: $0.managed,supervised: $0.supervised)
                    }.sorted { $0.name < $1.name }
                    
                    DispatchQueue.main.async {
                        self.mobileDevices = sortedDevices
                    }
                }
            }
        }.resume()
    }
    
    func fetchMobileDeviceDetails(deviceId: String) {
        guard let url = URL(string: "\(jamfURL)/JSSResource/mobiledevices/id/\(deviceId)") else {
            print("Invalid URL for mobile device details")
            return
        }
        print("Fetching mobile device details from URL: \(url)")

        guard let token = authToken else {
            print("Auth token is missing. Authenticate first.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching mobile device details: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            if let data = data {
                let parser = JamfXMLParser()
                if let details = (parser.parse(data: data, forType: .jamfMobileDeviceDetails) as? JamfMobileDeviceDetails) {
                    DispatchQueue.main.async {
                        self.mobileDeviceDetails = details
                    }
                } else {
                    print("Failed to parse mobile device details")
                }
            }
        }.resume()
    }
    
    func fetchMobileDeviceDetailsJson(deviceId: String) {
        guard let url = URL(string: "\(jamfURL)/JSSResource/mobiledevices/id/\(deviceId)") else {
            print("Invalid URL for mobile device details")
            return
        }
        print("Fetching mobile device details from URL: \(url)")

        guard let token = authToken else {
            print("Auth token is missing. Authenticate first.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.allHTTPHeaderFields = ["accept": "application/json"]

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching mobile device details: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            if let data = data {
                do {
                    // Versuche, die Daten als JSON zu dekodieren und in der globalen Variable zu speichern
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    self.mobileDeviceDetailsJson = json
                    print("Mobile device details fetched successfully.")
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }


    func sendCommandDevice(deviceId: String, command: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "\(jamfURL)/JSSResource/mobiledevicecommands/command/\(command)/id/\(deviceId)") else {
            print("Invalid URL for restarting device")
            completion(false, "Invalid URL")
            return
        }

        guard let token = authToken else {
            print("Auth token is missing. Authenticate first.")
            completion(false, "Auth token is missing")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error restarting device: \(error)")
                completion(false, "Error \(command) device: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
                if httpResponse.statusCode == 201 {
                    DispatchQueue.main.async {
                        completion(true, "\(command) wurde durchgeführt")
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "Fehler, versuch es später erneut")
                    }
                }
            }
        }.resume()
    }
    
}

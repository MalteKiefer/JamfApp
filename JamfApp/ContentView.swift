import SwiftUI
import Combine
import LocalAuthentication

enum JamfDeviceType {
    case jamfDevice
    case jamfMobileDevice
    case jamfMobileDeviceDetails
}

struct JamfDevice: Identifiable, Decodable, Encodable {
    var id: String
    var name: String
    var model: String
    var report_date_epoch: String
    var managed: String
}

struct JamfMobileDevice: Identifiable, Decodable, Encodable {
    var id: String
    var name: String
    var model: String
    var username: String
    var managed: String
    var supervised: String
}

struct JamfMobileDeviceDetails: Identifiable, Decodable, Encodable, Equatable {
    var id: String
    var name: String
    var model: String
    var username: String
    var osversion: String
    var osbuild: String
    var phonenumber: String
    var model_identifier: String
    var model_number: String
    var serial_number: String
}

struct AuthResponse: Decodable {
    let token: String
    let expires: String
}

struct ContentView: View {
    @StateObject private var api = JamfAPI()
    @State private var showingLogin = false
    @State private var isLoading = false  // Track loading state
    
    var body: some View {
        TabView {

            ComputersView(api: api, isLoading: $isLoading)  // Pass loading state
                .tabItem {
                    Label("Computers", systemImage: "desktopcomputer")
                }
            
            MobileDevicesView(api: api, isLoading: $isLoading)  // Pass loading state
                .tabItem {
                    Label("Mobile Devices", systemImage: "iphone")
                }

            SettingsView(api: api)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            if let savedUsername = KeychainService.load(key: "username"),
               let savedPassword = KeychainService.load(key: "password"),
               let savedJamfURL = KeychainService.load(key: "jamfURL") {
                api.configure(username: savedUsername, password: savedPassword, jamfURL: savedJamfURL)
                api.authenticate { success in
                    if success {
                        api.fetchComputers()
                        api.fetchMobileDevices()
                    }
                }
            } else {
                showingLogin = true
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView(api: api, isPresented: $showingLogin)
        }
    }
    private func fetchComputers() {
        isLoading = true
        api.fetchComputers()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false  // Hide loading spinner after API call
        }
    }
}

struct ComputerDetailView: View {
    @ObservedObject var api: JamfAPI
    var deviceId: String
    
    var body: some View {
        VStack {
            
        }
    }
}

    
@main
struct JamfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

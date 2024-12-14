import SwiftUI

struct SettingsView: View {
    @ObservedObject var api: JamfAPI
    
    @State private var username: String
    @State private var password: String
    @State private var jamfURL: String
    
    init(api: JamfAPI) {
        self.api = api
        _username = State(initialValue: KeychainService.load(key: "username") ?? "")
        _password = State(initialValue: KeychainService.load(key: "password") ?? "")
        _jamfURL = State(initialValue: KeychainService.load(key: "jamfURL") ?? "")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.largeTitle)
                .bold()
            VStack(alignment: .leading, spacing: 8) {
                Form {
                    Section(header: Text("Jamf Credentials")) {
                        TextField("Username", text: $username)
                        SecureField("Password", text: $password)
                        TextField("Jamf URL", text: $jamfURL)

                        Button(action: {
                            KeychainService.save(key: "username", value: username)
                            KeychainService.save(key: "password", value: password)
                            KeychainService.save(key: "jamfURL", value: jamfURL)
                            api.configure(username: username, password: password, jamfURL: jamfURL)
                            api.authenticate { success in
                                if success {
                                    api.fetchComputers()
                                    api.fetchMobileDevices()
                                }
                            }
                        }) {
                            Text("Save")
                                .padding() // Padding around the text
                                .frame(maxWidth: .infinity) // Makes the button fill the available width
                                .foregroundColor(.white) // White text
                                .background(Color.blue) // Red background
                                .cornerRadius(10) // Rounded corners
                                .padding(.horizontal) // Padding around the button
                        }
                        .frame(maxWidth: .infinity) // Ensures the button stretches across the screen
                    }
                }
            }
        }
    }
}

import SwiftUI
import Foundation

struct LoginView: View {
    @ObservedObject var api: JamfAPI
    @Binding var isPresented: Bool

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var jamfURL: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Jamf Credentials")) {
                    TextField("Jamf URL", text: $jamfURL)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Button("Save") {
                    guard !jamfURL.isEmpty, !username.isEmpty, !password.isEmpty else {
                        showError = true
                        errorMessage = "All fields are required."
                        return
                    }
                    
                    // Save credentials to Keychain
                    KeychainService.save(key: "username", value: username)
                    KeychainService.save(key: "password", value: password)
                    KeychainService.save(key: "jamfURL", value: jamfURL)
                    
                    api.configure(username: username, password: password, jamfURL: jamfURL)
                    
                    api.authenticate { success in
                        DispatchQueue.main.async {
                            if success {
                                api.fetchComputers()
                                api.fetchMobileDevices()
                                isPresented = false
                            } else {
                                showError = true
                                errorMessage = "Authentication failed. Check your credentials."
                            }
                        }
                    }
                }
            }
            .navigationTitle("Login")
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

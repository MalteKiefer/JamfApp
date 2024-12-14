import SwiftUI

struct MobileDeviceDetailView: View {
    @ObservedObject var api: JamfAPI
    var deviceId: String
    var deviceName: String
    
    @State private var showAlert = false
    @State private var showConfirmationDialog = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Info"
    
    // Reusable method for creating HStack for displaying device information
    private func deviceInfoRow(label: String, value: String?) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value ?? "N/A")
                .foregroundColor(.gray)
        }
    }

    // Reusable method for creating action buttons
    private func actionButton(title: String, command: String) -> some View {
        Button(action: {
            api.sendCommandDevice(deviceId: deviceId, command: command) { success, message in
                self.alertMessage = message
                self.alertTitle = success ? "Done" : "Error"
                self.showAlert = true
            }
        }) {
            Text(title)
                .padding()
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                        .padding(5)
                )
        }
        .padding(.horizontal)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Device Information")) {
                    deviceInfoRow(label: "Serial Number:", value: api.mobileDeviceDetails?.serial_number)
                    deviceInfoRow(label: "Model:", value: api.mobileDeviceDetails?.model)
                    deviceInfoRow(label: "Model Identifier:", value: api.mobileDeviceDetails?.model_identifier)
                    deviceInfoRow(label: "Model Number:", value: api.mobileDeviceDetails?.model_number)
                }

                Section(header: Text("Operating System")) {
                    deviceInfoRow(label: "OS Version:", value: api.mobileDeviceDetails?.osversion)
                    deviceInfoRow(label: "OS Build:", value: api.mobileDeviceDetails?.osbuild)
                }

                Section(header: Text("Action")) {
                    actionButton(title: "Update Inventory", command: "UpdateInventory")
                    actionButton(title: "Clear Passcode", command: "ClearPasscode")
                    actionButton(title: "Restart", command: "RestartDevice")

                    Button(action: {
                        self.showConfirmationDialog = true
                    }) {
                        Text("Wipe")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(deviceName)
        .onAppear {
            api.fetchMobileDeviceDetails(deviceId: deviceId)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Are you sure you want to wipe this device? This action cannot be undone.",
            isPresented: $showConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Wipe", role: .destructive) {
                api.sendCommandDevice(deviceId: deviceId, command: "WipeDevice") { success, message in
                    self.alertMessage = message
                    self.alertTitle = success ? "Done" : "Error"
                    self.showAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

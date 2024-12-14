import SwiftUI

struct MobileDevicesView: View {
    @ObservedObject var api: JamfAPI
    @Binding var isLoading: Bool  // Track loading state
    @State var searchText = ""
    @State var alphabetical = true

    var filteredDevices: [JamfMobileDevice] {
        let devices = searchText.isEmpty
            ? api.mobileDevices
            : api.mobileDevices.filter { device in
                device.name.localizedCaseInsensitiveContains(searchText)
            }
        return devices.sorted { alphabetical ? $0.name < $1.name : $0.name > $1.name }
    }

    var body: some View {
        NavigationStack {
            List(filteredDevices) { device in
                NavigationLink(
                    destination: MobileDeviceDetailView(
                        api: api, deviceId: device.id, deviceName: device.name)
                ) {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .font(.headline)
                            HStack {
                                Text(device.model)
                                    .font(.caption)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                
                                Text(device.supervised == "true" ? "COBO" : "BYOD")
                                    .font(.caption)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 5)
                                    .background(
                                        device.supervised == "true" ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Devices")
            .searchable(text: $searchText)
            .autocorrectionDisabled()
            .animation(.default, value: searchText)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        alphabetical.toggle()
                    } label: {
                        Image(systemName: alphabetical ? "arrow.down.square" : "arrow.up.square")
                    }
                }
            }
        }
        .refreshable {
            fetchDevices()
        }
    }

    private func fetchDevices() {
        isLoading = true
        api.fetchMobileDevices()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false  // Hide loading spinner after API call
        }
    }
}

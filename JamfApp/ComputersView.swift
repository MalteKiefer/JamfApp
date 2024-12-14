import SwiftUI

struct ComputersView: View {
    @ObservedObject var api: JamfAPI
    @Binding var isLoading: Bool
    @State private var searchText = ""
    @State private var alphabetical = true
    @State private var sortedComputers: [JamfDevice] = []

    var body: some View {
        NavigationStack {
            List(sortedComputers) { computer in
                NavigationLink(
                    destination: ComputerDetailView(api: api, deviceId: computer.id)
                ) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(computer.name)
                                .font(.headline)
                            Text(computer.model)
                                .font(.caption)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            ManagedStatusView(isManaged: computer.managed == "true")
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Computers")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        alphabetical.toggle()
                        updateSortedComputers()
                    } label: {
                        Image(systemName: alphabetical ? "arrow.down.square" : "arrow.up.square")
                    }
                }
            }
            .refreshable {
                fetchComputers()
            }
        }
        .onAppear {
            updateSortedComputers()
        }
        .onChange(of: searchText) { _ in
            updateSortedComputers()
        }
    }

    private func fetchComputers() {
        isLoading = true
        api.fetchComputers()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false  // Hide loading spinner after API call
        }
    }


    private func updateSortedComputers() {
        sortedComputers = api.computers
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { alphabetical ? $0.name < $1.name : $0.name > $1.name }
    }
}

struct ManagedStatusView: View {
    let isManaged: Bool

    var body: some View {
        Text(isManaged ? "Managed" : "Non Managed")
            .font(.caption)
            .padding(.horizontal, 13)
            .padding(.vertical, 5)
            .background(isManaged ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .clipShape(Capsule())
    }
}

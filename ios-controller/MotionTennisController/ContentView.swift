import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ControllerViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Controller") {
                    Picker("Role", selection: $viewModel.selectedRole) {
                        ForEach(ControllerRole.allCases) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    .disabled(viewModel.isStreaming)

                    LabeledContent("State", value: viewModel.phase.label)
                    LabeledContent("Calibrated", value: viewModel.isCalibrated ? "Yes" : "No")
                }

                BLEDiscoverySection(ble: viewModel.ble, startScanning: viewModel.startScanning)

                Section("Motion") {
                    Button("Calibrate neutral grip", action: viewModel.calibrate)
                        .disabled(viewModel.isStreaming)

                    if viewModel.isStreaming {
                        Button("Stop streaming", role: .destructive, action: viewModel.stopStreaming)
                    } else {
                        Button("Start streaming", action: viewModel.startStreaming)
                            .disabled(!viewModel.canStartStreaming)
                    }
                }

                Section("Diagnostics") {
                    LabeledContent("Generated", value: "\(viewModel.generatedSampleCount)")
                    LabeledContent("Last sequence", value: viewModel.lastSequence.map(String.init) ?? "—")
                    LabeledContent("Sample rate", value: String(format: "%.1f Hz", viewModel.observedSampleRate))
                    LabeledContent("Dropped/backpressured", value: "\(viewModel.ble.droppedFrameCount)")
                    LabeledContent("Frames handed to BLE", value: "\(viewModel.ble.completedFrameCount)")
                }

                if let error = viewModel.lastError {
                    Section("Last error") { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Motion Tennis")
        }
    }
}

private struct BLEDiscoverySection: View {
    @ObservedObject var ble: BLEManager
    let startScanning: () -> Void

    var body: some View {
        Section("Bluetooth") {
            Button("Scan for boards", action: startScanning)

            ForEach(ble.discoveredPeripherals) { peripheral in
                Button {
                    ble.connect(to: peripheral.id)
                } label: {
                    HStack {
                        Text(peripheral.name)
                        Spacer()
                        Text("\(peripheral.rssi) dBm").foregroundStyle(.secondary)
                    }
                }
            }

            if !ble.writableCharacteristics.isEmpty {
                Text("Select the characteristic verified for phone-to-board writes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(ble.writableCharacteristics) { characteristic in
                    Button(characteristic.label) {
                        ble.selectWriteCharacteristic(characteristic.id)
                    }
                    .tint(ble.selectedCharacteristicID == characteristic.id ? .green : .accentColor)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

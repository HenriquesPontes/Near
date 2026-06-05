import SwiftUI

struct AboutNearView: View {
    var body: some View {
        List {
            Section(header: Text("Mission")) {
                Text(
                    LocalizedStringKey(
                        """
                        The app, called NearbyGlasses, has one sole purpose: Look for smart glasses nearby and warn you.

                        This app notifies you when smart glasses are nearby. It uses company identifiers in the Bluetooth data sent out by these. Therefore, there likely are false positives (e.g. from VR headsets). Hence, please proceed with caution when approaching a person nearby wearing glasses. They might just be regular glasses, despite this app’s warning.

                        The app’s author Henriques Pontes takes no liability whatsoever for this app nor it’s functionality. Use at your own risk. By technical design, detecting Bluetooth Low Energy (BLE) devices might sometimes just not work as expected.
                        """
                    )
                )
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.secondary)
                .lineSpacing(5)
            }

            Section(header: Text("⚠ DO NOT HARASS ANYONE ⚠")) {
                Text(
                    LocalizedStringKey(
                        """
                        Any form of harassment or confrontation based on the suspicion of covert surveillance is unacceptable and may be illegal. *NearbyGlasses* relies on Bluetooth Low Energy (BLE) heuristics that can produce false positives such as mistaking a VR headset or smartwatch for smart glasses. This app is designed solely for personal situational awareness. Always act responsibly and familiarize yourself with your local privacy laws.

                        Please do not act rashly. Think before you act upon any messages (not only from this app).
                        """
                    )
                )
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
                .lineSpacing(5)
            }
            Section(header: Text("Legal")) {
                Link("Privacy Policy", destination: URL(string: "https://henriquespontes.com/privacy")!)
                    .foregroundColor(.blue)
                Link("Terms of Service", destination: URL(string: "https://henriquespontes.com/terms")!)
                    .foregroundColor(.blue)
                Link("End User License Agreement (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .foregroundColor(.blue)
            }
            
            Section {
                Text("Copyright © 2026 Henriques Pontes. All rights reserved.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About NearbyGlasses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AboutNearView()
    }
}

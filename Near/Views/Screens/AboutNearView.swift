import SwiftUI

struct AboutNearView: View {
    var body: some View {
        List {
            Section(header: Text("Mission")) {
                Text("""
The app, called Near, has one sole purpose: Look for smart glasses nearby and warn you.

This app notifies you when smart glasses are nearby. It uses company identifiers in the Bluetooth data sent out by these. Therefore, there likely are false positives (e.g. from VR headsets). Hence, please proceed with caution when approaching a person nearby wearing glasses. They might just be regular glasses, despite this app’s warning.

The app’s author Henriques Pontes takes no liability whatsoever for this app nor it’s functionality. Use at your own risk. By technical design, detecting Bluetooth LE devices might sometimes just not work as expected.
""")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.secondary)
                .lineSpacing(5)
            }
            
            Section(header: Text("⚠ DO NOT HARASS ANYONE ⚠")) {
                Text("""
HARASSING someone because you think they are wearing a covert surveillance device can be a criminal offence. It may even be a more serious offence than using such a device. Please seek legal advice regarding your local laws on this matter.

Use with extreme caution! As stated before: There is no guarantee that detected smart glasses are really nearby. It might be another device looking technically (on the BLE adv level) similar to smart glasses.

Please do not act rashly. Think before you act upon any messages (not only from this app).
""")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
                .lineSpacing(5)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About Near")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AboutNearView()
    }
}

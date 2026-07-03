import SwiftUI

enum OnboardingStep: Int, Hashable {
    case features = 1
}

struct OnboardingView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeOnboardingView(path: $path)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .features:
                        NotificationsOnboardingView()
                    }
                }
        }
    }
}

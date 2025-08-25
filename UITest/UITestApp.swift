import SwiftUI

struct HomeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let rootVC = ViewController()
        
        let navigationController = UINavigationController(rootViewController: rootVC)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}

@main
struct UITestApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

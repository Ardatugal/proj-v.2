import UIKit
import Photos

class ViewController: UIViewController {

    let progressBar = UIProgressView(progressViewStyle: .default)
    let progressLabel = UILabel()
    let groupCountLabel = UILabel()

    let scanner = PhotoScanner()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupUI()

        checkPhotoLibraryPermission()
    }

    func setupUI() {
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        groupCountLabel.translatesAutoresizingMaskIntoConstraints = false
        groupCountLabel.numberOfLines = 0

        view.addSubview(progressBar)
        view.addSubview(progressLabel)
        view.addSubview(groupCountLabel)

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            groupCountLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 30),
            groupCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            groupCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        progressBar.progress = 0.0
        progressLabel.text = "Scanning photos: 0% (0/0)"
        groupCountLabel.text = ""
    }

    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            startScanning()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.startScanning()
                    } else {
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        default:
            showPermissionDeniedAlert()
        }
    }

    func showPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Permission Denied",
                                      message: "Please allow photo library access in Settings to scan photos.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func startScanning() {
        scanner.onProgressUpdate = { [weak self] processed, total, groupCounts in
            guard let self = self else { return }
            let percent = total == 0 ? 0 : Float(processed) / Float(total)
            self.progressBar.progress = percent
            self.progressLabel.text = String(format: "Scanning photos: %.0f%% (%d/%d)", percent * 100, processed, total)

            // Update group counts display
            var groupText = "Group Counts:\n"
            for group in PhotoGroup.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
                if let count = groupCounts[group], count > 0 {
                    groupText += "\(group.rawValue.capitalized): \(count)\n"
                }
            }
            self.groupCountLabel.text = groupText
        }

        scanner.onScanComplete = {
            print("Scan complete!")
        }

        scanner.startScan()
    }
}

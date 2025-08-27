import UIKit
import Photos

class ViewController: UIViewController {

    let progressBar = UIProgressView(progressViewStyle: .default)
    let progressLabel = UILabel()
    let groupCountLabel = UILabel()
    let doneButton = UIButton(type: .system)

    let scanner = PhotoScanner()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupUI()
        setupDoneButton()

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

    func setupDoneButton() {
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        doneButton.isHidden = true

        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: groupCountLabel.bottomAnchor, constant: 20),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            doneButton.widthAnchor.constraint(equalToConstant: 120)
        ])

        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
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
            DispatchQueue.main.async {
                self.progressBar.progress = percent
                self.progressLabel.text = String(format: "Scanning photos: %.0f%% (%d/%d)", percent * 100, processed, total)

                var groupText = "Group Counts:\n"
                for group in PhotoGroup.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
                    if let count = groupCounts[group], count > 0 {
                        groupText += "\(group.rawValue.capitalized): \(count)\n"
                    }
                }
                self.groupCountLabel.text = groupText
            }
        }

        scanner.onScanComplete = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.progressLabel.text = "Scan complete!"
                self.doneButton.isHidden = false
            }
        }

        scanner.startScan()
    }

    @objc func doneButtonTapped() {
        let homeVC = HomeViewController()
        if let navController = self.navigationController {
            navController.pushViewController(homeVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: homeVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true)
        }
    }
}


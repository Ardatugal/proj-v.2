import UIKit
import SwiftUI
import Photos

class HomeViewController: UIViewController {

    var collectionView: UICollectionView!
    private var photoScanner = PhotoScanner()

    private var groupCounts: [PhotoGroup: Int] = [:]

    // Groups that have at least one photo (excluding empty ones)
    var nonEmptyGroups: [PhotoGroup] = []

    // UI elements to show loading state
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Scanning photos..."
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo Groups"

        setupCollectionView()
        setupLoadingUI()
        setupScanningCallbacks()

        checkPhotoLibraryPermission()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.register(GroupCell.self, forCellWithReuseIdentifier: "GroupCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.isHidden = true
        view.addSubview(collectionView)
    }

    private func setupLoadingUI() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
    
    private func setupScanningCallbacks() {
        photoScanner.onProgressUpdate = { [weak self] processed, total, receivedGroupCounts in
            guard let self = self else { return }

            // Update local, main-thread data properties with the data from the background thread
            self.groupCounts = receivedGroupCounts
            self.nonEmptyGroups = receivedGroupCounts.filter { $0.value > 0 }.map { $0.key }
            
            if let otherCount = receivedGroupCounts[.other], otherCount > 0, !self.nonEmptyGroups.contains(.other) {
                self.nonEmptyGroups.append(.other)
            }
            self.collectionView.reloadData()
        }

        photoScanner.onScanComplete = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.loadingLabel.isHidden = true
                self.collectionView.isHidden = false
            }
        }
    }
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            self.photoScanner.startScan()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.photoScanner.startScan()
                    } else {
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        default:
            showPermissionDeniedAlert()
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Permission Denied",
                                      message: "Please allow photo library access in Settings to scan photos.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nonEmptyGroups.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let group = nonEmptyGroups[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCell
        
        // now accessing the local, thread-safe data property
        cell.configure(with: group, count: groupCounts[group] ?? 0)
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let group = nonEmptyGroups[indexPath.item]
        let assets = photoScanner.assetsForGroup(group)

        let groupDetailView = GroupDetailView(group: group, assets: assets)
        let hostingVC = UIHostingController(rootView: groupDetailView)
        hostingVC.title = group.rawValue.capitalized
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}

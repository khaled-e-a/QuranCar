import UIKit
import GoogleMobileAds

class BannerAdView: UIViewController, BannerViewDelegate {

  private var bannerView: BannerView!
  private var adInspectorButton: UIBarButtonItem!

  private var isMobileAdsStartCalled = false
  var isViewDidAppearCalled = false  // Changed from private to internal
  private var isSDKInitialized = false  // New flag to track SDK initialization

  override func viewDidLoad() {
    super.viewDidLoad()
    print("viewDidLoad called")

    // Create and configure banner view
    bannerView = BannerView()
    bannerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bannerView)

    // Set up constraints
    NSLayoutConstraint.activate([
      bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])

    adInspectorButton = UIBarButtonItem(
      title: "Ad Inspector",
      style: .plain,
      target: self,
      action: #selector(adInspectorTapped)
    )

    // Add buttons to navigation bar
    navigationItem.rightBarButtonItems = [adInspectorButton]

    // Replace this ad unit ID with your own ad unit ID.
    // bannerView.adUnitID = "ca-app-pub-4062866077093549/9858278336"
    bannerView.adUnitID = "/1092393/320x50_QuranCar:DriveandMemorize"
    bannerView.rootViewController = self
    bannerView.delegate = self

    // Initialize SDK immediately instead of async
    startGoogleMobileAdsSDK()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    print("viewDidAppear called")
    isViewDidAppearCalled = true
    print("isViewDidAppearCalled set to true")

    // Load ad if SDK is initialized
    if isSDKInitialized {
      print("SDK already initialized, loading banner ad")
      loadBannerAd()
    } else {
      print("SDK not yet initialized, waiting for initialization")
    }
  }

  override func viewWillTransition(
    to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
  ) {
    coordinator.animate(alongsideTransition: { _ in
      self.loadBannerAd()
    })
  }

  /// Handle ad inspector launch.
  @objc private func adInspectorTapped(_ sender: UIBarButtonItem) {
    Task {
      do {
        try await MobileAds.shared.presentAdInspector(from: self)
      } catch {
        // There was an issue and the inspector was not displayed.
        let alertController = UIAlertController(
          title: error.localizedDescription, message: "Please try again later.",
          preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertController, animated: true)
      }
    }
  }

  private func startGoogleMobileAdsSDK() {
    print("startGoogleMobileAdsSDK called")
    guard !isMobileAdsStartCalled else {
      print("SDK already started, returning")
      return
    }

    isMobileAdsStartCalled = true
    print("isMobileAdsStartCalled set to true")

    // Initialize the Google Mobile Ads SDK.
    MobileAds.shared.start { [weak self] status in
      guard let self = self else { return }
      print("Google Mobile Ads SDK initialized. Status: \(status.adapterStatusesByClassName)")
      self.isSDKInitialized = true
      print("isViewDidAppearCalled: \(self.isViewDidAppearCalled)")

      // Load ad if viewDidAppear has been called
      if self.isViewDidAppearCalled {
        print("loading banner ad")
        self.loadBannerAd()
      } else {
        print("viewDidAppear not yet called, waiting for it")
      }
    }
  }

  func loadBannerAd() {
    let viewWidth = view.frame.inset(by: view.safeAreaInsets).width

    // Here the current interface orientation is used. Use
    // GADLandscapeAnchoredAdaptiveBannerAdSizeWithWidth or
    // GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth if you prefer to load an ad of a
    // particular orientation
    bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)

    print("bannerView.adSize: \(bannerView.adSize)")

    let request = Request()

    print("request: \(request)")

    bannerView.load(request)

    print("loaded banner ad")

  }

  // MARK: - GADBannerViewDelegate methods

  func bannerViewDidReceiveAd(_ bannerView: BannerView) {
    print(#function)
  }

  func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
    print(#function + ": " + error.localizedDescription)
  }

  func bannerViewDidRecordClick(_ bannerView: BannerView) {
    print(#function)
  }

  func bannerViewDidRecordImpression(_ bannerView: BannerView) {
    print(#function)
  }

  func bannerViewWillPresentScreen(_ bannerView: BannerView) {
    print(#function)
  }

  func bannerViewWillDismissScreen(_ bannerView: BannerView) {
    print(#function)
  }

  func bannerViewDidDismissScreen(_ bannerView: BannerView) {
    print(#function)
  }

}
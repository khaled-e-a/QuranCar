import SwiftUI
import GoogleMobileAds

class BannerAdView: UIViewController, BannerViewDelegate {
    private var bannerView: BannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create banner view programmatically
        bannerView = BannerView()
        bannerView.delegate = self
        bannerView.adUnitID = "ca-app-pub-4062866077093549/9858278336"
        bannerView.rootViewController = self

        // Add banner view to view hierarchy
        view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        bannerView.load(Request())
    }

    // MARK: - GADBannerViewDelegate

    // Called when an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: BannerView) {
        print(#function)
    }

    // Called when an ad request failed.
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("\(#function): \(error.localizedDescription)")
    }

    // Called just before presenting the user a full screen view, such as a browser, in response to
    // clicking on an ad.
    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        print(#function)
    }

    // Called just before dismissing a full screen view.
    func bannerViewWillDismissScreen(_ bannerView: BannerView) {
        print(#function)
    }

    // Called just after dismissing a full screen view.
    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        print(#function)
    }

    // Called just before the application will background or exit because the user clicked on an
    // ad that will launch another application (such as the App Store).
    func adViewWillLeaveApplication(_ bannerView: BannerView) {
        print(#function)
    }
}
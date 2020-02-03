//
//  LandingViewController
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import UIKit

class LandingViewController: UIViewController, Navigating {
    static var navigableItem: NavigableItem = .landing

    @IBOutlet weak private var subtitleLabel: UILabel!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var getStartedButton: UIButton!
    @IBOutlet weak private var learnMoreButton: UIButton!
    @IBOutlet weak private var imageView: UIImageView!

    init() {
        super.init(nibName: String(describing: Self.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        getStartedButton.cornerRadius = getStartedButton.frame.height/10
    }

    @IBAction func getStarted() {
        navigate(to: .login)
    }

    @IBAction func learnMore() {
        navigate(to: .carousel)
    }

    private func setupView() {
        titleLabel.text = LocalizedString.landingTitle.value
        subtitleLabel.text = LocalizedString.landingSubtitle.value
        getStartedButton.setTitle(LocalizedString.getStarted.value, for: .normal)
        getStartedButton.setBackgroundImage(UIImage.image(with: UIColor.custom(.blue80)), for: .highlighted)
        learnMoreButton.setTitle(LocalizedString.learnMore.value, for: .normal)
        imageView.image = UIImage(named: "logo")
    }
}

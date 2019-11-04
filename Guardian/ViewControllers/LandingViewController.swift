//
//  LandingViewController
//  FirefoxPrivateNetworkVPN
//
//  Copyright © 2019 Mozilla Corporation. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController, Navigating {
    static var navigableItem: NavigableItem = .landing

    @IBOutlet weak var nameLabel: UILabel!

    init() {
        super.init(nibName: String(describing: Self.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStrings()
    }

    private func setStrings() {
        nameLabel.accessibilityLabel = "LandingViewController_Name"
        nameLabel.text = NSLocalizedString(nameLabel.accessibilityLabel!, comment: "")
    }

    @IBAction func tapped(_ sender: UIButton) {
        navigate(to: .home)
    }
}

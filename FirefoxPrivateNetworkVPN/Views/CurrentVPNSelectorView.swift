//
//  CurrentVPNSelectorView
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import UIKit
import RxSwift

class CurrentVPNSelectorView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var countryFlagImageView: UIImageView!
    @IBOutlet var countryTitleLabel: UILabel!

    private let disposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        Bundle.main.loadNibNamed(String(describing: CurrentVPNSelectorView.self), owner: self, options: nil)
        view.frame = bounds
        addSubview(view)
        DependencyFactory.sharedFactory.tunnelManager.cityChangedEvent
            .map { Optional($0) }
            .startWith(VPNCity.fetchFromUserDefaults())
            .compactMap { $0 }
            .subscribe { cityEvent in
                guard let city = cityEvent.element?.name else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.countryTitleLabel.text = city
                    if let countryCode = DependencyFactory.sharedFactory.accountManager.countryCodeForCity(city) {
                        self?.countryFlagImageView.image = UIImage(named: "flag_\(countryCode)")
                    } else {
                        self?.countryFlagImageView.image = nil
                    }
                }
        }.disposed(by: disposeBag)
    }
}

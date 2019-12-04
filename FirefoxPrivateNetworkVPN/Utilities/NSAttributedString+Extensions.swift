//
//  NSAttributedString+Extensions
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import UIKit

extension NSAttributedString {
    static func formattedError(_ error: GuardianError, canTryAgain: Bool = true) -> NSAttributedString {
        let message = NSMutableAttributedString(string: error.description)
        if canTryAgain {
            let tryAgainMessage = NSAttributedString(string: LocalizedString.toastTryAgain.value, attributes: [
                .font: UIFont.custom(.interSemiBold, size: 13),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ])
            message.append(NSAttributedString(string: " "))
            message.append(tryAgainMessage)
        }
        return message
    }
}

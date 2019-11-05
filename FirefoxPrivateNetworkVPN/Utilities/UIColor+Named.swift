//
//  UIColor+Named
//  FirefoxPrivateNetworkVPN
//
//  Copyright © 2019 Mozilla Corporation. All rights reserved.
//

import UIKit

enum CustomColor: String {
    case blue50 = "custom_blue50"
    case green50 = "custom_green50"
    case grey5 = "custom_grey5"
    case grey10 = "custom_grey10"
    case grey20 = "custom_grey20"
    case grey30 = "custom_grey30"
    case grey40 = "custom_grey40"
    case grey50 = "custom_grey50"
    case launch = "custom_launch"
    case purple90 = "custom_purple90"
    case red40  = "custom_red40"
    case red50 = "custom_red50"
    case yellow50 = "custom_yellow50"
}

extension UIColor {
    static func custom(_ color: CustomColor) -> UIColor {
        // Must correspond with named colors in Assets.xcassets
        return UIColor(named: color.rawValue)!
    }
}

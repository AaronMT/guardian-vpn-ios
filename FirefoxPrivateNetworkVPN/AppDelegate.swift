//
//  AppDelegate
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var dependencyFactory: DependencyProviding?

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        dependencyFactory = DependencyFactory.sharedFactory

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        let firstViewController = dependencyFactory?.navigationCoordinator.firstViewController
        window.rootViewController = firstViewController
        window.makeKeyAndVisible()

        return true
    }
}

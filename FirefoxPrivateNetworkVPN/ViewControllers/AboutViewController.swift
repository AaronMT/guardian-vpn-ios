//
//  AboutViewController
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import UIKit

class AboutViewController: UIViewController, Navigating {
    static var navigableItem: NavigableItem = .devices

    @IBOutlet weak var tableView: UITableView!

    private var dataSource: AboutDataSourceAndDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()

        dataSource = AboutDataSourceAndDelegate(tableView: tableView)
        tableView.tableFooterView = UIView()
    }

    @objc func goBack() {
        navigate(to: .settings)
    }

    func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.title = LocalizedString.aboutTitle.value
        navigationItem.titleView?.tintColor = UIColor.custom(.grey50)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_backChevron"), style: .plain, target: self, action: #selector(goBack))
        navigationItem.leftBarButtonItem?.tintColor = UIColor.custom(.grey40)
    }
}

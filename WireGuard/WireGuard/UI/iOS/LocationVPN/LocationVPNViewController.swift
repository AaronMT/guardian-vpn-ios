// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit

class LocationVPNViewController: UIViewController {

    @IBOutlet var tableView: UITableView!

    private let userManager = UserManager.sharedManager
    private var dataSource: LocationsVPNDataSourceAndDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        styleViews()
        userManager.retrieveVPNServers { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                do {
                    let countries = try result.get()
                    self.dataSource = LocationsVPNDataSourceAndDelegate(countries: countries, tableView: self.tableView)
                    self.tableView.reloadData()
                } catch {
                    print(error)
                }
            }
        }
    }

    func styleViews() {
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = UIColor.backgroundOffWhite
    }

    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Close"), style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem?.tintColor = UIColor.guardianBlack
        navigationItem.title = "Connection"
    }

    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

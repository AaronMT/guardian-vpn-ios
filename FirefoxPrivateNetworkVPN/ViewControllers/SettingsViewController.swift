//
//  SettingsViewController
//  FirefoxPrivateNetworkVPN
//
//  Copyright © 2019 Mozilla Corporation. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, Navigating {
    static var navigableItem: NavigableItem = .settings

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton!

    private var dataSource: SettingsDataSourceAndDelegate?

    init() {
        super.init(nibName: String(describing: Self.self), bundle: nil)
        setupTabBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStrings()

        dataSource = SettingsDataSourceAndDelegate(tableView: tableView)
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    @IBAction func signOut() {
        DependencyFactory.sharedFactory.tunnelManager.stop()
        DependencyFactory.sharedFactory.accountManager.logout { [weak self] result in
            self?.navigate(to: .landing, context: ["Result": result])
        }
    }

    private func setupTabBar() {
        let tag: TabTag = .settings
        tabBarItem = UITabBarItem(title: LocalizedString.settingsTabName.value, image: UIImage(named: "tab_settings"), tag: tag)
    }

    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationItem.backBarButtonItem = nil
    }

    private func setStrings() {
        signOutButton.setTitle(LocalizedString.settingsSignOut.value, for: .normal)
    }
}

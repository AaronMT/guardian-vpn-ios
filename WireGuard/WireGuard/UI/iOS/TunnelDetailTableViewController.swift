// SPDX-License-Identifier: MIT
// Copyright © 2018 WireGuard LLC. All Rights Reserved.

import UIKit

// MARK: TunnelDetailTableViewController

class TunnelDetailTableViewController: UITableViewController {

    let interfaceFields: [TunnelViewModel.InterfaceField] = [
        .name, .publicKey, .addresses,
	.listenPort, .mtu, .dns
    ]

    let peerFields: [TunnelViewModel.PeerField] = [
        .publicKey, .preSharedKey, .endpoint,
        .allowedIPs, .persistentKeepAlive
    ]

    let tunnelsManager: TunnelsManager
    let tunnel: TunnelContainer
    var tunnelViewModel: TunnelViewModel

    init(tunnelsManager tm: TunnelsManager, tunnel t: TunnelContainer) {
        tunnelsManager = tm
        tunnel = t
        tunnelViewModel = TunnelViewModel(tunnelConfiguration: t.tunnelConfiguration())
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = tunnelViewModel.interfaceData[.name]
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))

        self.tableView.rowHeight = 44
        self.tableView.allowsSelection = false
        self.tableView.register(TunnelDetailTableViewStatusCell.self, forCellReuseIdentifier: TunnelDetailTableViewStatusCell.id)
        self.tableView.register(TunnelDetailTableViewKeyValueCell.self, forCellReuseIdentifier: TunnelDetailTableViewKeyValueCell.id)
        self.tableView.register(TunnelDetailTableViewButtonCell.self, forCellReuseIdentifier: TunnelDetailTableViewButtonCell.id)
    }

    @objc func editTapped() {
        let editVC = TunnelEditTableViewController(tunnelsManager: tunnelsManager, tunnel: tunnel)
        editVC.delegate = self
        let editNC = UINavigationController(rootViewController: editVC)
        editNC.modalPresentationStyle = .formSheet
        present(editNC, animated: true)
    }

    func showErrorAlert(title: String, message: String) {
        let okAction = UIAlertAction(title: "Ok", style: .default)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(okAction)

        self.present(alert, animated: true, completion: nil)
    }

    func showConfirmationAlert(message: String, buttonTitle: String, from sourceView: UIView,
                               onConfirmed: @escaping (() -> Void)) {
        let destroyAction = UIAlertAction(title: buttonTitle, style: .destructive) { (action) in
            onConfirmed()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let alert = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
        alert.addAction(destroyAction)
        alert.addAction(cancelAction)

        // popoverPresentationController will be nil on iPhone and non-nil on iPad
        alert.popoverPresentationController?.sourceView = sourceView

        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: TunnelEditTableViewControllerDelegate

extension TunnelDetailTableViewController: TunnelEditTableViewControllerDelegate {
    func tunnelSaved(tunnel: TunnelContainer) {
        tunnelViewModel = TunnelViewModel(tunnelConfiguration: tunnel.tunnelConfiguration())
        self.title = tunnel.name
        self.tableView.reloadData()
    }
    func tunnelEditingCancelled() {
        // Nothing to do
    }
}

// MARK: UITableViewDataSource

extension TunnelDetailTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3 + tunnelViewModel.peersData.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let interfaceData = tunnelViewModel.interfaceData
        let numberOfPeerSections = tunnelViewModel.peersData.count

        if (section == 0) {
            // Status
            return 1
        } else if (section == 1) {
            // Interface
            return interfaceData.filterFieldsWithValueOrControl(interfaceFields: interfaceFields).count
        } else if ((numberOfPeerSections > 0) && (section < (2 + numberOfPeerSections))) {
            // Peer
            let peerData = tunnelViewModel.peersData[section - 2]
            return peerData.filterFieldsWithValueOrControl(peerFields: peerFields).count
        } else {
            // Delete tunnel
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let numberOfPeerSections = tunnelViewModel.peersData.count

        if (section == 0) {
            // Status
            return "Status"
        } else if (section == 1) {
            // Interface
	    return "Interface"
        } else if ((numberOfPeerSections > 0) && (section < (2 + numberOfPeerSections))) {
            // Peer
            return "Peer"
        } else {
            // Delete tunnel
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let interfaceData = tunnelViewModel.interfaceData
        let numberOfPeerSections = tunnelViewModel.peersData.count

        let section = indexPath.section
        let row = indexPath.row

        if (section == 0) {
            // Status
            let cell = tableView.dequeueReusableCell(withIdentifier: TunnelDetailTableViewStatusCell.id, for: indexPath) as! TunnelDetailTableViewStatusCell
            cell.tunnel = self.tunnel
            cell.onSwitchToggled = { [weak self] isOn in
                guard let s = self else { return }
                if (isOn) {
                    s.tunnelsManager.startActivation(of: s.tunnel) { [weak self] error in
                        if let error = error {
                            switch (error) {
                            case TunnelActivationError.noEndpoint:
                                self?.showErrorAlert(title: "Endpoint missing", message: "There must be at least one peer with an endpoint")
                            case TunnelActivationError.dnsResolutionFailed:
                                self?.showErrorAlert(title: "DNS Failure", message: "One or more endpoint domains could not be resolved")
                            default:
                                self?.showErrorAlert(title: "Internal error", message: "The tunnel could not be activated")
                            }
                        }
                    }
                } else {
                    s.tunnelsManager.startDeactivation(of: s.tunnel) { error in
                        print("Error while deactivating: \(String(describing: error))")
                    }
                }
            }
            return cell
        } else if (section == 1) {
            // Interface
            let field = interfaceData.filterFieldsWithValueOrControl(interfaceFields: interfaceFields)[row]
            let cell = tableView.dequeueReusableCell(withIdentifier: TunnelDetailTableViewKeyValueCell.id, for: indexPath) as! TunnelDetailTableViewKeyValueCell
            // Set key and value
            cell.key = field.rawValue
            cell.value = interfaceData[field]
            if (field != .publicKey) {
                cell.detailTextLabel?.allowsDefaultTighteningForTruncation = true
                cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
                cell.detailTextLabel?.minimumScaleFactor = 0.85
            }
            return cell
        } else if ((numberOfPeerSections > 0) && (section < (2 + numberOfPeerSections))) {
            // Peer
            let peerData = tunnelViewModel.peersData[section - 2]
            let field = peerData.filterFieldsWithValueOrControl(peerFields: peerFields)[row]

            let cell = tableView.dequeueReusableCell(withIdentifier: TunnelDetailTableViewKeyValueCell.id, for: indexPath) as! TunnelDetailTableViewKeyValueCell
            // Set key and value
            cell.key = field.rawValue
            cell.value = peerData[field]
            if (field != .publicKey && field != .preSharedKey) {
                cell.detailTextLabel?.allowsDefaultTighteningForTruncation = true
                cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
                cell.detailTextLabel?.minimumScaleFactor = 0.85
            }

            return cell
        } else {
            assert(section == (2 + numberOfPeerSections))
            // Delete configuration
            let cell = tableView.dequeueReusableCell(withIdentifier: TunnelDetailTableViewButtonCell.id, for: indexPath) as! TunnelDetailTableViewButtonCell
            cell.buttonText = "Delete tunnel"
            cell.onTapped = { [weak self] in
                guard let s = self else { return }
                s.tunnelsManager.remove(tunnel: s.tunnel) { (error) in
                    if (error != nil) {
                        print("Error removing tunnel: \(String(describing: error))")
                        return
                    }
                    s.showConfirmationAlert(message: "Delete this tunnel?", buttonTitle: "Delete", from: cell) { [weak s] in
                        s?.navigationController?.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
            return cell
        }
    }
}

class TunnelDetailTableViewStatusCell: UITableViewCell {
    static let id: String = "TunnelDetailTableViewStatusCell"

    var tunnel: TunnelContainer? {
        didSet(value) {
            update(from: tunnel?.status)
            statusObservervationToken = tunnel?.observe(\.status) { [weak self] (tunnel, _) in
                self?.update(from: tunnel.status)
            }
        }
    }
    var isSwitchInteractionEnabled: Bool {
        get { return statusSwitch.isUserInteractionEnabled }
        set(value) { statusSwitch.isUserInteractionEnabled = value }
    }
    var onSwitchToggled: ((Bool) -> Void)? = nil
    private var isOnSwitchToggledHandlerEnabled: Bool = true

    let statusSwitch: UISwitch
    private var statusObservervationToken: AnyObject? = nil

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        statusSwitch = UISwitch()
        super.init(style: .default, reuseIdentifier: TunnelDetailTableViewKeyValueCell.id)
        accessoryView = statusSwitch

        statusSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
    }

    @objc func switchToggled() {
        if (isOnSwitchToggledHandlerEnabled) {
            onSwitchToggled?(statusSwitch.isOn)
        }
    }

    private func update(from status: TunnelStatus?) {
        guard let status = status else {
            reset()
            return
        }
        let text: String
        switch (status) {
        case .inactive:
            text = "Inactive"
        case .activating:
            text = "Activating"
        case .active:
            text = "Active"
        case .deactivating:
            text = "Deactivating"
        case .reasserting:
            text = "Reactivating"
        case .resolvingEndpointDomains:
            text = "Resolving domains"
        case .restarting:
            text = "Restarting"
        }
        textLabel?.text = text
        DispatchQueue.main.async { [weak statusSwitch] in
            guard let statusSwitch = statusSwitch else { return }
            statusSwitch.isOn = !(status == .deactivating || status == .inactive)
            statusSwitch.isUserInteractionEnabled = (status == .inactive || status == .active)
        }
        textLabel?.textColor = (status == .active || status == .inactive) ? UIColor.black : UIColor.gray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reset() {
        textLabel?.text = "Invalid"
        statusSwitch.isOn = false
        textLabel?.textColor = UIColor.gray
        statusSwitch.isUserInteractionEnabled = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
}

class TunnelDetailTableViewKeyValueCell: CopyableLabelTableViewCell {
    static let id: String = "TunnelDetailTableViewKeyValueCell"
    var key: String {
        get { return textLabel?.text ?? "" }
        set(value) { textLabel?.text = value }
    }
    var value: String {
        get { return detailTextLabel?.text ?? "" }
        set(value) { detailTextLabel?.text = value }
    }

    override var textToCopy: String? {
        return self.detailTextLabel?.text
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: TunnelDetailTableViewKeyValueCell.id)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        key = ""
        value = ""
    }
}

class TunnelDetailTableViewButtonCell: UITableViewCell {
    static let id: String = "TunnelDetailTableViewButtonCell"
    var buttonText: String {
        get { return button.title(for: .normal) ?? "" }
        set(value) { button.setTitle(value, for: .normal) }
    }
    var onTapped: (() -> Void)? = nil

    let button: UIButton

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        button = UIButton(type: .system)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            ])
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc func buttonTapped() {
        onTapped?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        buttonText = ""
        onTapped = nil
    }
}

// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit

class LocationsVPNDataSourceAndDelegate: NSObject {
    let countries: [VPNCountry]
    private var selectedIndexPath: IndexPath?

    init(countries: [VPNCountry], tableView: UITableView) {
        self.countries = countries
        super.init()
        setup(with: tableView)
    }

    private func setup(with tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self

        let nib = UINib.init(nibName: String(describing: CityVPNCell.self), bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: String(describing: CityVPNCell.self))

        let headerNib = UINib.init(nibName: String(describing: CountryVPNHeaderView.self), bundle: Bundle.main)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: String(describing: CountryVPNHeaderView.self))
    }
}

extension LocationsVPNDataSourceAndDelegate: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CityVPNCell.self), for: indexPath) as? CityVPNCell else {
            return UITableViewCell(frame: .zero)
        }

        let city = countries[indexPath.section].cities[indexPath.row]
        cell.cityLabel.text = city.name
        cell.radioImageView.image = (indexPath == selectedIndexPath) ? UIImage(named: "On") : UIImage(named: "Off")

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries[section].cities.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return countries.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath != selectedIndexPath {
            selectedIndexPath = indexPath
            tableView.reloadData()
        }
    }
}

extension LocationsVPNDataSourceAndDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: CountryVPNHeaderView.self)) as? CountryVPNHeaderView else {
            return nil
        }
        headerView.flagImageView.image = UIImage(named: countries[section].code.uppercased())
        headerView.nameLabel.text = countries[section].name

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CityVPNCell.height()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CountryVPNHeaderView.height()
    }
}

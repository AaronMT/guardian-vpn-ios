// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import Foundation

class ActivateOnDemandViewModel {
    enum OnDemandField {
        case onDemand
        case nonWiFiInterface
        case wiFiInterface
        case ssid

        var localizedUIString: String {
            switch self {
            case .onDemand:
                return tr("tunnelOnDemandKey")
            case .nonWiFiInterface:
                #if os(iOS)
                return tr("tunnelOnDemandCellular")
                #elseif os(macOS)
                return tr("tunnelOnDemandEthernet")
                #else
                #error("Unimplemented")
                #endif
            case .wiFiInterface: return tr("tunnelOnDemandWiFi")
            case .ssid: return tr("tunnelOnDemandSSIDsKey")
            }
        }
    }

    enum OnDemandSSIDOption {
        case anySSID
        case onlySpecificSSIDs
        case exceptSpecificSSIDs

        var localizedUIString: String {
            switch self {
            case .anySSID: return tr("tunnelOnDemandAnySSID")
            case .onlySpecificSSIDs: return tr("tunnelOnDemandOnlySelectedSSIDs")
            case .exceptSpecificSSIDs: return tr("tunnelOnDemandExceptSelectedSSIDs")
            }
        }
    }

    var isNonWiFiInterfaceEnabled = false
    var isWiFiInterfaceEnabled = false
    var selectedSSIDs = [String]()
    var ssidOption: OnDemandSSIDOption = .anySSID
}

extension ActivateOnDemandViewModel {
    convenience init(setting: ActivateOnDemandSetting) {
        if setting.isActivateOnDemandEnabled {
            self.init(option: setting.activateOnDemandOption)
        } else {
            self.init(option: .none)
        }
    }

    convenience init(option: ActivateOnDemandOption) {
        self.init()
        switch option {
        case .none:
            break
        case .wiFiInterfaceOnly(let onDemandSSIDOption):
            isWiFiInterfaceEnabled = true
            (ssidOption, selectedSSIDs) = ssidViewModel(from: onDemandSSIDOption)
        case .nonWiFiInterfaceOnly:
            isNonWiFiInterfaceEnabled = true
        case .anyInterface(let onDemandSSIDOption):
            isWiFiInterfaceEnabled = true
            isNonWiFiInterfaceEnabled = true
            (ssidOption, selectedSSIDs) = ssidViewModel(from: onDemandSSIDOption)
        }
    }

    func toOnDemandOption() -> ActivateOnDemandOption {
        switch (isWiFiInterfaceEnabled, isNonWiFiInterfaceEnabled) {
        case (false, false):
            return .none
        case (false, true):
            return .nonWiFiInterfaceOnly
        case (true, false):
            return .wiFiInterfaceOnly(toSSIDOption())
        case (true, true):
            return .anyInterface(toSSIDOption())
        }
    }
}

extension ActivateOnDemandViewModel {
    func isEnabled(field: OnDemandField) -> Bool {
        switch field {
        case .nonWiFiInterface:
            return isNonWiFiInterfaceEnabled
        case .wiFiInterface:
            return isWiFiInterfaceEnabled
        default:
            return false
        }
    }

    func setEnabled(field: OnDemandField, isEnabled: Bool) {
        switch field {
        case .nonWiFiInterface:
            isNonWiFiInterfaceEnabled = isEnabled
        case .wiFiInterface:
            isWiFiInterfaceEnabled = isEnabled
        default:
            break
        }
    }
}

extension ActivateOnDemandViewModel {
    var localizedInterfaceDescription: String {
        switch (isWiFiInterfaceEnabled, isNonWiFiInterfaceEnabled) {
        case (false, false):
            return tr("tunnelOnDemandOptionOff")
        case (true, false):
            return tr("tunnelOnDemandOptionWiFiOnly")
        case (false, true):
            #if os(iOS)
            return tr("tunnelOnDemandOptionCellularOnly")
            #elseif os(macOS)
            return tr("tunnelOnDemandOptionEthernetOnly")
            #else
            #error("Unimplemented")
            #endif
        case (true, true):
            #if os(iOS)
            return tr("tunnelOnDemandOptionWiFiOrCellular")
            #elseif os(macOS)
            return tr("tunnelOnDemandOptionWiFiOrEthernet")
            #else
            #error("Unimplemented")
            #endif
        }
    }
}

private extension ActivateOnDemandViewModel {
    func ssidViewModel(from ssidOption: ActivateOnDemandSSIDOption) -> (OnDemandSSIDOption, [String]) {
        switch ssidOption {
        case .anySSID:
            return (.anySSID, [])
        case .onlySpecificSSIDs(let ssids):
            return (.onlySpecificSSIDs, ssids)
        case .exceptSpecificSSIDs(let ssids):
            return (.exceptSpecificSSIDs, ssids)
        }
    }

    func toSSIDOption() -> ActivateOnDemandSSIDOption {
        switch ssidOption {
        case .anySSID:
            return .anySSID
        case .onlySpecificSSIDs:
            return .onlySpecificSSIDs(selectedSSIDs)
        case .exceptSpecificSSIDs:
            return .exceptSpecificSSIDs(selectedSSIDs)
        }
    }
}
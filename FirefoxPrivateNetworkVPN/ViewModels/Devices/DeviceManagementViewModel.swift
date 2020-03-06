//
//  DeviceManagementViewModel
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2020 Mozilla Corporation.
//

import RxSwift
import RxCocoa
import UIKit

class DeviceManagementViewModel {
    private let disposeBag = DisposeBag()
    private let account = { return DependencyFactory.sharedFactory.accountManager.account }()

    let trashTappedSubject = PublishSubject<Device>()
    let deletionConfirmedSubject = PublishSubject<Device>()
    let deletionSuccessSubject = PublishSubject<Void>()
    let deletionErrorSubject = PublishSubject<GuardianError>()

    var sortedDevices: [Device] {
        var devices = account?.user?.devices.sorted { return $0.isCurrentDevice && !$1.isCurrentDevice } ?? []

        if let account = account, !account.hasDeviceBeenAdded {
            devices.insert(Device.mock(name: UIDevice.current.name), at: 0)
        }
        return devices
    }

    init() {
        subscribeToDeletionConfirmedObservable()
    }

    private func subscribeToDeletionConfirmedObservable() {
        //swiftlint:disable:next trailing_closure
        deletionConfirmedSubject
            .flatMap { [unowned self] device -> Observable<Event<Void>> in
                guard let account = self.account else { return .never() }

                return account.remove(device: device).asObservable().materialize()
        }.subscribe(onNext: { [unowned self] event in
            guard let account = self.account else { return }

            switch event {
            case .next:
                if account.hasDeviceBeenAdded {
                    self.deletionSuccessSubject.onNext(())
                } else {
                    Logger.global?.log(message: "Attempting to add current device after removal")
                    account.addCurrentDevice { _ in
                        self.deletionSuccessSubject.onNext(())
                    }
                }
            case .error(let error):
                guard case GuardianError.couldNotRemoveDevice(let device) = error else { return }
                self.deletionErrorSubject.onNext(GuardianError.couldNotRemoveDevice(device))
            default: break
            }
        }).disposed(by: disposeBag)
    }

    private func formattedDeviceList(with devices: [Device]) -> [Device] {
        var devices = devices.sorted { return $0.isCurrentDevice && !$1.isCurrentDevice }

        if let account = account, !account.hasDeviceBeenAdded {
            devices.insert(Device.mock(name: UIDevice.current.name), at: 0)
        }
        return devices
    }
}

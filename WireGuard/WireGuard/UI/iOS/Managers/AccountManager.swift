// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import RxSwift

class AccountManager: AccountManaging {
    static let sharedManager = AccountManager()
    var credentialsStore = KeysStore.sharedStore

    private(set) var user: User?
    private(set) var token: String? // Save to user defaults
    private(set) var currentDevice: Device? // Save to user defaults
    private(set) var availableServers: [VPNCountry]?

    private let tokenUserDefaultsKey = "token"

    public var heartbeatFailedEvent = PublishSubject<Void>()

    private init() {
        token = UserDefaults.standard.string(forKey: tokenUserDefaultsKey)
        currentDevice = Device.fetchFromUserDefaults()
    }

    /**
     This should only be called from the initial login flow.
     */
    func setupFromVerify(url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var error: Error?

        dispatchGroup.enter()
        verify(url: url) { result in
            if case .failure(let verifyError) = result {
                error = verifyError
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        addDevice { result in
            if case .failure(let deviceError) = result {
                error = deviceError
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        retrieveVPNServers { result in
            if case .failure(let vpnError) = result {
                error = vpnError
            }
            dispatchGroup.leave()
        }

        if let error = error {
            completion(.failure(error))
            return
        }

        dispatchGroup.notify(queue: .main) {
            completion(.success(()))
        }
    }

    /**
     This should be called when the app is returned from foreground/launch and we've already logged in.
     */
    func setupFromAppLaunch(completion: @escaping (Result<Void, Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var error: Error?

        guard let userDefaultsToken = UserDefaults.standard.string(forKey: tokenUserDefaultsKey) else {
            completion(.failure(GuardianFailReason.emptyToken))
            return
        }

        guard let userDefaultsDevice = Device.fetchFromUserDefaults() else {
            completion(.failure(GuardianFailReason.couldNotFetchDevice))
            return
        }

        token = userDefaultsToken
        currentDevice = userDefaultsDevice

        dispatchGroup.enter()
        retrieveUser { result in
            if case .failure(let retrieveUserError) = result {
                error = retrieveUserError
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        retrieveVPNServers { result in
            if case .failure(let vpnError) = result {
                error = vpnError
            }
            dispatchGroup.leave()
        }

        if let error = error {
            completion(.failure(error))
            return
        }

        dispatchGroup.notify(queue: .main) {
            completion(.success(()))
        }
    }

    func login(completion: @escaping (Result<LoginCheckpointModel, Error>) -> Void) {
        GuardianAPI.initiateUserLogin(completion: completion)
    }

    private func verify(url: URL, completion: @escaping (Result<VerifyResponse, Error>) -> Void) {
        GuardianAPI.verify(urlString: url.absoluteString) { result in
            completion(result.map { [weak self] verifyResponse in
                guard let self = self else { return verifyResponse }
                UserDefaults.standard.set(verifyResponse.token, forKey: self.tokenUserDefaultsKey)
                self.user = verifyResponse.user
                self.token = verifyResponse.token
                return verifyResponse
            })
        }
    }

    @objc func pollUser() {
        retrieveUser { _ in }
    }

    func retrieveUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let token = token else {
            completion(Result.failure(GuardianFailReason.emptyToken))
            return // TODO: Handle this case?
        }
        GuardianAPI.accountInfo(token: token) { [weak self] result in
            if case .failure = result {
                self?.heartbeatFailedEvent.onNext(())
            }

            completion(result.map { user in
                self?.user = user
                return user
            })
        }
    }

    private func retrieveVPNServers(completion: @escaping (Result<[VPNCountry], Error>) -> Void) {
        guard let token = token else {
            completion(Result.failure(GuardianFailReason.emptyToken))
            return // TODO: Handle this case?
        }
        GuardianAPI.availableServers(with: token) { result in
            completion(result.map { [weak self] servers in
                self?.availableServers = servers
                return servers
            })
        }
    }

    private func addDevice(completion: @escaping (Result<Device, Error>) -> Void) {
        guard let token = token else {
            completion(Result.failure(GuardianFailReason.emptyToken))
            return // TODO: Handle this case?
        }

        let deviceBody: [String: Any] = ["name": UIDevice.current.name,
                                         "pubkey": credentialsStore.deviceKeys.devicePublicKey.base64Key() ?? ""]

        do {
            let body = try JSONSerialization.data(withJSONObject: deviceBody)
            GuardianAPI.addDevice(with: token, body: body) { [weak self] result in
                completion(result.map { device in
                    self?.currentDevice = device
                    device.saveToUserDefaults()
                    return device
                })
            }
        } catch {
            completion(Result.failure(GuardianFailReason.couldNotCreateBody))
        }
    }

    func startHeartbeat() {
        Timer(timeInterval: 3600,
              target: self,
              selector: #selector(pollUser),
              userInfo: nil,
              repeats: true)
    }
}

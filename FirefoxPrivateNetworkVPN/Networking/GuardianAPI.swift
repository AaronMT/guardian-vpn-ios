//
//  GuardianAPI
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import Foundation
import UIKit

class GuardianAPI: NetworkRequesting {

    private static func headers(with token: String) -> [String: String] {
        return ["Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "User-Agent": getUserAgentString()]
    }

    private static func getUserAgentString() -> String {
        return "\(getAppNameAndVersion()) \(getDeviceModel())/\(getDeviceOSVersion())"
    }

    private static func getAppNameAndVersion() -> String {
        guard let bundleDictionary = Bundle.main.infoDictionary else {
            return ""
        }

        guard let fullAppName = bundleDictionary["CFBundleName"] as? String else {
            return ""
        }
        let appName = fullAppName.replacingOccurrences(of: " ", with: "")

        guard let appVersion = bundleDictionary["CFBundleShortVersionString"] as? String else {
            return appName
        }

        return "\(appName)/\(appVersion)"
    }

    private static func getDeviceModel() -> String {
        // This retrieves the model in the form 'iPhone10,2', for example.
        // See https://medium.com/ios-os-x-development/get-model-info-of-ios-devices-18bc8f32c254
        // for reference

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)

        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    private static func getDeviceOSVersion() -> String {
        return "\(UIDevice.current.systemVersion)"
    }

    static func initiateUserLogin(completion: @escaping (Result<LoginCheckpointModel, Error>) -> Void) {
        let urlRequest = GuardianURLRequest.urlRequest(request: .login, type: .POST)
        NetworkLayer.fire(urlRequest: urlRequest) { result in
            DispatchQueue.main.async {
                completion(result.decode(to: LoginCheckpointModel.self))
            }
        }
    }

    static func accountInfo(token: String, completion: @escaping (Result<User, Error>) -> Void) {
        let urlRequest = GuardianURLRequest.urlRequest(request: .account, type: .GET, httpHeaderParams: headers(with: token))
        NetworkLayer.fire(urlRequest: urlRequest) { result in
            DispatchQueue.main.async {
                completion(result.decode(to: User.self))
            }
        }
    }

    static func verify(urlString: String, completion: @escaping (Result<VerifyResponse, Error>) -> Void) {
        let urlRequest = URLRequestBuilder.urlRequest(with: urlString, type: .GET)
        NetworkLayer.fire(urlRequest: urlRequest) { result in
            DispatchQueue.main.async {
                completion(result.decode(to: VerifyResponse.self))
            }
        }
    }

    static func availableServers(with token: String, completion: @escaping (Result<[VPNCountry], Error>) -> Void) {
        let urlRequest = GuardianURLRequest.urlRequest(request: .retrieveServers, type: .GET, httpHeaderParams: headers(with: token))
        NetworkLayer.fire(urlRequest: urlRequest) { result in
            DispatchQueue.main.async {
                completion(result
                    .decode(to: [String: [VPNCountry]].self)
                    .map { $0["countries"]! }
                )
            }
        }
    }

    static func addDevice(with token: String, body: [String: Any], completion: @escaping (Result<Device, Error>) -> Void) {
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(GuardianError.couldNotCreateBody))
            return
        }

        let urlRequest = GuardianURLRequest.urlRequest(request: .addDevice, type: .POST, httpHeaderParams: headers(with: token), body: data)
        NetworkLayer.fire(urlRequest: urlRequest) { result in
            DispatchQueue.main.async {
                completion(result.decode(to: Device.self))
            }
        }
    }

    static func removeDevice(with token: String, deviceKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let encodedKey = deviceKey.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            completion(.failure(GuardianError.couldNotEncodeData))
            return
        }

        let urlRequest = GuardianURLRequest.urlRequest(request: .removeDevice(encodedKey), type: .DELETE, httpHeaderParams: headers(with: token))

        NetworkLayer.fire(urlRequest: urlRequest) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(()))
                case.failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    static func latestVersion(completion: @escaping (Result<Release, Error>) -> Void) {
        let urlRequest = GuardianURLRequest.urlRequest(request: .versions, type: .GET)
        NetworkLayer.fire(urlRequest: urlRequest) { result in
            completion(result.decode(to: Release.self))
        }
    }
}

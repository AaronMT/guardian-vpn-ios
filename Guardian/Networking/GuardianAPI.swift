// SPDX-License-Identifier: MPL-2.0
// Copyright © 2019 Mozilla Corporation. All Rights Reserved.

import Foundation

class GuardianAPI {

    static func initiateUserLogin(completion: @escaping (Result<LoginCheckpointModel, Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .login, type: .POST)
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { $0.convert(to: LoginCheckpointModel.self) })
        }
    }

    static func accountInfo(token: String, completion: @escaping (Result<User, Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .account, type: .GET, httpHeaderParams: headers(with: token))
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { $0.convert(to: User.self) })
        }
    }

    static func verify(urlString: String, completion: @escaping (Result<VerifyResponse, Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(fullUrlString: urlString, type: .GET)
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { $0.convert(to: VerifyResponse.self) })
        }
    }

    static func availableServers(with token: String, completion: @escaping (Result<[VPNCountry], Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .retrieveServers, type: .GET, httpHeaderParams: headers(with: token))
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result
                .flatMap { $0.convert(to: [String: [VPNCountry]].self) }
                .map { $0["countries"]! })
        }
    }

    static func addDevice(with token: String, body: [String: Any], completion: @escaping (Result<Device, Error>) -> Void) {
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(Result { throw GuardianFailReason.couldNotCreateBody })
            return
        }

        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .addDevice, type: .POST, httpHeaderParams: headers(with: token), body: data)

        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { $0.convert(to: Device.self) })
        }
    }

    static func removeDevice(with deviceKey: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let encodedKey = deviceKey.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            completion(Result { throw GuardianFailReason.emptyToken })
            return
        }

        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .removeDevice(encodedKey), type: .DELETE)

        NetworkLayer.fireURLRequest(with: urlRequest, completion: completion)
    }

    private static func headers(with token: String) -> [String: String] {
        return ["Authorization": "Bearer \(token)",
                "Content-Type": "application/json"]
    }
}

// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import Foundation

class GuardianAPI {
    static func initiateUserLogin(completion: @escaping (Result<LoginCheckpointModel, Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .login, type: .POST)
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { data in
                Result { try data.convert(to: LoginCheckpointModel.self) }
            })
        }
    }

    static func accountInfo(token: String, completion: @escaping (Result<User, Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .account, type: .GET, httpHeaderParams: bearerToken(from: token))
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { data in
                Result { try data.convert(to: User.self) }
            })
        }
    }

    static func verify(urlString: String, completion: @escaping (Result<VerifyResponse, Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(fullUrlString: urlString, type: .GET)
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { data in
                Result { try data.convert(to: VerifyResponse.self) }
            })
        }
    }

    static func availableServers(with token: String, completion: @escaping (Result<[VPNCountry], Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .retrieveServers, type: .GET, httpHeaderParams: bearerToken(from: token))
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { data in
                Result {
                    guard let countries = try data.convert(to: [String: [VPNCountry]].self)["countries"] else {
                        throw GuardianFailReason.couldNotDecodeFromJson
                    }
                    return countries
                }
            })
        }
    }

    static func addDevice(with token: String, completion: @escaping (Result<Device, Error>) -> Void) {
        let urlRequest = GuardianURLRequestBuilder.urlRequest(request: .addDevice, type: .POST, httpHeaderParams: bearerToken(from: token))
        NetworkLayer.fireURLRequest(with: urlRequest) { result in
            completion(result.flatMap { data in
                Result { try data.convert(to: Device.self) }
            })
        }
    }

    private static func bearerToken(from token: String) -> [String: String] {
        return ["Authorization": "Bearer \(token)"]
    }
}

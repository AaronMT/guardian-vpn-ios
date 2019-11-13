//
//  NetworkLayer
//  FirefoxPrivateNetworkVPN
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2019 Mozilla Corporation.
//

import Foundation

class NetworkLayer {

    static func fire(urlRequest: URLRequest, completion: @escaping (Result<Data?, GuardianAPIError>) -> Void) {
        let defaultSession = URLSession(configuration: .default)
        defaultSession.configuration.timeoutIntervalForRequest = 120

        let dataTask = defaultSession.dataTask(with: urlRequest) { data, response, error in
            if let response = response as? HTTPURLResponse, 200...210 ~= response.statusCode {
                completion(.success(data))
            } else if error != nil, let data = data {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                completion(.failure(errorResponse?.guardianAPIError ?? .unknown))
            } else {
                completion(.failure(.unknown))
            }
        }
        dataTask.resume()
    }
}

struct ErrorResponse: Codable {
    let code: Int
    let errorno: Int
    let error: String

    var guardianAPIError: GuardianAPIError {
        return GuardianAPIError(rawValue: errorno) ?? .unknown
    }
}

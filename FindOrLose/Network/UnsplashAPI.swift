//
//  UnsplashAPI.swift
//  FindOrLose
//
//  Created by Rodrigo Rovaron on 07/23/21.
//

import Foundation
import Combine

enum UnsplashAPI {
  static let accessToken = "1FbNzA8lXbS1dKDVB3WXhQnbB7ZqYFYfhafTwi8TUx0"

  static func randomImage() -> AnyPublisher<RandomImageResponse, GameError> {
    let url = URL(string: "https://api.unsplash.com/photos/random/?client_id=\(accessToken)")!

    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.urlCache = nil
    let session = URLSession(configuration: config)

    var urlRequest = URLRequest(url: url)
    urlRequest.addValue("Accept-Version", forHTTPHeaderField: "v1")

    return session.dataTaskPublisher(for: urlRequest)
      .tryMap { response -> Data in
        
        guard
          let httpURLResponse = response.response as? HTTPURLResponse,
                                httpURLResponse.statusCode == 200
            else {
              throw GameError.statusCode
          }
        return response.data
      }
      .decode(type: RandomImageResponse.self, decoder: JSONDecoder())
      .mapError { GameError.map($0) }
      .eraseToAnyPublisher()
  }
}

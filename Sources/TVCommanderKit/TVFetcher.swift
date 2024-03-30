//
//  TVFetcher.swift
//
//
//  Created by Wilson Desimini on 3/30/24.
//

import Foundation

public class TVFetcher {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchDevice(for tv: TV, completion: @escaping (Result<TV, TVFetcherError>) -> Void) {
        guard let url = URL(string: tv.uri) else {
            completion(.failure(.invalidURL))
            return
        }
        session.dataTask(with: url) { data, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(.failedRequest(error, response as? HTTPURLResponse)))
                return
            }
            do {
                let updatedTV = try JSONDecoder().decode(TV.self, from: data)
                completion(.success(updatedTV))
            } catch {
                completion(.failure(.unexpectedResponseBody(data)))
            }
        }.resume()
    }
}

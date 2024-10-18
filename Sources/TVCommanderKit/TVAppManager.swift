//
//  TVAppManager.swift
//  TVCommanderKit
//
//  Created by Wilson Desimini on 10/17/24.
//

import Foundation

public protocol TVAppManaging {
    func fetchStatus(for tvApp: TVApp, tvIPAddress: String) async throws -> TVAppStatus
    func launch(tvApp: TVApp, tvIPAddress: String) async throws
}

enum TVAppManagerError: LocalizedError {
    case badURL(description: String)
    case noData
    case networkError(description: String)

    var errorDescription: String? {
        switch self {
        case .badURL(let description):
            return "Bad URL: \(description)"
        case .noData:
            return "No data received from the network."
        case .networkError(let description):
            return "Network error: \(description)"
        }
    }
}

public class TVAppManager: TVAppManaging {
    private let urlBuilder: TVAppURLBuilding
    private let networkManager: TVAppNetworkManaging
    private let decoder: TVAppDecoding

    public init(
        urlBuilder: TVAppURLBuilding = TVAppURLBuilder(),
        networkManager: TVAppNetworkManaging = TVAppNetworkManager(),
        decoder: TVAppDecoding = TVAppDecoder()
    ) {
        self.urlBuilder = urlBuilder
        self.networkManager = networkManager
        self.decoder = decoder
    }

    public func fetchStatus(for tvApp: TVApp, tvIPAddress: String) async throws -> TVAppStatus {
        let url = try buildURL(tvApp: tvApp, tvIPAddress: tvIPAddress)
        guard let data = try await networkManager.sendRequest(url: url) else {
            throw TVAppManagerError.noData
        }
        return try decoder.decodeAppStatus(from: data)
    }

    public func launch(tvApp: TVApp, tvIPAddress: String) async throws {
        let url = try buildURL(tvApp: tvApp, tvIPAddress: tvIPAddress)
        try await networkManager.sendRequest(url: url, method: "POST")
    }

    private func buildURL(tvApp: TVApp, tvIPAddress: String) throws -> URL {
        if let url = urlBuilder.buildURL(tvIPAddress: tvIPAddress, tvAppId: tvApp.id) {
            return url
        } else {
            throw TVAppManagerError.badURL(description: "Unable to build URL for IP: \(tvIPAddress)")
        }
    }
}

// MARK: - Build App URL

public protocol TVAppURLBuilding {
    func buildURL(tvIPAddress: String, tvAppId: String) -> URL?
}

public class TVAppURLBuilder: TVAppURLBuilding {
    public init() {
    }

    public func buildURL(tvIPAddress: String, tvAppId: String) -> URL? {
        var components = URLComponents()
        components.scheme = "http"
        components.host = tvIPAddress
        components.port = 8001
        components.path = "/api/v2/applications/\(tvAppId)"
        return components.url
    }
}

// MARK: - Send HTTP Request

public protocol TVAppNetworkManaging {
    @discardableResult
    func sendRequest(url: URL, method: String) async throws -> Data?
}

extension TVAppNetworkManaging {
    func sendRequest(url: URL) async throws -> Data? {
        try await sendRequest(url: url, method: "GET")
    }
}

enum TVAppNetworkError: LocalizedError {
    case appNotFound
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .appNotFound:
            return "App Not Found"
        case .invalidResponse:
            return "Invalid Response"
        }
    }
}

public class TVAppNetworkManager: TVAppNetworkManaging {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func sendRequest(url: URL, method: String) async throws -> Data? {
        var request = URLRequest(url: url)
        request.httpMethod = method
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    private func validate(response: URLResponse) throws {
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            return
        case 404:
            throw TVAppNetworkError.appNotFound
        default:
            throw TVAppNetworkError.invalidResponse
        }
    }
}

// MARK: Decode App Status

public protocol TVAppDecoding {
    func decodeAppStatus(from data: Data) throws -> TVAppStatus
}

public class TVAppDecoder: TVAppDecoding {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }

    public func decodeAppStatus(from data: Data) throws -> TVAppStatus {
        try decoder.decode(TVAppStatus.self, from: data)
    }
}

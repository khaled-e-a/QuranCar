//
//  QuranAPIService.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import Foundation

enum QuranAPIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
}

class QuranAPIService {
    private let baseURL = "https://apis-prelive.quran.foundation/content/api/v4"
    private let clientId: String
    private let authToken: String

    init(clientId: String, authToken: String) {
        self.clientId = clientId
        self.authToken = authToken
    }

    func fetchChapters() async throws -> [Chapter] {
        let url = URL(string: "\(baseURL)/chapters")!
        var request = URLRequest(url: url)

        // Add headers
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(authToken, forHTTPHeaderField: "x-auth-token")
        request.addValue(clientId, forHTTPHeaderField: "x-client-id")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw QuranAPIError.invalidResponse
            }

            let chapters = try JSONDecoder().decode(ChaptersResponse.self, from: data)
            return chapters.chapters
        } catch let error as DecodingError {
            throw QuranAPIError.decodingError(error)
        } catch {
            throw QuranAPIError.networkError(error)
        }
    }
}

// API Response Models
struct ChaptersResponse: Codable {
    let chapters: [Chapter]
}

struct Chapter: Codable {
    let id: Int
    let revelationPlace: String
    let revelationOrder: Int
    let bismillahPre: Bool
    let nameSimple: String
    let nameArabic: String
    let versesCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case revelationPlace = "revelation_place"
        case revelationOrder = "revelation_order"
        case bismillahPre = "bismillah_pre"
        case nameSimple = "name_simple"
        case nameArabic = "name_arabic"
        case versesCount = "verses_count"
    }
}
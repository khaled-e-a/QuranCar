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
        print("QuranAPIService: Initialized with clientId: \(clientId) and authToken: \(authToken)")
    }

    func fetchChapters() async throws -> [Chapter] {
        let url = URL(string: "\(baseURL)/chapters")!
        var request = URLRequest(url: url)

        // Add headers
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(authToken, forHTTPHeaderField: "x-auth-token")
        request.addValue(clientId, forHTTPHeaderField: "x-client-id")

        // Enhanced request logging
        print("""
        QuranAPIService: Fetching chapters from API
        URL: \(request.url?.absoluteString ?? "")
        Method: \(request.httpMethod ?? "GET")
        Headers: \(request.allHTTPHeaderFields ?? [:])
        """)

        do {
            print("QuranAPIService: Fetching chapters from API with request: \(request)")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("QuranAPIService: Received invalid response")
                throw QuranAPIError.invalidResponse
            }
            print("QuranAPIService: Received response with status code: \(httpResponse.statusCode)")

            let chapters = try JSONDecoder().decode(ChaptersResponse.self, from: data)
            return chapters.chapters
        } catch let error as DecodingError {
            throw QuranAPIError.decodingError(error)
        } catch {
            throw QuranAPIError.networkError(error)
        }
    }

    func fetchVersesByChapter(_ chapterId: Int) async throws -> [Verse] {
        // Update URL to match the Python version
        let url = URL(string: "\(baseURL)/verses/by_chapter/\(chapterId)")!
        var request = URLRequest(url: url)

        // Set request method explicitly to match Python
        request.httpMethod = "GET"

        // Match Python headers exactly
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(authToken, forHTTPHeaderField: "x-auth-token")
        request.addValue(clientId, forHTTPHeaderField: "x-client-id")

        print("""
        QuranAPIService: Fetching verses for chapter \(chapterId)
        URL: \(request.url?.absoluteString ?? "")
        Method: \(request.httpMethod ?? "GET")
        Headers: \(request.allHTTPHeaderFields ?? [:])
        """)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw QuranAPIError.invalidResponse
            }

            print("QuranAPIService: Response status code: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 200:
                let versesResponse = try JSONDecoder().decode(VersesResponse.self, from: data)
                print("QuranAPIService: Successfully fetched \(versesResponse.verses.count) verses")
                return versesResponse.verses

            case 401:
                throw QuranAPIError.unauthorized

            default:
                print("QuranAPIService: Unexpected status code: \(httpResponse.statusCode)")
                throw QuranAPIError.invalidResponse
            }
        } catch let error as DecodingError {
            print("QuranAPIService: Decoding error: \(error)")
            throw QuranAPIError.decodingError(error)
        } catch {
            print("QuranAPIService: Network error: \(error)")
            throw QuranAPIError.networkError(error)
        }
    }

    func fetchUthmaniVerses(chapterNumber: Int) async throws -> [UthmaniVerse] {
        let url = URL(string: "\(baseURL)/quran/verses/uthmani?chapter_number=\(chapterNumber)")!
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(authToken, forHTTPHeaderField: "x-auth-token")
        request.addValue(clientId, forHTTPHeaderField: "x-client-id")

        print("""
        QuranAPIService: Fetching Uthmani verses for chapter \(chapterNumber)
        URL: \(request.url?.absoluteString ?? "")
        Method: \(request.httpMethod ?? "GET")
        Headers: \(request.allHTTPHeaderFields ?? [:])
        """)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw QuranAPIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                let response = try JSONDecoder().decode(UthmaniVersesResponse.self, from: data)
                return response.verses
            case 401:
                throw QuranAPIError.unauthorized
            default:
                throw QuranAPIError.invalidResponse
            }
        } catch {
            throw QuranAPIError.networkError(error)
        }
    }

    func fetchReciters() async throws -> [Reciter] {
        let url = URL(string: "\(baseURL)/resources/recitations")!
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(authToken, forHTTPHeaderField: "x-auth-token")
        request.addValue(clientId, forHTTPHeaderField: "x-client-id")

        print("QuranAPIService: Fetching reciters")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("QuranAPIService: Reciters Response data: \(String(data: data, encoding: .utf8) ?? "")")

            guard let httpResponse = response as? HTTPURLResponse else {
                throw QuranAPIError.invalidResponse
            }
            print("QuranAPIService: Reciters Response status code: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 200:
                let response = try JSONDecoder().decode(RecitersResponse.self, from: data)
                print("QuranAPIService: Successfully fetched \(response.recitations.count) reciters")
                return response.recitations
            case 401:
                print("QuranAPIService: Reciters Unauthorized")
                throw QuranAPIError.unauthorized
            default:
                print("QuranAPIService: Reciters Unexpected status code: \(httpResponse.statusCode)")
                throw QuranAPIError.invalidResponse
            }
        } catch {
            print("QuranAPIService: Network error: \(error)")
            throw QuranAPIError.networkError(error)
        }
    }

    func fetchVerseAudio(recitationId: Int, chapterNumber: Int) async throws -> [AudioFile] {
        let url = URL(string: "\(baseURL)/recitations/\(recitationId)/by_chapter/\(chapterNumber)")!
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(authToken, forHTTPHeaderField: "x-auth-token")
        request.addValue(clientId, forHTTPHeaderField: "x-client-id")

        print("QuranAPIService: Fetching audio files for reciter \(recitationId) chapter \(chapterNumber)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("QuranAPIService: Audio files Response data: \(String(data: data, encoding: .utf8) ?? "")")

            guard let httpResponse = response as? HTTPURLResponse else {
                throw QuranAPIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                let response = try JSONDecoder().decode(AudioFilesResponse.self, from: data)
                print("QuranAPIService: Successfully fetched \(response.audioFiles.count) audio files")
                return response.audioFiles
            case 401:
                print("QuranAPIService: Audio files Unauthorized")
                throw QuranAPIError.unauthorized
            default:
                print("QuranAPIService: Audio files Unexpected status code: \(httpResponse.statusCode)")
                throw QuranAPIError.invalidResponse
            }
        } catch {
            print("QuranAPIService: Network error: \(error)")
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

struct VersesResponse: Codable {
    let verses: [Verse]
    let pagination: Pagination
}

struct Verse: Codable {
    let id: Int
    let verseNumber: Int
    let verseKey: String
    let hizbNumber: Int
    let rubElHizbNumber: Int
    let rukuNumber: Int
    let manzilNumber: Int
    let sajdahNumber: Int?
    let pageNumber: Int
    let juzNumber: Int
    let textUthmani: String?

    enum CodingKeys: String, CodingKey {
        case id
        case verseNumber = "verse_number"
        case verseKey = "verse_key"
        case hizbNumber = "hizb_number"
        case rubElHizbNumber = "rub_el_hizb_number"
        case rukuNumber = "ruku_number"
        case manzilNumber = "manzil_number"
        case sajdahNumber = "sajdah_number"
        case pageNumber = "page_number"
        case juzNumber = "juz_number"
        case textUthmani = "text_uthmani"
    }
}

struct Pagination: Codable {
    let perPage: Int
    let currentPage: Int
    let nextPage: Int?
    let totalPages: Int
    let totalRecords: Int

    enum CodingKeys: String, CodingKey {
        case perPage = "per_page"
        case currentPage = "current_page"
        case nextPage = "next_page"
        case totalPages = "total_pages"
        case totalRecords = "total_records"
    }
}

struct UthmaniVersesResponse: Codable {
    let verses: [UthmaniVerse]
}

struct UthmaniVerse: Codable {
    let id: Int
    let verseKey: String
    let textUthmani: String

    enum CodingKeys: String, CodingKey {
        case id
        case verseKey = "verse_key"
        case textUthmani = "text_uthmani"
    }
}

struct Reciter: Codable {
    let id: Int
    let reciterName: String
    let style: String?
    let translatedName: TranslatedName

    enum CodingKeys: String, CodingKey {
        case id
        case reciterName = "reciter_name"
        case style
        case translatedName = "translated_name"
    }
}

struct TranslatedName: Codable {
    let name: String
    let languageName: String

    enum CodingKeys: String, CodingKey {
        case name
        case languageName = "language_name"
    }
}

struct RecitersResponse: Codable {
    let recitations: [Reciter]
}

struct AudioFile: Codable {
    let verseKey: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case url
    }
}

struct AudioFilesResponse: Codable {
    let audioFiles: [AudioFile]
    let pagination: Pagination

    enum CodingKeys: String, CodingKey {
        case audioFiles = "audio_files"
        case pagination
    }
}
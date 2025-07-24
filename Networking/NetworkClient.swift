//
//  NetworkClient.swift
//  yandexSMR
//
//  Created by kirill on 18.07.2025.
//

import Foundation

// Определяем кастомные ошибки для нашего сетевого слоя
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case noData
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL-адрес."
        case .requestFailed(let statusCode):
            return "Ошибка сервера. Код ответа: \(statusCode)."
        case .decodingFailed:
            return "Не удалось обработать ответ от сервера."
        case .noData:
            return "Сервер не вернул данные."
        case .unknown:
            return "Произошла неизвестная ошибка."
        }
    }
}

final class NetworkClient {
    // MARK: - Properties
    private let baseURL = URL(string: "https://shmr-finance.ru/api/v1")!
    private let session: URLSession
    // ВАЖНО: Замените "YOUR_TOKEN" на ваш токен!
    private let authToken = "Bearer 6VwjDlRhnpobBsLfL8skfsoe"

    // Определяем HTTP методы для удобства
    enum HttpMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    // MARK: - Lifecycle
    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public Methods
    
    // Основной метод для выполнения запросов
    func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HttpMethod,
        body: B? = nil,// Тело запроса опционально
        query: [String: String]? = nil
    ) async throws -> T {
        var url = baseURL.appendingPathComponent(endpoint)
        if let queryItems = query?.map({ URLQueryItem(name: $0.key, value: $0.value) }) {
                    url.append(queryItems: queryItems)
                }
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        
        // Добавляем общие заголовки
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        // Кодируем тело запроса, если оно есть
        if let body = body {
            let encoder = JSONEncoder.custom
            request.httpBody = try? encoder.encode(body)
        }
        // --- НАЧАЛО ОТЛАДОЧНОГО БЛОКА ---
                // Распечатаем запрос, чтобы увидеть его в консоли
                print("----------- STARTING REQUEST -----------")
                print("URL: \(request.url?.absoluteString ?? "N/A")")
                print("METHOD: \(request.httpMethod ?? "N/A")")
                print("HEADERS: \(request.allHTTPHeaderFields ?? [:])")
                if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
                    print("BODY: \(bodyString)")
                } else {
                    print("BODY: nil")
                }
                print("--------------------------------------")
                // --- КОНЕЦ ОТЛАДОЧНОГО БЛОКА ---
        // Выполняем запрос
        let (data, response) = try await session.data(for: request)
        
        // Проверяем ответ
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        // Декодируем ответ
        do {
            let decoder = JSONDecoder.custom
            // API возвращает даты в формате ISO8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}

// Вспомогательная пустая структура для запросов без тела
struct EmptyBody: Encodable {}

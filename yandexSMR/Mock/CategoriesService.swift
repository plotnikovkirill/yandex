import Foundation

// Протокол оставляем без изменений
protocol CategoriesServiceLogic {
    func getAllCategories() async throws -> [Category]
    func getCategories(by direction: Direction) async throws -> [Category]
}

// ИЗМЕНЕНО: Это больше не actor, а обычный класс,
// так как NetworkClient уже потокобезопасен для наших целей.
final class CategoriesService: CategoriesServiceLogic {
    
    // ДОБАВЛЕНО: Зависимость от NetworkClient
    private let networkClient: NetworkClient

    // ДОБАВЛЕНО: Инициализатор
    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    // MARK: - Methods
    func getAllCategories() async throws -> [Category] {
        // ИЗМЕНЕНО: Делаем сетевой запрос к эндпоинту /categories
        let emptyBody: EmptyBody? = nil
                return try await networkClient.request(
                    endpoint: "categories",
                    method: .get,
                    body: emptyBody
                )
    }
    
    func getCategories(by direction: Direction) async throws -> [Category] {
        // ВАЖНО: API предоставляет эндпоинт для фильтрации по типу
        let isIncome = (direction == .income)
        let endpoint = "categories/type/\(isIncome)"
        let emptyBody: EmptyBody? = nil
                return try await networkClient.request(
                    endpoint: endpoint,
                    method: .get,
                    body: emptyBody
                )
    }
}

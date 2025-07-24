import Foundation

@MainActor
final class CategoryRepository: ObservableObject {
    @Published private(set) var allCategories: [Category] = []
    @Published var isLoading = false
    
    private let networkService: CategoriesServiceLogic
    private let storage: CategoryStorage
    
    init(networkService: CategoriesServiceLogic, storage: CategoryStorage) {
        self.networkService = networkService
        self.storage = storage
    }
    
    func fetchAllCategories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let freshCategories = try await networkService.getAllCategories()
            try await storage.upsert(freshCategories)
            self.allCategories = try await storage.fetchAll()
        } catch {
            self.allCategories = (try? await storage.fetchAll()) ?? []
        }
    }
    
    func getCategories(by direction: Direction) -> [Category] {
        return allCategories.filter { $0.direction == direction }
    }
    
    func getCategory(id: Int) -> Category? {
        return allCategories.first(where: { $0.id == id })
    }
}

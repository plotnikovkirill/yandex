// UI/Analysis/AnalysisViewController.swift

import UIKit
import SwiftUI

final class AnalysisViewController: UIViewController {

    // MARK: - Зависимости и данные
    private let direction: Direction
    private let transactionsService = TransactionsService()
    private let categoriesService = CategoriesService()
    
    private var transactions: [Transaction] = []
    private var allCategories: [Category] = []
    private var totalAmount: Decimal = 0
    private var sortOption: SortOption = .byDate
    
    private lazy var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    private lazy var endDate: Date = Date()

    // MARK: - UI Элементы
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "value1Cell")
        tableView.register(HostingCell.self, forCellReuseIdentifier: HostingCell.reuseIdentifier)
        tableView.backgroundColor = UIColor(named: "Background")
        return tableView
    }()

    // MARK: - Lifecycle
    init(direction: Direction) {
        self.direction = direction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    // MARK: - Настройка UI
    private func setupUI() {
        view.backgroundColor = UIColor(named: "Background")
        title = "Анализ"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    // ... внутри final class AnalysisViewController ...

    private func createStyledDatePicker(date: Date, action: Selector) -> UIView {
        // 1. Создаем сам пикер
        let picker = UIDatePicker()
        picker.date = date
        picker.datePickerMode = .date
        // ВАЖНО: Устанавливаем стиль, чтобы он выглядел как кнопка
        picker.preferredDatePickerStyle = .compact
        picker.addTarget(self, action: action, for: .valueChanged)
        
        // 2. Создаем контейнер
        let container = UIView()
        container.backgroundColor = UIColor(named: "LightAccentColor")?.withAlphaComponent(0.5)
        container.layer.cornerRadius = 8
        container.clipsToBounds = true
        
        // 4. Помещаем пикер внутрь контейнера
        container.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        
        // ДОБАВЛЕНО: Задаем явный размер контейнеру
        // Это говорит системе, что наш контейнер должен иметь определенный размер,
        // основанный на внутреннем размере пикера.
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: picker.widthAnchor, constant: 16), // Добавляем отступы по бокам
            container.heightAnchor.constraint(equalTo: picker.heightAnchor, constant: 8)  // Добавляем отступы сверху/снизу
        ])
        
        // Привязываем пикер к центру контейнера
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }

    // MARK: - Логика
    private func loadData() {
        Task {
            let dayStart = Calendar.current.startOfDay(for: startDate)
            let dayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            
            do {
                let categoriesForDirection = try await categoriesService.getCategories(by: direction)
                let categoryIds = Set(categoriesForDirection.map(\.id))
                let allTransactions = try await transactionsService.transactions(accountId: 1, from: dayStart, to: dayEnd)
                
                let filtered = allTransactions.filter { categoryIds.contains($0.categoryId) }
                
                await MainActor.run {
                    self.allCategories = categoriesForDirection
                    self.transactions = filtered
                    self.applySort()
                    self.totalAmount = filtered.reduce(0) { $0 + $1.amount }
                    self.tableView.reloadData()
                }
            } catch {
                print("Ошибка загрузки данных для анализа: \(error)")
            }
        }
    }
    
    private func applySort() {
        switch sortOption {
        case .byDate:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            transactions.sort { $0.amount > $1.amount }
        }
    }
    
    @objc private func startDateChanged(_ picker: UIDatePicker) {
        self.startDate = picker.date
        if startDate > endDate {
            endDate = startDate
        }
        loadData()
    }
    
    @objc private func endDateChanged(_ picker: UIDatePicker) {
        self.endDate = picker.date
        if endDate < startDate {
            startDate = endDate
        }
        loadData()
    }
    
    @objc private func sortTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "По дате", style: .default, handler: { _ in
            self.sortOption = .byDate
            self.applySort()
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "По сумме", style: .default, handler: { _ in
            self.sortOption = .byAmount
            self.applySort()
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
        }
        
        present(alert, animated: true)
    }
} // <-- ВАЖНО: ЭТА СКОБКА ЗАКРЫВАЕТ КЛАСС AnalysisViewController


// MARK: - UITableViewDataSource, UITableViewDelegate
extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 1
        case 2: return transactions.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // Секция управления
                    let cell = UITableViewCell(style: .value1, reuseIdentifier: "value1Cell")
                    cell.backgroundColor = .systemBackground
                    cell.selectionStyle = .none

                    switch indexPath.row {
                    case 0:
                        cell.textLabel?.text = "Период: начало"
                        let picker = UIDatePicker()
                        picker.date = startDate
                        picker.datePickerMode = .date
                        picker.preferredDatePickerStyle = .compact
                        picker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
                        // Присваиваем стилизованный пикер как accessoryView
                        cell.accessoryView = picker
                        
                    case 1:
                        cell.textLabel?.text = "Период: конец"
                        let picker = UIDatePicker()
                        picker.date = endDate
                        picker.datePickerMode = .date
                        picker.preferredDatePickerStyle = .compact
                        picker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
                        cell.accessoryView = picker

                    case 2:
                        cell.textLabel?.text = "Сумма"
                        cell.detailTextLabel?.text = "\(totalAmount.formatted()) ₽"
                        
                    default: break
                    }
                    
                    // Стилизуем accessoryView, если это UIDatePicker
                    if let picker = cell.accessoryView as? UIDatePicker {
                        //picker.backgroundColor = UIColor(named: "LightAccentColor")?.withAlphaComponent(0.5)
                        picker.layer.cornerRadius = 8
                        picker.layer.masksToBounds = true
                        // Добавляем отступы, чтобы фон был чуть больше самого пикера
                        picker.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 8)
                    }
                    
                    return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let imageView = UIImageView(image: UIImage(systemName: "chart.pie.fill"))
            imageView.tintColor = .systemGray4
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.contentView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                imageView.heightAnchor.constraint(equalToConstant: 120)
            ])
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell

        case 2:
            guard let transactionCell = tableView.dequeueReusableCell(withIdentifier: HostingCell.reuseIdentifier, for: indexPath) as? HostingCell else {
                 return UITableViewCell()
            }
            let transaction = transactions[indexPath.row]
            let category = allCategories.first { $0.id == transaction.categoryId }
            transactionCell.configure(with: transaction, category: category)
            return transactionCell

        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            let transaction = transactions[indexPath.row]
            let editView = TransactionEditView(mode: .edit(transaction: transaction))
            let hostingController = UIHostingController(rootView: editView)
            present(hostingController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2 {
            let headerView = UIView()
            let titleLabel = UILabel()
            titleLabel.text = "ОПЕРАЦИИ"
            titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
            titleLabel.textColor = .gray
            
            let sortButton = UIButton(type: .system)
            sortButton.setTitle(sortOption.rawValue, for: .normal)
            sortButton.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
            sortButton.semanticContentAttribute = .forceRightToLeft
            sortButton.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            sortButton.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(titleLabel)
            headerView.addSubview(sortButton)
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                
                sortButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                sortButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            ])
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 { return 40 }
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            // Задаем высоту только для ячеек с транзакциями
            if indexPath.section == 2 {
                return 60.0 // Можете подобрать значение, 60 выглядит хорошо
            }
            // Для остальных ячеек оставляем автоматическую высоту
            return UITableView.automaticDimension
        }
}


fileprivate final class HostingCell: UITableViewCell {
    static let reuseIdentifier = "TransactionHostingCell"
    private var hostingController: UIHostingController<TransactionRow>?

    func configure(with transaction: Transaction, category: Category?) {
        let transactionRowView = TransactionRow(transaction: transaction, category: category, showEmojiBackground: true)
        
        if let hostingController = hostingController {
            hostingController.rootView = transactionRowView
        } else {
            hostingController = UIHostingController(rootView: transactionRowView)
            guard let hcView = hostingController?.view else { return }
            hcView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(hcView)
            
            NSLayoutConstraint.activate([
                hcView.topAnchor.constraint(equalTo: contentView.topAnchor),
                hcView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                hcView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hcView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }
        contentView.backgroundColor = .systemBackground
    }
}

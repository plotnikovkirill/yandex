import UIKit
import SwiftUI

final class AnalysisViewController: UIViewController {

    // MARK: - Зависимости и данные
    private let direction: Direction
    private let transactionsRepository: TransactionsRepository
    private let categoryRepository: CategoryRepository
    private let accountsRepository: AccountsRepository
    
    private var transactions: [Transaction] = []
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
    init(direction: Direction,
         transactionsRepository: TransactionsRepository,
         categoryRepository: CategoryRepository,
         accountsRepository: AccountsRepository) {
        self.direction = direction
        self.transactionsRepository = transactionsRepository
        self.categoryRepository = categoryRepository
        self.accountsRepository = accountsRepository
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Настраиваем navigation bar родительского контроллера при каждом появлении
        guard let navController = self.navigationController else { return }
        navController.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "Анализ"
    }

    // MARK: - Настройка UI
    private func setupUI() {
        view.backgroundColor = UIColor(named: "Background")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Логика
    private func loadData() {
        Task {
            guard let accountId = accountsRepository.currentAccountId else { return }
            
            let dayStart = Calendar.current.startOfDay(for: startDate)
            let dayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            
            let loadedTransactions = await transactionsRepository.getTransactions(for: accountId, from: dayStart, to: dayEnd)
            
            self.transactions = loadedTransactions.filter { categoryRepository.getCategory(id: $0.categoryId)?.direction == direction }
            self.totalAmount = self.transactions.reduce(0) { $0 + $1.amount }
            self.applySort()
            self.tableView.reloadData()
        }
    }
    
    private func applySort() {
        switch sortOption {
        case .byDate: transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount: transactions.sort { $0.amount > $1.amount }
        }
    }
    
    @objc private func startDateChanged(_ picker: UIDatePicker) {
        self.startDate = picker.date
        if startDate > endDate { endDate = startDate }
        loadData()
    }
    
    @objc private func endDateChanged(_ picker: UIDatePicker) {
        self.endDate = picker.date
        if endDate < startDate { startDate = endDate }
        loadData()
    }
    
    @objc private func sortTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "По дате", style: .default) { _ in self.updateSortOption(to: .byDate) })
        alert.addAction(UIAlertAction(title: "По сумме", style: .default) { _ in self.updateSortOption(to: .byAmount) })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateSortOption(to option: SortOption) {
        self.sortOption = option
        self.applySort()
        self.tableView.reloadSections(IndexSet(integer: 2), with: .automatic) // Обновляем только секцию с операциями
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 3 }
    
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
        case 0: // Секция управления
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
            if let picker = cell.accessoryView as? UIDatePicker {
                picker.layer.cornerRadius = 8
                picker.layer.masksToBounds = true
            }
            return cell

        case 1: // Секция "графика"
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

        case 2: // Секция операций
            guard let transactionCell = tableView.dequeueReusableCell(withIdentifier: HostingCell.reuseIdentifier, for: indexPath) as? HostingCell else { return UITableViewCell() }
            let transaction = transactions[indexPath.row]
            let category = categoryRepository.getCategory(id: transaction.categoryId)
            transactionCell.configure(with: transaction, category: category, hideChevron: true)
            transactionCell.accessoryType = .disclosureIndicator // Используем стандартную стрелку
            return transactionCell

        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            let transaction = transactions[indexPath.row]
            let editView = TransactionEditView(
                mode: .edit(transaction: transaction),
                transactionsRepository: self.transactionsRepository,
                categoryRepository: self.categoryRepository,
                accountsRepository: self.accountsRepository
            )
            let hostingController = UIHostingController(rootView: editView)
            present(hostingController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2 {
            let headerView = UIView()
            let titleLabel = UILabel(); titleLabel.text = "ОПЕРАЦИИ"; titleLabel.font = .systemFont(ofSize: 13, weight: .regular); titleLabel.textColor = .gray
            let sortButton = UIButton(type: .system); sortButton.setTitle(sortOption.rawValue, for: .normal); sortButton.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal); sortButton.semanticContentAttribute = .forceRightToLeft; sortButton.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)
            [titleLabel, sortButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; headerView.addSubview($0) }
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16), titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                sortButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16), sortButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
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
        if indexPath.section == 2 { return 60.0 }
        return UITableView.automaticDimension
    }
}

// MARK: - Hosting Cell for SwiftUI Row
fileprivate final class HostingCell: UITableViewCell {
    static let reuseIdentifier = "TransactionHostingCell"
    private var hostingController: UIHostingController<TransactionRow>?

    func configure(with transaction: Transaction, category: Category?, hideChevron: Bool) {
        let transactionRowView = TransactionRow(transaction: transaction, category: category, showEmojiBackground: true)
        
        if let hostingController = hostingController {
            hostingController.rootView = transactionRowView
        } else {
            hostingController = UIHostingController(rootView: transactionRowView)
            guard let hcView = hostingController?.view else { return }
            hcView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(hcView)
            NSLayoutConstraint.activate([
                hcView.topAnchor.constraint(equalTo: contentView.topAnchor), hcView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                hcView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), hcView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }
        contentView.backgroundColor = .systemBackground
    }
}

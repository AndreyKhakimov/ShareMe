//
//  PortfolioViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.05.2022.
//

import UIKit
import SnapKit

class PortfolioViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        return tableView
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search assets"
        searchController.searchBar.sizeToFit()
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.scopeButtonTitles = ["Stock", "Crypto"]
        
        searchController.searchBar.delegate = self
        return searchController
    }()
    
    private let networkManager = PortfolioNetworkManager()
    private let storageManager = StorageManager.shared
    var assets: [Asset]?
    private var portfolioAssets = [PortfolioAsset]()
    private var cellHeights = [IndexPath: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        tableView.dataSource = self
        tableView.delegate = self
        assets = StorageManager.shared.getAllAssets()
        fetchAssets(assets ?? [Asset]())
    }
    
    private func fetchAssets(_ assets: [Asset]) {
        networkManager.getAssets(assets: assets) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let portfolioAssets):
                    self.portfolioAssets = portfolioAssets
                    self.cellHeights.removeAll()
                    self.tableView.reloadData()
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
    }
    
}

// MARK: - TableView Datasource Methods
extension PortfolioViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        portfolioAssets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.identifier, for: indexPath) as! SearchResultCell
        let asset = portfolioAssets[indexPath.row]
        cell.configure(image: asset.logo, info: String(asset.currentPrice), description: String(asset.code), chartData: asset.chartData)
        return cell
    }
    
    func isSearchBarEmpty() -> Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }
    
}

// MARK: - TableView Delegate Methods
extension PortfolioViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let asset = assets[indexPath.row]
//        let assetVC = AssetViewController()
//        assetVC.code = asset.code
//        assetVC.assetName = asset.name
//        assetVC.exchange = asset.exchange
//        assetVC.currency = asset.currency
//        assetVC.logoURL = asset.logo
//        navigationController?.pushViewController(assetVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.bounds.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - Setup Views
extension PortfolioViewController {
    func setupViews() {
        view.addSubview(tableView)
        navigationItem.searchController = searchController
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Search Bar Delegate
extension PortfolioViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchBar.text = ""
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        guard let text = searchController.searchBar.text else { return }
//        fetchAssets(with: text)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        guard let assetName = searchController.searchBar.text else { return }
//        guard !isSearchBarEmpty() else { return }
//        switch searchController.searchBar.selectedScopeButtonIndex {
//        case 1:
//            fetchAssets(with: assetName, and: .crypto)
//        default:
//            fetchAssets(with: assetName)
//        }
    }
    
}
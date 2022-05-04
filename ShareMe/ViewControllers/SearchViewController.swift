//
//  SearchViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.04.2022.
//

import UIKit
import SnapKit

class SearchViewController: UIViewController {
    
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
    
    private let networkManager = SearchAssetNetworkManager()
    private var assets = [SearchRespond]()
    private var cellHeights = [IndexPath: CGFloat]()
//    private var logos = [URL?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func fetchAssets(with name: String, and type: AssetType = .stock) {
        networkManager.getAssetsWithName(name: name, type: type) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let assetsRespond):
                    self.assets = assetsRespond
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
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.identifier, for: indexPath) as! SearchResultCell
        let asset = assets[indexPath.row]
        cell.configure(image: asset.logo ,info: asset.info, description: asset.descriprion, chartData: asset.chartData)
        return cell
    }
    
    func isSearchBarEmpty() -> Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }
    
}

// MARK: - TableView Delegate Methods
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let asset = assets[indexPath.row]
        let assetVC = AssetViewController()
        assetVC.code = asset.code
        assetVC.exchange = asset.exchange
        navigationController?.pushViewController(assetVC, animated: true)
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
extension SearchViewController {
    func setupViews() {
        view.addSubview(tableView)
        navigationItem.searchController = searchController
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Search Bar Delegate
extension SearchViewController: UISearchBarDelegate {
        func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
            searchBar.text = ""
        }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchController.searchBar.text else { return }
        fetchAssets(with: text)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchController.searchBar.text else { return }
        guard !isSearchBarEmpty() else { return }
        switch searchController.searchBar.selectedScopeButtonIndex {
        case 1:
            fetchAssets(with: text, and: .crypto)
        default:
            fetchAssets(with: text)
        }
    }
    
}

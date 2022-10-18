//
//  SearchViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.04.2022.
//

import UIKit
import SnapKit

class SearchViewController: UIViewController {
    
    private struct Section: Hashable {
        enum SectionType {
            case first
        }
        var type: SectionType
        var items: [SearchRespond]
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
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
    private var cellHeights = [IndexPath: CGFloat]()
    private var searchAssetsDataTask: URLSessionDataTask?
    private var type: AssetType = .stock
    private lazy var dataSource = createDatasource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        tableView.delegate = self
    }
    
    private func createDatasource() -> UITableViewDiffableDataSource<Section, SearchRespond> {
        UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.identifier, for: indexPath) as! SearchResultCell
            cell.configure(code: itemIdentifier.code, exchange: itemIdentifier.exchange, image: itemIdentifier.logo ,info: itemIdentifier.name, description: itemIdentifier.description, chartData: itemIdentifier.chartData)
            return cell
        })
    }
    
    private func fetchAssets(with name: String, and type: AssetType = .stock) {
        searchAssetsDataTask?.cancel()
        searchAssetsDataTask = networkManager.getAssetsWithName(name: name, type: type) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let assetsRespond):
                    self.cellHeights.removeAll()
                    self.updateDataSource(assets: assetsRespond)
                    assetsRespond.forEach { asset in
                        if let assetLogoURL = asset.logo {
                            let id = [asset.code, asset.exchange].joined(separator: ":")
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.logoImageCache.insert(assetLogoURL, forKey: id)
                        }
                    }
                case .failure(let error):
                    if case .cancelled = error { break }
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
    }
    
    func updateDataSource(assets: [SearchRespond]) {
        let sections = [Section(type: .first, items: assets)]
        var snapshot = NSDiffableDataSourceSnapshot<Section, SearchRespond>()
        snapshot.appendSections(sections)
        sections.forEach { section in
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }
    
    func isSearchBarEmpty() -> Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }
    
}

// MARK: - TableView Delegate Methods
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let asset = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let assetVC = AssetViewController(
            code: asset.code,
            assetName: asset.name,
            exchange: asset.exchange,
            currency: asset.currency,
            type: type,
            logoURL: asset.logo
        )
        
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
        searchAssetsDataTask?.cancel()
        guard let assetName = searchController.searchBar.text else { return }
        guard !isSearchBarEmpty() else { return }
        switch searchController.searchBar.selectedScopeButtonIndex {
        case 1:
            fetchAssets(with: assetName, and: .crypto)
            type = .crypto
        default:
            fetchAssets(with: assetName)
            type = .stock
        }
    }
    
}

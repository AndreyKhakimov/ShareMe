//
//  PortfolioCollectionViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 25.05.2022.
//

import UIKit
import SnapKit
import CoreData
import SwiftUI

class PortfolioCollectionViewController: UIViewController {
    
    private var ops: [BlockOperation] = []
    
    private struct Section: Hashable {
        var type: AssetType
        var items: [PortfolioCellData]
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
        }
    
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.type == rhs.type
        }
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Asset> = {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Asset.type),
                                    ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: "type",
            cacheName: nil)
        return fetchedResultsController
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = generateCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(PortfolioCollectionViewCell.self, forCellWithReuseIdentifier: PortfolioCollectionViewCell.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        return collectionView
    }()
    
    private let networkManager = PortfolioNetworkManager()
    private let storageManager = StorageManager.shared
    private let webSocketManager = WebSocketManager()
    private var dataSource: UICollectionViewDiffableDataSource<Section, PortfolioCellData>?
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        collectionView.delegate = self
        dataSource = createDatasource()
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        fetchAssets(fetchedResultsController.fetchedObjects ?? [Asset]())
        webSocketManager.delegate = self
        setupWebSockets()
    }
    
    private func generateCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { _, _ -> NSCollectionLayoutSection? in
            
            let size = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(60)
            )
            
            let item = NSCollectionLayoutItem(layoutSize: size)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(100)
            )
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(40)
            )
            
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            
            section.boundarySupplementaryItems = [sectionHeader]
            
            return section
        })
    }
    
    private func createDatasource() -> UICollectionViewDiffableDataSource<Section, PortfolioCellData> {
        let dataSource: UICollectionViewDiffableDataSource<Section, PortfolioCellData> = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [fetchedResultsController] collectionView, indexPath, itemIdentifier in
            let object = fetchedResultsController.object(at: indexPath)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PortfolioCollectionViewCell.identifier, for: indexPath) as! PortfolioCollectionViewCell
            let url = URL(string: object.logo)
            cell.configure(
                uid: object.uid,
                logo: url,
                assetName: object.code,
                assetDescription: object.name,
                chartData: object.chartData,
                price: object.currentPrice,
                currency: object.currency,
                priceChange: object.priceChange,
                pricePercentChange: object.priceChangePercent)
            return cell
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else {
                return nil
            }
            guard let sections = self?.fetchedResultsController.sections else { return SectionHeaderView() }
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "header",
                for: indexPath) as? SectionHeaderView
            let asset = AssetType(rawValue: Int16(sections[indexPath.section].name) ?? 0)
            view?.label.text = asset?.assetName
            return view
        }
        return dataSource
    }
    
    private func fetchAssets(_ assets: [Asset]) {
        networkManager.getAssets(assets: assets) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
    }
    
    func updateDataSource(assets: [Asset]) {
        var sections = [Section]()
        let stockAssets = assets
            .filter({ $0.type == .stock })
            .map { PortfolioCellData(asset: $0) }
        let cryptoAssets = assets
            .filter({ $0.type == .crypto })
            .map { PortfolioCellData(asset: $0) }
        
        if !stockAssets.isEmpty {
            sections.append(Section(type: .stock, items: stockAssets))
        }
        
        if !cryptoAssets.isEmpty {
            sections.append(Section(type: .crypto, items: cryptoAssets))
        }
        
        if !sections.isEmpty {
            var snapshot = NSDiffableDataSourceSnapshot<Section, PortfolioCellData>()
            snapshot.appendSections(sections)
            
            sections.forEach { section in
                snapshot.appendItems(section.items, toSection: section)
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems(section.items)
                } else {
                    snapshot.reloadItems(section.items)
                }
            }
            dataSource?.apply(snapshot, animatingDifferences: false, completion: nil)
        }
    }
    
    deinit {
        for o in ops { o.cancel() }
        ops.removeAll()
    }
    
}

// MARK: - Setup Views
extension PortfolioCollectionViewController {
    func setupViews() {
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - CollectionView Datasource Methods
extension PortfolioCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = fetchedResultsController.object(at: indexPath)
        let assetVC = AssetViewController(
            code: asset.code,
            assetName: asset.name,
            exchange: asset.exchange,
            currency: asset.currency,
            type: asset.type,
            logoURL: URL(string: asset.logo)
        )
        assetVC.callback = { [weak self] in
            guard let self = self else { return }
            self.setupWebSockets()
        }
        let navigationVC = UINavigationController(rootViewController: assetVC)
        present(navigationVC, animated: true, completion: nil)
        collectionView.deselectItem(at: indexPath, animated: true)
        webSocketManager.close()
    }
    
}

// MARK: - NSFetchedResultsController Delegate Methods
extension PortfolioCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<Section, PortfolioCellData> else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }
        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Section, PortfolioCellData>
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers
        let newValue = reloadIdentifiers.compactMap { itemId -> Asset? in
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemId) else { return nil }
            return existingObject as? Asset
        }
        let insertedAssets = newValue.filter { newItem in
            !currentSnapshot.itemIdentifiers.contains { newItem.uid == $0.uid }
        }
        if !insertedAssets.isEmpty {
            insertedAssets.forEach{ newAsset in
                fetchAssets([newAsset])
                if newAsset.type == .stock {
                    if webSocketManager.stockWebSocket == nil {
                        webSocketManager.createStockSession(delegate: self)
                        webSocketManager.subscribe(stockSymbols: [newAsset.code])
                    } else {
                        webSocketManager.subscribe(stockSymbols: [newAsset.code])
                    }
                } else {
                    if webSocketManager.cryptoWebSocket == nil {
                        webSocketManager.createCryptoSession(delegate: self)
                        webSocketManager.subscribe(cryptoSymbols: [newAsset.code])
                    } else {
                        webSocketManager.subscribe(cryptoSymbols: [newAsset.code])
                    }
                }
            }
        }
        let deletedAssets = currentSnapshot.itemIdentifiers.filter { oldItem in
            !newValue.contains { oldItem.uid == $0.uid }
        }
        if !deletedAssets.isEmpty {
            deletedAssets.forEach { asset in
                if asset.type == .stock {
                    self.webSocketManager.unsubscribe(stockSymbols: [asset.code])
                } else {
                    self.webSocketManager.unsubscribe(cryptoSymbols: [asset.code])
                }
            }
            print("Remove socket \(deletedAssets)")
        }
        updateDataSource(assets: newValue)
    }
    
}

// MARK: - URLSessionWebSocket Methods
extension PortfolioCollectionViewController: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Did connect to socket")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Did close connection with reason")
    }
    
    func createWebSocketSessions() {
        if let _ = fetchedResultsController.fetchedObjects?.filter({ $0.type == .stock && $0.exchange == "US"}).first {
            webSocketManager.createStockSession(delegate: self)
        }
        
        if let _ = fetchedResultsController.fetchedObjects?.filter({ $0.type == .crypto}).first {
            webSocketManager.createCryptoSession(delegate: self)
        }
    }
    
    func subscribe() {
        if let stocks = fetchedResultsController.fetchedObjects?.filter({ $0.type == .stock && $0.exchange == "US"}) {
            let stockTickers = stocks.compactMap({ $0.code })
            webSocketManager.subscribe(stockSymbols: stockTickers)
        }
        
        if let cryptos = fetchedResultsController.fetchedObjects?.filter({ $0.type == .crypto}) {
            let cryptoTickers = cryptos.compactMap({ $0.code })
            webSocketManager.subscribe(cryptoSymbols: cryptoTickers)
        }
    }
    
    func setupWebSockets() {
        createWebSocketSessions()
        subscribe()
        webSocketManager.stockReceive()
        webSocketManager.cryptoReceive()
        }
    
    func updateQuoteCoreDataItems(stockCache: [String: QuoteWebSocketResponse]) {
        stockCache.forEach{ [weak self] _, value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "US") {
                $0?.currentPrice = value.price
            }
        }
    }
    
    func updateCryptoCoreDataItems(cryptoCache: [String: CryptoWebSocketResponse]) {
        cryptoCache.forEach{ [weak self] _, value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "CC") {
                $0?.currentPrice = Double(value.price) ?? 0
                $0?.priceChangePercent = Double(value.dailyChangePercentage) ?? 0
                $0?.priceChange = Double(value.dailyDifferencePrice) ?? 0
            }
        }
    }
    
}

extension PortfolioCollectionViewController: WebSocketManagerDelegate {
    
    func updateStockCacheData(with stockCache: [String: QuoteWebSocketResponse]) {
        updateQuoteCoreDataItems(stockCache: stockCache)
    }
    
    func updateCryptoCacheData(with cryptoCache: [String: CryptoWebSocketResponse]) {
        updateCryptoCoreDataItems(cryptoCache: cryptoCache)
    }
    
}

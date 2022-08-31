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
    
    private let updateAssetCacheQueue = DispatchQueue(label: "updateAssetCacheQueue", qos: .background, target: .global())
    private let networkManager = PortfolioNetworkManager()
    private let storageManager = StorageManager.shared
    private let webSocketManager = WebSocketManager()
    private var webSocketStockCache = [String:QuoteWebSocketResponse]()
    private var webSocketCryptoCache = [String:CryptoWebSocketResponse]()
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
        setupWebSockets()
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAssetCacheQueue.async {
                self?.updateQuoteItemsWithTimer()
                self?.updateCryptoItemsWithTimer()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
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
//                    guard let assets = self.fetchedResultsController?.fetchedObjects else {
//                        self.showAlert(title: "No fetchedObjects", message: "Try again")
//                        return }
//                    self.updateDataSource(assets: assets)
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
    }
    
    func updateDataSource(assets: [Asset]) {
        //        let sections = [Section(type: .first, items: assets)]
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
    
    //    func numberOfSections(in collectionView: UICollectionView) -> Int {
    //        guard let sections = fetchedResultsController?.sections else { return 0 }
    //        return sections.count
    //    }
    
    //    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    //        guard let sections = fetchedResultsController?.sections else { return 0 }
    //        let sectionInfo = sections[section]
    //        return sectionInfo.numberOfObjects
    //    }
    
    //    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    //        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PortfolioCollectionViewCell.identifier, for: indexPath) as! PortfolioCollectionViewCell
    //        guard let asset = fetchedResultsController?.object(at: indexPath) else { return cell }
    //        let url = URL(string: asset.logo)
    //        cell.configure(
    //            uid: asset.uid,
    //            logo: url,
    //            assetName: asset.code,
    //            assetDescription: asset.name,
    //            chartData: asset.chartData,
    //            price: asset.currentPrice,
    //            currency: asset.currency,
    //            priceChange: asset.priceChange,
    //            pricePercentChange: asset.priceChangePercent)
    //        return cell
    //    }
    
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    //        return 16
    //    }
    //
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    //        CGSize(width: collectionView.frame.size.width, height: 48)
    //    }
    //
    //    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    //        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? SectionHeaderView {
    //            guard let sections = fetchedResultsController?.sections else { return sectionHeader }
    //            let asset = AssetType(rawValue: Int16(sections[indexPath.section].name) ?? 0)
    //            sectionHeader.label.text = asset?.assetName
    //            return sectionHeader
    //        }
    //        return UICollectionReusableView()
    //    }
    
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    //        CGSize(width: collectionView.frame.size.width, height: 40)
    //    }
    //
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    //        UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
    //    }
    
    // MARK: - CollectionView Delegate Methods
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

// MARK: - URLSessionWebSocket Delegate Methods
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
    
    func updateWebSocketStockCache(for quoteResponse: QuoteWebSocketResponse) {
        webSocketStockCache[quoteResponse.code] = quoteResponse
    }
    
    func updateWebSocketCryptoCache(for quoteResponse: CryptoWebSocketResponse) {
        webSocketCryptoCache[quoteResponse.code] = quoteResponse
    }
    
    @objc func updateCoreDataWithWebSocketCache() {
        webSocketStockCache.forEach{ [weak self] _, value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "US") {
                $0?.currentPrice = value.price
            }
        }
        
        webSocketCryptoCache.forEach{ [weak self] _, value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "CC") {
                $0?.currentPrice = Double(value.price) ?? 0
                $0?.priceChangePercent = Double(value.dailyChangePercentage) ?? 0
                $0?.priceChange = Double(value.dailyDifferencePrice) ?? 0
            }
        }
        webSocketStockCache.removeAll()
        webSocketCryptoCache.removeAll()
        print("TIMER RAN")
    }
    
    func setupWebSockets() {
        createWebSocketSessions()
        subscribe()
        webSocketManager.stockReceive { [weak self] value in
//            self?.storageManager.modifyAsset(code: value.code, exchange: "US") {
//                $0?.currentPrice = value.price
//            }
            self?.updateWebSocketStockCache(for: value)
        }
        
        webSocketManager.cryptoReceive { [weak self] value in
            self?.updateWebSocketCryptoCache(for: value)
//            self?.storageManager.modifyAsset(code: value.code, exchange: "CC") {
//                $0?.currentPrice = Double(value.price) ?? 0
//                $0?.priceChangePercent = Double(value.dailyChangePercentage) ?? 0
//                $0?.priceChange = Double(value.dailyDifferencePrice) ?? 0
            }
        }
//    }
    
    func updateQuoteItemsWithTimer() {
        webSocketStockCache.forEach{ [weak self] _, value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "US") {
                $0?.currentPrice = value.price
            }
        }
        webSocketStockCache.removeAll()
    }
    
    func updateCryptoItemsWithTimer() {
        webSocketCryptoCache.forEach{ [weak self] _, value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "CC") {
                $0?.currentPrice = Double(value.price) ?? 0
                $0?.priceChangePercent = Double(value.dailyChangePercentage) ?? 0
                $0?.priceChange = Double(value.dailyDifferencePrice) ?? 0
            }
        }
        webSocketCryptoCache.removeAll()
    }
    
//    func updateVisibleStockItem(collectionView: UICollectionView, itemID: String, item: QuoteWebSocketResponse) {
//        let visibleIndexpathes = collectionView.indexPathsForVisibleItems
//        let visibleItems = visibleIndexpathes.filter({ dataSource?.itemIdentifier(for: $0)?.code == itemID })
//        let cellsToUpdate = visibleItems.compactMap({ [weak self] index in
//            self?.collectionView.cellForItem(at: index) as? PortfolioCollectionViewCell
//        })
//        cellsToUpdate.forEach({ cell in
//            cell.updatePrice(
//                price: item.price,
//                currency: "USD",
//                priceChange: 0,
//                pricePercentChange: 0)
//        })
//    }
    
//    func updateVisibleCryptoItem(collectionView: UICollectionView, itemID: String, item: CryptoWebSocketResponse) {
//        let visibleIndexpathes = collectionView.indexPathsForVisibleItems
//        let visibleItems = visibleIndexpathes.filter({ dataSource?.itemIdentifier(for: $0)?.code == itemID })
//        let cellsToUpdate = visibleItems.compactMap({ [weak self] index in
//            self?.collectionView.cellForItem(at: index) as? PortfolioCollectionViewCell
//        })
//        cellsToUpdate.forEach({ cell in
//            cell.updatePrice(
//                price: Double(item.price) ?? 0,
//                currency: "USD",
//                priceChange: Double(item.dailyDifferencePrice) ?? 0,
//                pricePercentChange: Double(item.dailyChangePercentage) ?? 0)
//        })
//    }
    
}

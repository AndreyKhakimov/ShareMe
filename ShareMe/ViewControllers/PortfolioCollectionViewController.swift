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
        var items: [NSManagedObjectID]
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
    private var webSocketStockUpdates = [String:QuoteWebSocketResponse]()
    private var webSocketCryptoUpdates = [String:CryptoWebSocketResponse]()
    private lazy var managedObjectContext = storageManager.privateContext
    private var dataSource: UICollectionViewDiffableDataSource<String, NSManagedObjectID>?
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
//        collectionView.dataSource = dataSource
        //        collectionView.dataSource = self
        collectionView.delegate = self
//        fetchedResultsController = storageManager.fetchedResultsController
//        fetchedResultsController.performFetch()
        fetchedResultsController.delegate = self
//        storageManager.performFetch(fetchedResultsController: fetchedResultsController!)
        dataSource = createDatasource()
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        fetchAssets(fetchedResultsController.fetchedObjects ?? [Asset]())
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
    
    private func createDatasource() -> UICollectionViewDiffableDataSource<String, NSManagedObjectID> {
        let dataSource: UICollectionViewDiffableDataSource<String, NSManagedObjectID> = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [fetchedResultsController] collectionView, indexPath, itemIdentifier in
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
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "header",
                for: indexPath) as? SectionHeaderView
            view?.label.text = "Test"
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
    
//    func updateDataSource(assets: [Asset]) {
//        //        let sections = [Section(type: .first, items: assets)]
//        var sections = [Section]()
//        let stockAssets = assets
//            .filter({ $0.type == .stock })
//            .map { PortfolioCellData(asset: $0) }
//        let cryptoAssets = assets
//            .filter({ $0.type == .crypto })
//            .map { PortfolioCellData(asset: $0) }
//
//        if !stockAssets.isEmpty {
//            sections.append(Section(type: .stock, items: stockAssets))
//        }
//
//        if !cryptoAssets.isEmpty {
//            sections.append(Section(type: .crypto, items: cryptoAssets))
//        }
//
//        if !sections.isEmpty {
//            var snapshot = NSDiffableDataSourceSnapshot<Section, PortfolioCellData>()
//            snapshot.appendSections(sections)
//
//            sections.forEach { section in
//                snapshot.appendItems(section.items, toSection: section)
//            }
//            dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
//        }
//    }
    
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
        guard let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<String, NSManagedObjectID> else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)
        
        let shouldAnimate = collectionView.numberOfSections != 0
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>, animatingDifferences: shouldAnimate)
    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//        case .insert:
//            if let newAsset = anObject as? Asset {
//                fetchAssets([newAsset])
//                if newAsset.type == .stock {
//                    if webSocketManager.stockWebSocket == nil {
//                        webSocketManager.createStockSession(delegate: self)
//                        webSocketManager.subscribe(stockSymbols: [newAsset.code])
//                    } else {
//                        webSocketManager.subscribe(stockSymbols: [newAsset.code])
//                    }
//                } else {
//                    if webSocketManager.cryptoWebSocket == nil {
//                        webSocketManager.createCryptoSession(delegate: self)
//                        webSocketManager.subscribe(cryptoSymbols: [newAsset.code])
//                    } else {
//                        webSocketManager.subscribe(cryptoSymbols: [newAsset.code])
//                    }
//                }
//            }
//            ops.append(BlockOperation(block: { [weak self] in
//                self?.collectionView.insertItems(at: [newIndexPath!])
//            }))
//        case .delete:
//            if let indexPath = indexPath {
//                ops.append(BlockOperation(block: { [weak self] in
//                    guard let self = self, let asset = anObject as? Asset else { return }
//                    if asset.type == .stock {
//                        self.webSocketManager.unsubscribe(stockSymbols: [asset.code])
//                    } else {
//                        self.webSocketManager.unsubscribe(cryptoSymbols: [asset.code])
//                    }
//                    self.collectionView.deleteItems(at: [indexPath])
//                }))
//            }
//        case .update:
//            ops.append(BlockOperation(block: { [weak self] in
//                UIView.performWithoutAnimation({
//                    self?.collectionView.reloadItems(at: [indexPath!])
//                })
//            }))
//        case .move:
//            ops.append(BlockOperation(block: { [weak self] in
//                self?.collectionView.moveItem(at: indexPath!, to: newIndexPath!)
//            }))
//        @unknown default:
//            break
//        }
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        let indexSection = IndexSet(integer: sectionIndex)
//        switch type {
//        case .insert:
//            ops.append(BlockOperation(block: { [weak self] in
//                self?.collectionView.insertSections(indexSection)
//            }))
//            break
//        case .delete:
//            ops.append(BlockOperation(block: { [weak self] in
//                self?.collectionView.deleteSections(indexSection)
//            }))
//        case .move:
//            break
//        case .update:
//            ops.append(BlockOperation(block: { [weak self] in
//                self?.collectionView.reloadSections(indexSection)
//            }))
//        @unknown default:
//            break
//        }
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        collectionView.performBatchUpdates({ () -> Void in
//            UIView.performWithoutAnimation {
//                for op: BlockOperation in self.ops { op.start() }
//            }
//        }, completion: { (finished) -> Void in self.ops.removeAll() })
//    }
//
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
    
    func setupWebSockets() {
        createWebSocketSessions()
        subscribe()
        webSocketManager.stockReceive { [weak self] value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "US") {
                $0?.currentPrice = value.price
            }
//            DispatchQueue.main.async {
//                self?.updateDataSource(assets: self?.fetchedResultsController?.fetchedObjects ?? [])
//            }
        }
        
        webSocketManager.cryptoReceive { [weak self] value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "CC") {
                $0?.currentPrice = Double(value.price) ?? 0
                $0?.priceChangePercent = Double(value.dailyChangePercentage) ?? 0
                $0?.priceChange = Double(value.dailyDifferencePrice) ?? 0
            }
//            DispatchQueue.main.async {
//                self?.updateDataSource(assets: self?.fetchedResultsController?.fetchedObjects ?? [])
//            }
        }
    }
    
    func updateVisibleItems(collectionView: UICollectionView, itemID: String) {
        let visibleItems = collectionView.indexPathsForVisibleItems
        visibleItems
    }
    
}

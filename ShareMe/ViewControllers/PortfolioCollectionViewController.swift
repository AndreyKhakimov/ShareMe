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
    
    private struct Section {
        var type: AssetType
        var items: [Asset]
    }
    
    private var fetchedResultsController: NSFetchedResultsController<Asset>?
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        collectionView.dataSource = self
        collectionView.delegate = self
        fetchedResultsController = storageManager.fetchedResultsController
        fetchedResultsController?.delegate = self
        storageManager.performFetch(fetchedResultsController: fetchedResultsController!)
        fetchAssets(fetchedResultsController?.fetchedObjects ?? [Asset]())
        createWebSocketSessions()
        subscribe()
        webSocketManager.stockReceive { [weak self] value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "US") {
                $0?.currentPrice = value.price
            }
        }
        
        webSocketManager.cryptoReceive { [weak self] value in
            self?.storageManager.modifyAsset(code: value.code, exchange: "CC") {
                $0?.currentPrice = Double(value.price) ?? 0
                $0?.priceChangePercent = Double(value.dailyChangePercentage) ?? 0
                $0?.priceChange = Double(value.dailyDifferencePrice) ?? 0
            }
        }
    }
    
    private func fetchAssets(_ assets: [Asset]) {
        networkManager.getAssets(assets: assets) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.collectionView.reloadData()
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
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
extension PortfolioCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sections = fetchedResultsController?.sections else { return 0 }
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections else { return 0 }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PortfolioCollectionViewCell.identifier, for: indexPath) as! PortfolioCollectionViewCell
        guard let asset = fetchedResultsController?.object(at: indexPath) else { return cell }
        let url = URL(string: asset.logo)
        cell.configure(
            logo: url,
            assetName: asset.code,
            assetDescription: asset.name,
            chartData: asset.chartData,
            price: asset.currentPrice,
            currency: asset.currency,
            priceChange: asset.priceChange,
            pricePercentChange: asset.priceChangePercent)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.size.width, height: 48)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? SectionHeaderView {
            guard let sections = fetchedResultsController?.sections else { return sectionHeader }
            let asset = AssetType(rawValue: Int16(sections[indexPath.section].name) ?? 0)
            sectionHeader.label.text = asset?.assetName
            return sectionHeader
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
    }
    
    // MARK: - CollectionView Delegate Methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = fetchedResultsController!.object(at: indexPath)
        let assetVC = AssetViewController(
            code: asset.code,
            assetName: asset.name,
            exchange: asset.exchange,
            currency: asset.currency,
            type: asset.type,
            logoURL: URL(string: asset.logo)
        )
        
        let navigationVC = UINavigationController(rootViewController: assetVC)
        present(navigationVC, animated: true, completion: nil)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - NSFetchedResultsController Delegate Methods
extension PortfolioCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newAsset = anObject as? Asset {
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
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.insertItems(at: [newIndexPath!])
            }))
        case .delete:
            if let indexPath = indexPath {
                ops.append(BlockOperation(block: { [weak self] in
                    guard let self = self, let asset = anObject as? Asset else { return }
                    if asset.type == .stock {
                        self.webSocketManager.unsubscribe(stockSymbols: [asset.code])
                    } else {
                        self.webSocketManager.unsubscribe(cryptoSymbols: [asset.code])
                    }
                    self.collectionView.deleteItems(at: [indexPath])
                }))
            }
        case .update:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.reloadItems(at: [indexPath!])
            }))
        case .move:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.moveItem(at: indexPath!, to: newIndexPath!)
            }))
        @unknown default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSection = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.insertSections(indexSection)
            }))
            break
        case .delete:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.deleteSections(indexSection)
            }))
        case .move:
            break
        case .update:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.reloadSections(indexSection)
            }))
        @unknown default:
            break
        }
    }
    
    //    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    //        collectionView.performBatchUpdates({ () -> Void in
    //            for op: BlockOperation in self.ops { op.start() }
    //        }, completion: { (finished) -> Void in self.ops.removeAll() })
    //    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ () -> Void in
            for op: BlockOperation in self.ops { op.start() }
        }, completion: { (finished) -> Void in self.ops.removeAll() })
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
        if let _ = fetchedResultsController?.fetchedObjects?.filter({ $0.type == .stock && $0.exchange == "US"}) {
            webSocketManager.createStockSession(delegate: self)
        }
        
        if let _ = fetchedResultsController?.fetchedObjects?.filter({ $0.type == .crypto}) {
            webSocketManager.createCryptoSession(delegate: self)
        }
    }
    
    func subscribe() {
        if let stocks = fetchedResultsController?.fetchedObjects?.filter({ $0.type == .stock && $0.exchange == "US"}) {
            let stockTickers = stocks.compactMap({ $0.code })
            webSocketManager.subscribe(stockSymbols: stockTickers)
        }
        
        if let cryptos = fetchedResultsController?.fetchedObjects?.filter({ $0.type == .crypto}) {
            let cryptoTickers = cryptos.compactMap({ $0.code })
            webSocketManager.subscribe(cryptoSymbols: cryptoTickers)
        }
    }
    
}

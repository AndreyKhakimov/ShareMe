//
//  PortfolioCollectionViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 25.05.2022.
//

import UIKit
import SnapKit

class PortfolioCollectionViewController: UIViewController {
    
    private struct Section {
        var type: AssetType
        var items: [PortfolioAsset]
    }
    
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
    var assets: [Asset]?
    private var portfolioAssets = [PortfolioAsset]() {
        didSet {
            sections = AssetType.allCases.map({ assetType in
                Section(type: assetType, items: portfolioAssets.filter { $0.type == assetType })
            }).filter { !$0.items.isEmpty }
        }
    }
    private var sections = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        collectionView.dataSource = self
        collectionView.delegate = self
        assets = storageManager.getAllAssets()
        fetchAssets(assets ?? [Asset]())
    }
    
    private func fetchAssets(_ assets: [Asset]) {
        networkManager.getAssets(assets: assets) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let portfolioAssets):
                    self.portfolioAssets = portfolioAssets
                    self.collectionView.reloadData()
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
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
        sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PortfolioCollectionViewCell.identifier, for: indexPath) as! PortfolioCollectionViewCell
        let asset = sections[indexPath.section].items[indexPath.row]
        
        cell.configure(
            logo: asset.logo,
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
            sectionHeader.label.text = sections[indexPath.section].type.assetName
            return sectionHeader
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.frame.size.width, height: 40)
    }
    
    // MARK: - CollectionView Delegate Methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = sections[indexPath.section].items[indexPath.row]
        let assetVC = AssetViewController()
        assetVC.code = asset.code
        assetVC.assetName = asset.name
        assetVC.exchange = asset.exchange
        assetVC.currency = asset.currency
        assetVC.type = assets?[indexPath.row].type ?? .stock
        assetVC.logoURL = asset.logo
        let navigationVC = UINavigationController(rootViewController: assetVC)
        present(navigationVC, animated: true, completion: nil)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

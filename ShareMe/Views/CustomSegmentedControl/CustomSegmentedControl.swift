//
//  CustomSegmentedControl.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 09.05.2022.
//

import UIKit
import SnapKit

@IBDesignable
class CustomSegmentedControl: UIControl {
    
    private var buttons = [UIButton]()
    
    var items = [String]() {
        didSet {
            updateView(force: true)
        }
    }
    
    private let selector = UIView()
    
    var selectedSegmentIndex = 0 {
        didSet {
            configureColors()
            setNeedsLayout()
        }
    }
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 28
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    @IBInspectable
    var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable
    var borderColor: UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable
    var textColor: UIColor = .lightGray {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var selectorColor: UIColor = .systemBlue {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var selectorTextColor: UIColor = .white {
        didSet {
            updateView()
        }
    }
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        configureSelector()
        configureStackView()
    }
    
    private func updateView(force: Bool = false) {
        if force {
            configureButtons()
        }
        configureColors()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selector.layer.cornerRadius = bounds.height / 2
        //        selector.frame = stackView.arrangedSubviews[selectedSegmentIndex].frame
        let adjustedWidth = frame.width - stackView.spacing * CGFloat(buttons.count - 1)
        let xSpacingPosition = stackView.spacing * CGFloat(selectedSegmentIndex)
        selector.frame = CGRect(
            x: adjustedWidth / CGFloat(buttons.count) * CGFloat(selectedSegmentIndex) + xSpacingPosition,
            y: 0,
            width: adjustedWidth / CGFloat(buttons.count),
            height: frame.height
        )
        layer.cornerRadius = frame.height / 2
    }
    
    private func configureButtons() {
        buttons.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, buttonTitle) in items.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(buttonTitle, for: .normal)
            button.setTitleColor(textColor, for: .normal)
            button.addTarget(self, action: #selector(buttonPressed(button:)), for: .touchUpInside)
            button.tag = index
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    private func configureSelector() {
        addSubview(selector)
    }
    
    private func configureColors() {
        selector.backgroundColor = selectorColor
        stackView.arrangedSubviews
            .compactMap { $0 as? UIButton }
            .enumerated()
            .forEach { index, button in
                let isButtonSelected = index == selectedSegmentIndex
                let titleColor = isButtonSelected ? selectorTextColor : textColor
                button.setTitleColor(titleColor, for: .normal)
            }
    }
    
    private func configureStackView() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func buttonPressed(button: UIButton) {
        self.selectedSegmentIndex = button.tag
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
        configureColors()
        sendActions(for: .valueChanged)
    }
    
}


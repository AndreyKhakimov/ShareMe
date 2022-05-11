//
//  SimpleChartView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 13.04.2022.
//

import UIKit

class SimpleChartView: UIView {
    
    var contentInsetX: CGFloat = 8 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    var contentInsetY: CGFloat = 8 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    var lineColor: UIColor? {
        didSet {
            chartLineLayer.strokeColor = (lineColor ?? tintColor).cgColor
        }
    }
    
    var gradientColor: UIColor? {
        didSet {
            chartGradientLayer.colors = [
                (gradientColor ?? tintColor.withAlphaComponent(0.5)).cgColor,
                (backgroundColor ?? UIColor.white.withAlphaComponent(0)).cgColor
            ]
        }
    }
    
    private var contentInset: UIEdgeInsets {
        UIEdgeInsets(top: contentInsetY, left: contentInsetX, bottom: contentInsetY, right: contentInsetX)
    }
    
    var chartData = [Double]() {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    private var chartLineLayer = CAShapeLayer()
    private var chartGradientLayerMask = CAShapeLayer()
    private var chartGradientLayer = CAGradientLayer()
    private var errorLabel = UILabel()
    
    private var adjustedBounds: CGRect {
        bounds.inset(by: contentInset)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chartGradientLayer.frame = bounds
        chartLineLayer.frame = bounds
        chartGradientLayerMask.frame = bounds
        errorLabel.frame = adjustedBounds
        // TODO: - Make label text
        if chartData.count > 1 {
            chartLineLayer.path = makeChartPath().cgPath
            chartGradientLayerMask.path = makeChartMaskPath().cgPath
            chartGradientLayer.mask = chartGradientLayerMask
            chartLineLayer.isHidden = false
            chartGradientLayer.isHidden = false
            errorLabel.isHidden = true
        } else {
            chartLineLayer.isHidden = true
            chartGradientLayer.isHidden = true
            errorLabel.isHidden = false
        }
    }
    
    private func chartPositions() -> [CGPoint] {
        let chartLastIndex = chartData.count - 1
        let chartMaxValue = chartData.max() ?? 0
        let chartMinValue = chartData.min() ?? 0
        let chartMaxAdjustedValue = chartMaxValue - chartMinValue
        let chartPositions = chartData.enumerated().map { index, value -> CGPoint in
            let xPosition = (Double(index) / Double(chartLastIndex)) * adjustedBounds.width
            let yPosition = ((value - chartMinValue) / chartMaxAdjustedValue) * adjustedBounds.height
            return CGPoint(
                x: xPosition + adjustedBounds.origin.x,
                y: adjustedBounds.height - yPosition + adjustedBounds.origin.y
            )
        }
        return chartPositions
    }
    
    private func makeChartPath() -> UIBezierPath {
        guard !chartData.isEmpty else { return UIBezierPath() }
        let path = UIBezierPath()
        let chartLastIndex = chartData.count - 1
        let chartPositions = chartPositions()
        path.move(to: chartPositions.first ?? .zero)
        // TODO: - Fix Fatal error: Range requires lowerBound <= upperBound when chartLastIndex = 0
        for chartPosition in chartPositions[1...chartLastIndex] {
            path.addLine(to: chartPosition)
        }
        return path
    }
    
    private func makeChartMaskPath() -> UIBezierPath {
        let path = makeChartPath()
        path.addLine(to: CGPoint(x: adjustedBounds.maxX, y: adjustedBounds.maxY))
        path.addLine(to: CGPoint(x: adjustedBounds.origin.x, y: adjustedBounds.maxY))
        path.close()
        return path
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        layer.addSublayer(chartGradientLayer)
        layer.addSublayer(chartLineLayer)
        
        chartGradientLayer.colors = [
            (gradientColor ?? tintColor.withAlphaComponent(0.5)).cgColor,
            (backgroundColor ?? UIColor.white.withAlphaComponent(0)).cgColor
        ]
        chartLineLayer.strokeColor = (lineColor ?? tintColor).cgColor
        chartLineLayer.lineWidth = 2
        chartLineLayer.fillColor = nil
    }
    
}


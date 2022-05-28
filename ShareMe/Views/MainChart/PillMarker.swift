//
//  PillMarker.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 09.05.2022.
//

import Charts

class PillMarker: MarkerImage {

//    private (set) var color: UIColor
    private (set) var font: UIFont
    private (set) var textColor: UIColor
    private var labelText: String = ""
    private var attrs: [NSAttributedString.Key: AnyObject]!

    static let formatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.unitsStyle = .short
        return f
    }()

    init(color: UIColor, font: UIFont, textColor: UIColor) {
//        self.color = color
        self.font = font
        self.textColor = textColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attrs = [.font: font, .paragraphStyle: paragraphStyle, .foregroundColor: textColor, .baselineOffset: NSNumber(value: -4)]
        super.init()
    }

    override func draw(context: CGContext, point: CGPoint) {
        let chartWidth = chartView?.bounds.width ?? 0
        let chartHeight = chartView?.bounds.height ?? 0
        // custom padding around text
        let labelWidth = labelText.size(withAttributes: attrs).width + 8
        // if you modify labelHeigh you will have to tweak baselineOffset in attrs
        let labelHeight = labelText.size(withAttributes: attrs).height + 4
        let maxYPosition = chartHeight - labelHeight
        let minYPosition:CGFloat = 0
        // place pill above the marker, centered along x
        var rectangle = CGRect(x: point.x, y: point.y, width: labelWidth, height: labelHeight)
        print(UIScreen.main.bounds.size.width)
        if point.x > chartWidth * 0.5 {
            rectangle.origin.x -= rectangle.width + 8
        } else {
            rectangle.origin.x = point.x + 8
        }
        let spacing: CGFloat = 8
        rectangle.origin.y -= rectangle.height + spacing
        rectangle.origin.y = min(maxYPosition, rectangle.origin.y)
        rectangle.origin.y = max(minYPosition, rectangle.origin.y)
        // rounded rect
        let clipPath = UIBezierPath(roundedRect: rectangle, cornerRadius: 6.0).cgPath
        context.addPath(clipPath)
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.black.cgColor)
        context.closePath()
        context.drawPath(using: .fillStroke)

        // add the text
        labelText.draw(with: rectangle, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
    }

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let candleEntry = entry as? CandleChartDataEntry
        let formatedOpen = String(format: "%.2f", candleEntry?.open ?? 0)
        let formatedClose = String(format: "%.2f", candleEntry?.close ?? 0)
        let formatedHigh = String(format: "%.2f", candleEntry?.high ?? 0)
        let formatedLow = String(format: "%.2f", candleEntry?.low ?? 0)
        
        labelText = "Open: \(formatedOpen)\nClose: \(formatedClose)\nHigh: \(formatedHigh)\nLow: \(formatedLow)"
    }
}

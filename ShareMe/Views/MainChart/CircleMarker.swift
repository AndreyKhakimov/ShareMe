//
//  CircleMarker.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 10.05.2022.
//

import Charts

class CircleMarker: MarkerImage {
    
    private var color: UIColor
    private var radius: CGFloat = 4
    
    init(color: UIColor) {
        self.color = color
        super.init()
    }
    
    override func draw(context: CGContext, point: CGPoint) {
        let circleRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: circleRect)
        
        context.restoreGState()
    }
}

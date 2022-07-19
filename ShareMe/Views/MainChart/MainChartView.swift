//
//  MainChartView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 08.05.2022.
//

import Charts

struct ChartEntryData {
    let data: Double
    let date: String
}

class MainChartView: LineChartView {
    
    var chartData = [ChartEntryData]() {
        didSet {
            setData()
        }
    }
    
    func prepareEntriesFromData() -> [ChartDataEntry] {
        guard !chartData.isEmpty else { return [ChartDataEntry]() }
        let chartLastIndex = chartData.count - 1
        let chartEntries = chartData.enumerated().map { index, value -> ChartDataEntry in
            let xPosition = (Double(index) / Double(chartLastIndex))
            let yPosition = value.data
            return ChartDataEntry(x: xPosition, y: yPosition, data: value.date)
        }
        return chartEntries
        
    }
    
    func setData() {
        let entries = prepareEntriesFromData()
        let set = LineChartDataSet(entries: entries)
        set.label = nil
        set.mode = .cubicBezier
        set.lineWidth = 2
        set.drawValuesEnabled = false
        set.drawCirclesEnabled = false
        set.drawHorizontalHighlightIndicatorEnabled = false
        set.highlightColor = .label
        set.setColor(.label)
        
        let data = LineChartData(dataSet: set)
        self.data = data
    }
    
}

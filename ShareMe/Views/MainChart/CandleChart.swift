//
//  CandleChart.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 26.05.2022.
//

import Charts

struct CandleChartEntry {
    let date: String
    let open, high, low, close: Double
    let volume: Int
}

class CandleChartView: CandleStickChartView {
    
    var chartData = [CandleChartEntry]() {
        didSet {
            setData()
        }
    }
    
    func prepareEntriesFromData() -> [CandleChartDataEntry] {
        guard !chartData.isEmpty else { return [CandleChartDataEntry]() }
        let chartEntries = chartData.enumerated().map { index, value -> CandleChartDataEntry in
            let xPosition = Double(index)
            return CandleChartDataEntry(x: xPosition, shadowH: value.high, shadowL: value.low, open: value.open, close: value.close, data: value.date)
        }
        return chartEntries
        
    }
    
    func setData() {
        let entries = prepareEntriesFromData()
        let set = CandleChartDataSet(entries: entries, label: "Candles")
        set.highlightColor = .black
        set.increasingColor = .systemRed
        set.decreasingColor = .systemGreen
        set.increasingFilled = true
        set.decreasingFilled = true
        set.shadowColorSameAsCandle = true
        set.drawValuesEnabled = false
        set.drawHorizontalHighlightIndicatorEnabled = false
        
        let data = CandleChartData(dataSet: set)
        self.data = data
    }
    
}

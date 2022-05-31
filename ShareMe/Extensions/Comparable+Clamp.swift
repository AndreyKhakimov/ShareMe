//
//  Comparable+Clamp.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 30.05.2022.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

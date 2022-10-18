//
//  SVGImageProcessor.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 18.10.2022.
//

import UIKit
import Kingfisher
import SVGKit

public struct SVGImgProcessor:ImageProcessor {
    public var identifier: String = "com.appidentifier.SVGImageProcessor"
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            if let imagePng = UIImage(data: data) {
                return imagePng
            } else {
                let imageSvg = SVGKImage(data: data)
                return imageSvg?.uiImage
            }
        }
    }
}

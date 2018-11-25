//
//  UIImageView+AsyncAspectFit.swift
//  Clipboard
//
//  Created by Bill Wu on 11/24/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func setImage(_ originalImage: UIImage, maxImageWidth: CGFloat?, maxImageHeight: CGFloat?) {
        var image = originalImage
        //self.image = nil
        
        //DispatchQueue.global(qos: .utility).async {
            let size: CGSize = originalImage.size
            var scaleFactor: CGFloat?
            if let maxWidth = maxImageWidth {
                if size.width > maxWidth {
                    // scale image down to fit width
                    scaleFactor = maxWidth / size.width
                    
                }
            }
            else if let maxHeight = maxImageHeight {
                if size.height > maxHeight {
                    // scale image down to fit height
                    scaleFactor = maxHeight / size.height
                }
            }
            
            if let scale = scaleFactor {
                let newSize: CGSize = CGSize(width: size.width * scale, height: size.height * scale)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
                if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                    image = newImage
                }
                UIGraphicsEndImageContext()
            }
            
            //DispatchQueue.main.async {
                self.image = image
            //}
        //}
    }
}

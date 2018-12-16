//
//  Toast.swift
//  Clips
//
//  Created by Bill Wu on 12/9/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class Toast: UIView {
    
    private var imageView: UIImageView!
    private var label: UILabel!
    
    convenience init(message: String) {
        let frameWidth: CGFloat = 150, frameHeight: CGFloat = 150
        let frameX: CGFloat = (UIScreen.main.bounds.size.width / 2) - (frameWidth / 2), frameY: CGFloat = (UIScreen.main.bounds.size.height / 2) - (frameHeight / 2)
        self.init(frame: CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight))
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        self.alpha = 0
        
        let padding: CGFloat = 15
        let innerFrame: CGRect = CGRect(x: padding, y: padding, width: (self.frame.size.width - 2 * padding), height: (self.frame.size.height - 2 * padding))
        let centerX: CGFloat = self.frame.size.width / 2
        
        let imageWidth: CGFloat = 90, imageHeight: CGFloat = 90
        let imageX: CGFloat = centerX - (imageWidth / 2), imageY: CGFloat = innerFrame.minY
        self.imageView = UIImageView(frame: CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight))
        self.imageView.tintColor = UIColor.white
        self.imageView.image = UIImage(named: "Checkmark")
        self.addSubview(self.imageView)
        
        let labelWidth: CGFloat = 120, labelHeight: CGFloat = 20
        let labelX: CGFloat = centerX - (labelWidth / 2), labelY: CGFloat = innerFrame.maxY - labelHeight
        self.label = UILabel(frame: CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight))
        self.label.textColor = UIColor.white
        self.label.textAlignment = .center
        self.label.text = message
        self.addSubview(self.label)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

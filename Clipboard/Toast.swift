//
//  Toast.swift
//  Clipboard
//
//  Created by Bill Wu on 12/9/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class Toast: UIView {
    
    let circleLayer: CAShapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // set up circle layer
        let centerX: CGFloat = frame.size.width / 2, centerY: CGFloat = frame.size.height / 2
        let radius: CGFloat = frame.size.width / 4
        let circlePath: UIBezierPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        self.circleLayer.path = circlePath.cgPath
        self.circleLayer.strokeColor = UIColor.white.cgColor
        self.circleLayer.fillColor = UIColor.clear.cgColor
        self.circleLayer.lineWidth = 5
        self.circleLayer.strokeEnd = 0
        
        self.layer.addSublayer(self.circleLayer)
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

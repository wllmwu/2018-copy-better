//
//  KeyboardUpperButton.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 1/3/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit

class KeyboardUpperButton: UIButton {
    
    static let lightGrayColor: UIColor = UIColor.init(displayP3Red: 235.0 / 255, green: 237.0 / 255, blue: 240.0 / 255, alpha: 1)

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = self.isHighlighted ? KeyboardUpperButton.lightGrayColor : nil
    }
    
    private func setup() {
        self.layer.cornerRadius = 4
    }

}

//
//  KeyboardUpperButton.swift
//  Clips Keyboard
//
//  Created by William Wu on 1/3/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit

class KeyboardUpperButton: UIButton {

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
        self.backgroundColor = self.isHighlighted ? UIColor.systemGray4 : nil
    }
    
    private func setup() {
        self.layer.cornerRadius = 4
    }

}

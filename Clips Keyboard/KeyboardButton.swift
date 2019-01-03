//
//  KeyboardButton.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 1/3/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit

class KeyboardButton: UIButton {
    
    @IBInspectable var isControlKey: Bool = true
    //static let whiteColor: UIColor = UIColor.white
    //static let grayColor: UIColor = UIColor.init(displayP3Red: 162, green: 171, blue: 185, alpha: 1)
    @IBInspectable var defaultBackgroundColor: UIColor = UIColor.init(displayP3Red: 162, green: 171, blue: 185, alpha: 1)
    @IBInspectable var highlightedBackgroundColor: UIColor = UIColor.white
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = self.isHighlighted ? self.highlightedBackgroundColor : self.defaultBackgroundColor
    }
    
    private func setup() {
        self.layer.cornerRadius = 4
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowRadius = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.masksToBounds = false
        
        /*if self.isControlKey {
            self.defaultBackgroundColor = KeyboardButton.grayColor
            self.highlightedBackgroundColor = KeyboardButton.whiteColor
        }
        else {
            self.defaultBackgroundColor = KeyboardButton.whiteColor
            self.highlightedBackgroundColor = KeyboardButton.grayColor
        }*/
        self.backgroundColor = self.defaultBackgroundColor
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
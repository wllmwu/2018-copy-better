//
//  UIViewController+Toast.swift
//  Clipboard
//
//  Created by Bill Wu on 12/5/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showToast(message: String) {
        let labelWidth: CGFloat = 150, labelHeight: CGFloat = 150
        let labelX: CGFloat = UIScreen.main.bounds.size.width / 2 - labelWidth / 2
        let labelY: CGFloat = UIScreen.main.bounds.size.height / 2 - labelHeight
        let toastLabel: UILabel = UILabel(frame: CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight))
        toastLabel.text = message
        //toastLabel.font = UIFont.systemFont(ofSize: <#T##CGFloat#>)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.alpha = 1
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0
        }, completion: { (completed) in
            toastLabel.removeFromSuperview()
        })
    }
    
}

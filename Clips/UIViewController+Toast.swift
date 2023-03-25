//
//  UIViewController+Toast.swift
//  Clips
//
//  Created by William Wu on 12/5/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showToast(message: String) {
        if let window = UIApplication.shared.keyWindow {
            let toast: Toast = Toast(message: message)
            window.addSubview(toast)
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                toast.alpha = 1
            }, completion: { (completed) in
                UIView.animate(withDuration: 0.5, delay: 0.6, options: .curveEaseOut, animations: {
                    toast.alpha = 0
                }, completion: { (completed) in
                    toast.removeFromSuperview()
                })
            })
        }
    }
    
}

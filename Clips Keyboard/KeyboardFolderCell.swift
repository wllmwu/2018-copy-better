//
//  KeyboardFolderCell.swift
//  Copy Better Keyboard
//
//  Created by Bill Wu on 9/15/20.
//  Copyright © 2020 William Wu. All rights reserved.
//

import UIKit

enum Format {
    case folder, superfolder, favorites
}

class KeyboardFolderCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func setName(_ name: String?) {
        self.nameLabel.text = name
    }
    
    func setFormat(_ format: Format) {
        if format == .folder {
            self.imageView.image = UIImage(systemName: "folder.fill")
        }
        else if format == .superfolder {
            self.imageView.image = UIImage(systemName: "arrowshape.turn.up.left.fill")
        }
        else {
            self.imageView.image = UIImage(systemName: "star.square")
        }
    }
    
}

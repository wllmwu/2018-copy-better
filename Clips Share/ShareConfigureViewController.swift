//
//  ShareConfigureViewController.swift
//  Clips Share
//
//  Created by William Wu on 1/7/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit

protocol ShareConfigureViewControllerDelegate: class {
    func setTitle(_ title: String?)
}

class ShareConfigureViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleTextField: UITextField!
    weak var delegate: ShareConfigureViewControllerDelegate?
    public var titleToSet: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.titleTextField.text = self.titleToSet
        self.titleTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        delegate?.setTitle(self.titleTextField.text)
    }
    
    // MARK: - Text field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

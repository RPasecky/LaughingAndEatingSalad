//
//  saladView.swift
//  Laughing and Eating Salad
//
//  Created by Ryan Pasecky on 3/15/17.
//  Copyright © 2017 Ryan Pasecky. All rights reserved.
//

import UIKit

class saladView1 : UIView {
    
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "saladView1", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    
}

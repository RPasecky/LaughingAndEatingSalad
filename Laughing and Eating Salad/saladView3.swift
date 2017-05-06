//
//  saladView3.swift
//  Laughing and Eating Salad
//
//  Created by Ryan Pasecky on 3/16/17.
//  Copyright © 2017 Ryan Pasecky. All rights reserved.
//

import UIKit

class saladView3 : UIView {
    
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "saladView3", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    
}

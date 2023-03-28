//
//  HomeCell.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-10-21.
//

import UIKit

class HomeCell: UICollectionViewCell {
    
    //MARK: Properties
    var btnPress: Any?
    
    //MARK: Outlets
    @IBOutlet weak var nameBackground: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var editBtn: UIButton!
    
    //MARK: Actions
    @IBAction func editBtnPressed(_ sender: UIButton) {
        self.btnPress = sender
    }
}

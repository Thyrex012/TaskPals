//
//  ItemViewCell.swift
//  TaskPals
//
//  Created by B Ouk on 10/11/25.
//

import UIKit

class ShopItemCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemEmoji: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }
    
    /**
     The shop item's appearance is setup by this function
     */
    func setupAppearance() {
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
    }
    
}

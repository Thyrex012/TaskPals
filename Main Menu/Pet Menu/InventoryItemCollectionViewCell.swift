//
//  InventoryItemCollectionViewCell.swift
//  TaskPals
//
//  Created by B Ouk on 12/11/25.
//

import UIKit

class InventoryItemCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemEmoji: UILabel!
    @IBOutlet weak var itemQuantity: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    /**
    The inventory's item's appearance is set based off these values
     */
    func setupAppearance() {
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
    }
}

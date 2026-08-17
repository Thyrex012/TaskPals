//
//  ListCollectionViewCell.swift
//  TaskPals
//
//  Created by B Ouk on 6/10/25.
//

import UIKit

//This class was implemented by chatgp
//Used to represent a list collection cell
class ListCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var listTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        listTitleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }
    
    func configure(with list: TaskList, isSelected: Bool) {
        listTitleLabel.text = list.name
        
        if isSelected {
            contentView.backgroundColor = .systemTeal
            layer.borderWidth = 3
            layer.borderColor = UIColor.systemYellow.cgColor
        } else {
            contentView.backgroundColor = .systemBlue
            layer.borderWidth = 0
        }
    }
}

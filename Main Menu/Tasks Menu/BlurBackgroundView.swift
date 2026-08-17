//
//  BlurBackgroundView.swift
//  TaskPals
//
//  Created by B Ouk on 5/11/25.
//

import UIKit

//This whole class was implemented by chatgpt
//This class is used by the History and Tasks vc so that tasks are inside the somewhat
//blurred view
class BlurBackgroundView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBackground()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBackground()
    }
    
    private func setupBackground() {
        // Use a regular UIView instead of UIVisualEffectView
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9) // semi-transparent
        backgroundView.layer.cornerRadius = 12
        backgroundView.clipsToBounds = true
        
        addSubview(backgroundView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}


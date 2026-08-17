//
//  TasksCollectionViewCell.swift
//  TaskPals
//
//  Created by B Ouk on 6/10/25.
//

import UIKit

class TasksCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var taskDescriptionLabel: UILabel!
    @IBOutlet weak var taskDueDateLabel: UILabel!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    var onEditTapped: (() -> Void)?
    var togglingTaskCompletion: (() -> Void)?
    
    override func awakeFromNib() {
         super.awakeFromNib()
         
         // Style (implemented by chatgpt)
         contentView.layer.cornerRadius = 10
         contentView.layer.masksToBounds = true

         layer.shadowColor = UIColor.black.cgColor
         layer.shadowOpacity = 0.1
         layer.shadowOffset = CGSize(width: 0, height: 2)
         layer.shadowRadius = 4
         layer.masksToBounds = false
     }
     
    //This function is used to configure the task based off its expanded state through tapping
    func configure(task: Task, isExpanded: Bool) {
        taskTitleLabel.text = task.title
        taskDescriptionLabel.text = "Description: \(task.details ?? "No details")"
        taskDueDateLabel.text = task.dueDate != nil ? "Due: \(task.dueDate!.formatted(date: .abbreviated, time: .shortened))" : "No due date"
        
        taskDescriptionLabel.isHidden = !isExpanded
        taskDueDateLabel.isHidden = !isExpanded
        editButton.isHidden = !isExpanded
        
        switch task.difficulty {
        case .easy:
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        case .medium:
            contentView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.3)
        case .hard:
            contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        }
    }
    
    //This function will call on togglingTaskCompletion which doesnt have an implementation
    //Which is up to how task and history vc wants to implement it
    @IBAction func toggleCompletionTapped(_ sender: Any) {
        togglingTaskCompletion?()
    }
    
    //This function will call on onEditTapped which doesnt have an implementation
    //Which is up to how task and history vc wants to implement it
    @IBAction func EditButtonTapped(_ sender: Any) {
        onEditTapped?()
    }
}

//
//  TaskDetailsViewController.swift
//  TaskPals
//
//  Created by B Ouk on 16/10/25.
//

import UIKit
import FirebaseFirestore

class TaskDetailsViewController: UIViewController {
    
    var selectedTask: Task!
    var taskCollection: CollectionReference?

    @IBOutlet weak var taskTitleOutlet: UITextField!
    @IBOutlet weak var taskDescriptionOutlet: UITextView!
    @IBOutlet weak var datePickerOutlet: UIDatePicker!
    @IBOutlet weak var taskDifficultyOutlet: UISegmentedControl!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskTitleOutlet.text = selectedTask.title
        taskDescriptionOutlet.text = selectedTask.details
        taskDifficultyOutlet.selectedSegmentIndex = segmentIndex(from: selectedTask.difficulty)
        
        // Set date picker and switch based on existing due date
        if let dueDate = selectedTask.dueDate {
            datePickerOutlet.date = dueDate
            dueDateSwitch.isOn = true
            datePickerOutlet.isHidden = false
        } else {
            datePickerOutlet.date = Date() // fallback default
            dueDateSwitch.isOn = false
            datePickerOutlet.isHidden = true
        }
        
        // Update title background colour
        changeTitleBackgroundColour(taskDifficulty: selectedTask.difficulty)
    }


    //This function will dynamically change the title background colour
    @IBAction func selectedDifficultyChange(_ sender: Any) {
        guard let segment = sender as? UISegmentedControl else { return }
        let difficulty = difficulty(from: segment.selectedSegmentIndex)
        changeTitleBackgroundColour(taskDifficulty: difficulty)
    }
    
    //This function is called when we click on the confirm button which causes the seleted task that we want to edit
    //to have its contents updated on the firestore database
    @IBAction func confirmTaskChange(_ sender: Any) {
        // Update task properties from UI
        selectedTask.title = taskTitleOutlet.text ?? ""
        selectedTask.details = taskDescriptionOutlet.text
        selectedTask.dueDate = dueDateSwitch.isOn ? datePickerOutlet.date : nil
        selectedTask.difficulty = difficulty(from: taskDifficultyOutlet.selectedSegmentIndex)
        
        // Call updateTask in the database
        databaseController?.updateTask(selectedTask, in: taskCollection!) { success in
            DispatchQueue.main.async {
                if success {
                    
                    // Update notification for this task
                    if self.selectedTask.dueDate != nil {
                        NotificationManager.scheduleNotification(for: self.selectedTask)
                    } else {
                        NotificationManager.cancelNotification(for: self.selectedTask)
                    }
                    
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.showAlert(title: "Error", message: "Failed to update task")
                }
            }
        }
    }
    
    //This function is called when we want to delete the selected task from the firestore database
    @IBAction func deleteTask(_ sender: Any) {
        
        let alert = UIAlertController(
            title: "Delete Task",
            message: "This action cannot be undone. Are you sure you want to delete this task?",
            preferredStyle: .alert
        )
        
        //Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        //Confirm action
        let confirmDeleteAction = UIAlertAction(title: "Confirm", style: .destructive, handler: { [self] _ in
            self.databaseController?.deleteTask(selectedTask, in: taskCollection!) { success in
                DispatchQueue.main.async {
                    if success {
                        
                        // Go back to TasksViewController and cancel task notification
                        if self.selectedTask.dueDate != nil {
                            NotificationManager.cancelNotification(for: self.selectedTask)
                        }
                        
                        self.navigationController?.popViewController(animated: true)
                        
                    } else {
                        self.showAlert(title: "Error", message: "failed to delete task")
                    }
                }
            }
        })
        alert.addAction(confirmDeleteAction)
        self.present(alert,animated: true)
        
    }
    
    //This fuction is called whenever we click on the due date switch
    @IBAction func dueDateSwitchChanged(_ sender: UISwitch) {
        datePickerOutlet.isHidden = !sender.isOn
    }
    
    
    //Helper function used to change title background colour based off of task difficulty chosen
    func changeTitleBackgroundColour(taskDifficulty: TaskDifficulty) {
        switch taskDifficulty {
        case .easy:
            taskTitleOutlet.backgroundColor = UIColor.systemGreen
        case .medium:
            taskTitleOutlet.backgroundColor = UIColor.systemOrange
        case .hard:
            taskTitleOutlet.backgroundColor = UIColor.systemRed
        }
    }
    
    //Helper function used to convert the difficulty into an index value for the segment controller
    func segmentIndex(from difficulty: TaskDifficulty) -> Int {
        switch difficulty {
        case .easy: return 0
        case .medium: return 1
        case .hard: return 2
        }
    }
    
    //Helper function used to convert index values to task difficulty
    func difficulty(from index: Int) -> TaskDifficulty {
        switch index {
        case 0: return .easy
        case 1: return .medium
        case 2: return .hard
        default: return .easy
        }
    }
}

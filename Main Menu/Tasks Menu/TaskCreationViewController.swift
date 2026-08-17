//
//  TaskCreationViewController.swift
//  TaskPals
//
//  Created by B Ouk on 8/10/25.
//

import UIKit
import FirebaseFirestore

class TaskCreationViewController: UIViewController {

    @IBOutlet weak var taskTitleOutlet: UITextField!
    @IBOutlet weak var taskDescriptionOutlet: UITextView!
    @IBOutlet weak var datePickerOutlet: UIDatePicker!
    @IBOutlet weak var taskDifficultyOutlet: UISegmentedControl!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    
    var taskCollection: CollectionReference?
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //This fuction is called whenever we click on the due date switch
    @IBAction func showDueDatePicker(_ sender: UISwitch) {
        datePickerOutlet.isHidden = !sender.isOn
    }
    
    //Upon selecting on an option in the difficulty segemented controls we'll then
    //change the title colour based off of it
    @IBAction func selectedDifficultyChange(_ sender: Any) {
        guard let segment = sender as? UISegmentedControl else { return }
        let difficulty = difficulty(from: segment.selectedSegmentIndex)
        changeTitleBackgroundColour(taskDifficulty: difficulty)
    }
    
    /**
     This function is called the moment we click on the confirm button which will create our task with info passed
     from the labels etc...
     */
    @IBAction func confirmCreateTask(_ sender: Any) {
        // Validate title
        guard let title = taskTitleOutlet.text, !title.isEmpty else {
            showAlert(title: "Missing Title", message: "Please enter a title for your task.")
            return
        }
        
        //Based off the selected segment the task difficulty will be set to it
        let difficulty: TaskDifficulty
        switch taskDifficultyOutlet.selectedSegmentIndex {
        case 0: difficulty = .easy
        case 1: difficulty = .medium
        case 2: difficulty = .hard
        default: difficulty = .medium
        }
        
        //New task is created with texts that are inside each of the text fields, along with the due date
        //if the switch is on
        let newTask = Task(
            title: title,
            difficulty: difficulty,
            details: taskDescriptionOutlet.text,
            dueDate: dueDateSwitch.isOn ? datePickerOutlet.date : nil,
            isCompleted: false
        )
        
        databaseController?.addTask(newTask, to: taskCollection!){ success in
            DispatchQueue.main.async {
                if success {
                    //Schedule notifications for the task we made
                    NotificationManager.scheduleNotification(for: newTask)
                    self.navigationController?.popViewController(animated: true)
                }
                else {
                    self.showAlert(title: "Error", message: "Failed to add task")
                }
            }
        }
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

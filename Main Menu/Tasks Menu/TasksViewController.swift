//
//  TasksViewController.swift
//  TaskPals
//
//  Created by B Ouk on 6/10/25.
//

import UIKit
import FirebaseFirestore
import UserNotifications

class TasksViewController: UICollectionViewController, DatabaseListener {

    let GO_TO_TASK_CREATION = "showTaskCreation"
    let GO_TO_TASK_DETAILS = "showTaskDetails"
    
    var taskCollectionRef: CollectionReference?
    var taskListener: ListenerRegistration?
    
    var listenerType = ListenerType.all
    weak var databaseController: FirebaseController?
    var taskListToShow: [TaskList] = []
    var originalTasksOrder: [Task] = []
    var tasksToShow: [Task] = []
    var userDataToShow: User?
    var selectedTaskListIndex: Int? = nil
    var expandedTaskIndexes: Set<Int> = []
    @IBOutlet weak var userCoinsLabel: UILabel!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    var selectedSortOption: SortOption = .default
    
    //MARK: - Databas listeners
    
    //This function is called whenever the use's coins changes from the firestore database so
    //we'll need to reflect the coins change onto our app as well
    func onUserDataChange(change: DatabaseChange, userData: User) {
        userDataToShow = userData
        userCoinsLabel.text = "\(userDataToShow?.totalCoins ?? 0)$"
        collectionView.reloadData()
    }
    
    //This function will call whenever a task list has been created or deleted in firestore database
    //we'll reflect this in  our lists section by setting taskListToShow to the tasklists that was passed from firestore
    func onTaskListChange(change: DatabaseChange, taskLists: [TaskList]) {
        taskListToShow = taskLists
        collectionView.reloadData()
    }
    
    //This function will call whenever a task has been changed in firestore and only tasks that arent completed yet will
    //be shown. The tasks that are passed as param are the latest tasks from firestore so we'll set out variables to it
    func onTaskChange(change: DatabaseChange, tasks: [Task]) {
        
        //Only showing tasks that are not completed
        originalTasksOrder = tasks.filter { !$0.isCompleted }
        tasksToShow = tasks.filter { !$0.isCompleted }
        
        //Apply the task sorting everytime we go to another task list
        applySort(option: selectedSortOption)
    }
    
    func onInventoryChange(change: DatabaseChange, items: [InventoryItem]) {
        //Do nothing
    }
    
    /**
     a snapshot listener is added to the task collection to listen to any changes that occurs within the user's document from firestore
     */
    private func setupTaskListener(for list: TaskList) {
        
        removeTaskListener() // remove existing listener if any
        
        taskListener = taskCollectionRef?.addSnapshotListener { [weak self] snapshot, error in
            guard let snapshot = snapshot else {
                print("Failed to fetch tasks: \(String(describing: error))")
                return
            }
            
            var tasks: [Task] = []
            snapshot.documents.forEach { doc in
                if let task = try? doc.data(as: Task.self) {
                    tasks.append(task)
                }
            }
            self?.onTaskChange(change: .update, tasks: tasks)
        }
    }
    
    /**
     The task listener is removed by calling remove() and setting it to nil
     */
    private func removeTaskListener() {
        taskListener?.remove()
        taskListener = nil
    }
 
    /**
     The database controller is set from the app deligate along with setting how the collection view looks
     we'lll also request permission to show notifiatoins if its the first time the user entered the screen
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let dbController = appDelegate.databaseController {
            databaseController = dbController as? FirebaseController
        }

        // Set custom compositional layout
        collectionView.collectionViewLayout = createLayout()
        
        //Configure the sort menu to show the menu after button press
        configureSortMenu()
        
        //Request for user notification once we enter this screen
        NotificationManager.requestPermissionIfNeeded()
    }
    
    /**
     return 2 as there is a lists and tasks section
     */
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SectionType.allCases.count
    }

    /**
     returns the number of items within that section based off the section type
     */
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return taskListToShow.count + 1 //increment by 1 as we have an additional item which is the "+ New List"
        }
        else {
            return tasksToShow.count
        }
    }

    /**
     Based off the section type the list and task cells will be configured differently by calling on the configureListCell or configureTaskCell
     */
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = SectionType(rawValue: indexPath.section) else { fatalError("Unknown section") }

        switch section {
        case .lists:
            return configureListCell(for: indexPath)
        case .tasks:
            return configureTaskCell(for: indexPath)
        }
    }
    
    //This function was implemeneed by chatgpt
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = SectionType(rawValue: indexPath.section) else { return }
        
        switch section {
        case .lists:
            if indexPath.item == 0 {
                showCreateListAlert()
            } else {
                let oldSelectedTaskListIndex = selectedTaskListIndex
                selectedTaskListIndex = indexPath.item - 1
                let selectedList = taskListToShow[selectedTaskListIndex!]

                // Reload only the old and new selected cells
                var indexPathsToReload: [IndexPath] = [indexPath]
                if let oldIndex = oldSelectedTaskListIndex {
                    indexPathsToReload.append(IndexPath(item: oldIndex + 1, section: SectionType.lists.rawValue))
                }
                collectionView.reloadItems(at: indexPathsToReload)
                
                // Create a new taskRef for this list
                if let uid = databaseController?.currentUser?.uid {
                    taskCollectionRef = databaseController?.database
                        .collection("users")
                        .document(uid)
                        .collection("taskList")
                        .document(selectedList.id!)
                        .collection("task")
                }

                // Set up listener for the new selected list
                setupTaskListener(for: selectedList)
            }
            
        case .tasks:
            // Toggle expansion
            if expandedTaskIndexes.contains(indexPath.item) {
                expandedTaskIndexes.remove(indexPath.item)
            } else {
                expandedTaskIndexes.insert(indexPath.item)
            }
            
            // Reload only the tapped cell for smooth expansion/collapse
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    /**
     This function will setup task and user listeners along with adding the current view controller into the firebase controller's listeners as well
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.setupTaskListListener()
        databaseController?.setupUserListener()
        databaseController?.addListener(listener: self)
    }
    
    /**
     This function will remove the current vc from firebase controller's listener
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    /**
     This function is used to configure the sorting button to show the menu which will contains the default order, and due date. Upon clicking on
     one of them the applySort function will be called to sort the task accordingly based off the SortOption type
     */
    func configureSortMenu() {
        let defaultAction = UIAction(title: "Default Order", image: UIImage(systemName: "list.bullet")) { _ in
            self.applySort(option: .default)
        }

        let dueDateAction = UIAction(title: "Due Date", image: UIImage(systemName: "calendar")) { _ in
            self.applySort(option: .dueDate)
        }

        let menu = UIMenu(title: "Sort Tasks", children: [defaultAction, dueDateAction])
        
        sortButton.menu = menu
    }
    
    // MARK: - Cell Creation Helpers

    /**
     Used to configure how the liset cell will look in the app
     Implemented by chatgpt
     */
    private func configureListCell(for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as! ListCollectionViewCell
        
        if indexPath.item == 0 {
            // "Create List +" cell
            cell.listTitleLabel.text = "+ New List"
            cell.contentView.backgroundColor = .systemGreen
            cell.layer.borderWidth = 0
        } else {
            let list = taskListToShow[indexPath.item - 1]
            let isSelected = selectedTaskListIndex == indexPath.item - 1
            cell.configure(with: list, isSelected: isSelected)
        }
        
        return cell
    }

    /**
     Used to configure how task cells will show up in the vc
     Implemented by chatgpt
     */
    private func configureTaskCell(for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TaskCell", for: indexPath) as! TasksCollectionViewCell
        let task = tasksToShow[indexPath.item]
        let isExpanded = expandedTaskIndexes.contains(indexPath.item)
        
        // Configure the cell's content
        cell.configure(task: task, isExpanded: isExpanded)
        
        // Edit button closure
        cell.onEditTapped = { [weak self] in
            guard let self = self else { return }
            self.performSegue(withIdentifier: self.GO_TO_TASK_DETAILS, sender: task)
        }
        
        // Complete button closure
        cell.togglingTaskCompletion = { [weak self] in
            self?.markTaskCompleted(at: indexPath)
        }
        
        return cell
    }
    
    /**
     As we mark the task as completed the function's update task is called to update the task within the databse and we'll also need to update the user's
     coins as well as it'll be deducted from the user due to their incomplete nature
     */
    private func markTaskCompleted(at indexPath: IndexPath) {
        var task = tasksToShow[indexPath.item]
        userDataToShow?.totalCoins! += task.coinsEarned
        
        task.isCompleted = true
        
        // Cancel notification if task had a due date
        if task.dueDate != nil {
            NotificationManager.cancelNotification(for: task)
        }
        
        databaseController?.updateTask(task, in: taskCollectionRef!) { success in
            DispatchQueue.main.async {
                if success {
                    // Remove task from view if filtering out completed tasks
                    print("task completed and notifcation removed")
                } else {
                    print("Failed to mark task complete")
                }
            }
        }
        
        databaseController?.updateUser(userDataToShow!) { success in
            if success {
                print("coins has been added to user balance")
            } else {
                print("Failed to update user coins")
            }
        }
    }

    /**
     As we're going to the task details screen we'll instanstiated
     selectedTask: task we want to see the details of
     databaseController: the firebase controller from app delegate
     taskCollection: the user's task collection reference
     
     As we're going to the task creation screen we'll instantiate
     taskCollection: the user's task collection reference
     databaseController: the firebase controller from app delegate
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == GO_TO_TASK_CREATION {
            let destination = segue.destination as! TaskCreationViewController
            destination.taskCollection = taskCollectionRef
            destination.databaseController = databaseController
        }
        else if segue.identifier == GO_TO_TASK_DETAILS {
            let destination = segue.destination as! TaskDetailsViewController
            if let task = sender as? Task {
                destination.selectedTask = task
                destination.databaseController = databaseController
                destination.taskCollection = taskCollectionRef
            }
        }
    }
    
    /**
     used to show an alert when we want to create a task list
     This function was implemenetd by chatgpt
     */
    func showCreateListAlert() {
        let alert = UIAlertController(
            title: "New List",
            message: "Enter a name for your list",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Enter a name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else {
                // If name is empty, show a warning alert
                let emptyNameAlert = UIAlertController(
                    title: "Name cannot be empty",
                    message: "Please enter a name for your list.",
                    preferredStyle: .alert
                )
                emptyNameAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(emptyNameAlert, animated: true)
                return
            }
            
            // Create a new TaskList
            let newList = TaskList(name: name)
            
            // Add it to Firestore
            self.databaseController?.addTaskList(newList) { success in
                if success {
                    print("List '\(name)' added to Firestore")
                } else {
                    print("Failed to add list to Firestore")
                }
            }
        }))
        
        present(alert, animated: true)
    }
}

extension TasksViewController {
    
    /**
     Based off the sorting option say the due date then we'll need to sort the tasksToShow accordingly by extracting each
     task's dueDate and if it doesnt exist will perform our sort accordingly as well
     
     this function was implemented by chatgpt
     */
    func applySort(option: SortOption) {
        selectedSortOption = option
        switch selectedSortOption {
        case .default:
            tasksToShow = originalTasksOrder
        case .dueDate:
            tasksToShow.sort { t1, t2 in
                switch (t1.dueDate, t2.dueDate) {
                case let (d1?, d2?): return d1 < d2        // both have due dates
                case (nil, _?): return false               // t1 has no due date → after t2
                case (_?, nil): return true                // t2 has no due date → after t1
                case (nil, nil): return false              // both nil → keep original order
                }
            }
        }
        // Reload the collection view after sorting
        collectionView.reloadSections(IndexSet(integer: SectionType.tasks.rawValue))
    }
    
    /**
     Create layout provides the layout for both the lists and tasks section which dictates how it'll be able to be scrolled horizontally or verticlaly along with how
     the items are populated as well
     
     implementd by chatgpt
     */
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let sectionType = SectionType(rawValue: sectionIndex) else {
                fatalError("Unknown section")
            }

            switch sectionType {
            case .lists:
                // MARK: Lists Section (horizontal scroll)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(100),
                    heightDimension: .fractionalHeight(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: .fixed(8),
                    top: .fixed(8),
                    trailing: .fixed(8),
                    bottom: .fixed(8)
                )

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(140),
                    heightDimension: .absolute(80)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.interItemSpacing = .fixed(10)

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 20, trailing: 10)
                return section

            case .tasks:
                // MARK: Tasks Section (vertical scroll with blur background)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(60)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(60)
                )
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 5
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

                // Only add blur background if there are tasks
                if self.tasksToShow.count > 0 {
                    section.decorationItems = [
                        NSCollectionLayoutDecorationItem.background(elementKind: "blur-background")
                    ]
                }

                return section
            }
        }

        // Register the blur decoration view
        layout.register(BlurBackgroundView.self, forDecorationViewOfKind: "blur-background")
        return layout
    }
}


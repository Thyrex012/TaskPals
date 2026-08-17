//
//  ShopViewController.swift
//  TaskPals
//
//  Created by B Ouk on 10/11/25.
//

import UIKit
import FirebaseAuth

private let reuseIdentifier = "ItemViewCell"
class ShopViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DatabaseListener {
    
    var listenerType = ListenerType.all
    var allItems: [InventoryItem] = []
    var displayedItems: [InventoryItem] = []
    var inventoryItems: [InventoryItem] = []
    var userDataToShow: User?
    weak var databaseController: FirebaseController?
    var nextRefreshDate: Date?
    var rotationTimer: Timer?
    var refreshCost = 0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var shopRefreshLabel: UILabel!
    @IBOutlet weak var userCoinsLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    
    //MARK: - Database listener functions
    
    func onTaskListChange(change: DatabaseChange, taskLists: [TaskList]) {
        //Do nothing
    }
    
    func onTaskChange(change: DatabaseChange, tasks: [Task]) {
        //Do nothing
    }
    
    func onUserDataChange(change: DatabaseChange, userData: User) {
        userDataToShow = userData
        userCoinsLabel.text = "\(userDataToShow?.totalCoins ?? 0)$"
    }
    
    func onInventoryChange(change: DatabaseChange, items: [InventoryItem]) {
        inventoryItems = items
    }
    
    //MARK: - View Controller functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let dbController = appDelegate.databaseController {
            databaseController = dbController as? FirebaseController
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        loadInventoryItems()
        loadUserRefreshDate()
        loadRefreshCost()
        setupHourlyRotation()
        startCountdownTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.setupUserListener()
        databaseController?.setupInventoryListener()
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    //MARK: - Helper functions to rotate items in the shop and also set the timers
    
    /**
     Loads the inventory items for viewing by rotating it first
     */
    func loadInventoryItems() {
        
        //this has been implemented by chatgpt
        allItems = [
            // Foods
            InventoryItem(id: "food_chicken_kibble", name: "Chicken Kibble", category: .food, price: 200, emoji: "🍗", quantity: 0),
            InventoryItem(id: "food_beef_meal", name: "Beef Meal", category: .food, price: 220, emoji: "🥩", quantity: 0),
            InventoryItem(id: "food_fish_treat", name: "Fish Treat", category: .food, price: 180, emoji: "🐟", quantity: 0),
            InventoryItem(id: "food_veggie_mix", name: "Veggie Mix", category: .food, price: 150, emoji: "🥕", quantity: 0),
            
            // Toys
            InventoryItem(id: "toy_rubber_ball", name: "Rubber Ball", category: .toys, price: 100, emoji: "🎾", quantity: 0),
            InventoryItem(id: "toy_chew_rope", name: "Chew Rope", category: .toys, price: 120, emoji: "🪢", quantity: 0),
            InventoryItem(id: "toy_squeaky_dog", name: "Squeaky Dog", category: .toys, price: 150, emoji: "🦴", quantity: 0),
            InventoryItem(id: "toy_cat_wand", name: "Cat Wand", category: .toys, price: 130, emoji: "🪄", quantity: 0),
            
            // Hygiene
            InventoryItem(id: "hygiene_pet_shampoo", name: "Pet Shampoo", category: .hygiene, price: 180, emoji: "🧴", quantity: 0),
            InventoryItem(id: "hygiene_pet_conditioner", name: "Pet Conditioner", category: .hygiene, price: 200, emoji: "🫧", quantity: 0),
            InventoryItem(id: "hygiene_pet_toothpaste", name: "Pet Toothpaste", category: .hygiene, price: 150, emoji: "🪥", quantity: 0),
            InventoryItem(id: "hygiene_pet_brush", name: "Pet Brush", category: .hygiene, price: 170, emoji: "🧹", quantity: 0)
        ]
        
        rotateItems()
    }
    
    /**
     all the items are shuffled and displayed items will only display the first 6 items in the shuffled array
     */
    func rotateItems(){
        let shuffledItems = allItems.shuffled()
        displayedItems.removeAll()
        for i in 0...5 {
            displayedItems.append(shuffledItems[i])
        }
        collectionView.reloadData()
    }
    
    //This function was implemented by chatgpt
    //Used to rotate items every hour even if we were to close the app
    func setupHourlyRotation() {
        // check if we have a saved next refresh time
        if let nextRefresh = nextRefreshDate, nextRefresh > Date() {
            let interval = nextRefresh.timeIntervalSinceNow
            rotationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                self.rotateItems()
                self.saveNextRefreshDate() // reset for the next hour
                self.setupHourlyRotation()
            }
        } else {
            rotateItems()
            saveNextRefreshDate()
            rotationTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
                self.rotateItems()
                self.saveNextRefreshDate()
            }
        }
    }
    
    /**
     Helper function used to save the next time we'll need to refresh the items in the shop based off of the user using the uid
     */
    func saveNextRefreshDate() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let nextDate = Date().addingTimeInterval(3600)
        nextRefreshDate = nextDate
        UserDefaults.standard.set(nextDate, forKey: "shop_nextRefreshDate_\(uid)")
    }

    /**
     Helper function where next refresh date is loaded up from the UserDefauls that is tied to a user
     */
    func loadUserRefreshDate() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let savedDate = UserDefaults.standard.object(forKey: "shop_nextRefreshDate_\(uid)") as? Date {
            nextRefreshDate = savedDate
        }
    }
    
    /**
     Helper function used to save the refresh cost as the user keeps on clicking it more and more without letting it refresh and reset
     This value is saved inside the UserDefaults that is tied based off of uid
     */
    func saveRefreshCost() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        UserDefaults.standard.set(refreshCost, forKey: "shop_refreshCost_\(uid)")
    }

    /**
     Helper funciton used to load the refresh cost from UserDefaults
     */
    func loadRefreshCost() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let savedCost = UserDefaults.standard.object(forKey: "shop_refreshCost_\(uid)") as? Int {
            refreshCost = savedCost
        } else {
            refreshCost = 500 // default starting cost
        }

        refreshButton.setTitle(refreshCost == 0 ? "free" : "\(refreshCost)", for: .normal)
    }

    /**
     Sets a countdown timer that will call on updateCountDownLabel to change the label every second
     */
    func startCountdownTimer() {
          rotationTimer?.invalidate()
          rotationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
              self.updateCountdownLabel()
          }
      }
    
    /**
     used to update the countdown label
     implementd by chatgpt
     */
    func updateCountdownLabel() {
        guard let nextRefreshDate = nextRefreshDate else {
            shopRefreshLabel.text = "⏳ Loading..."
            return
        }

        let now = Date()
        if now >= nextRefreshDate {
            shopRefreshLabel.text = "Refreshing..."
            rotateItems()
            saveNextRefreshDate()
            updateCountdownLabel()
            refreshButton.setTitle("free", for: .normal)
            return
        }

        let remaining = Int(nextRefreshDate.timeIntervalSince(now))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        shopRefreshLabel.text = String(format: "⏳ Next refresh in %02d:%02d:%02d", hours, minutes, seconds)
    }

    /**
     This funciton is called when we click on the refresh cooldown button which will perform different actions depending on the amount of coints we have and if
     refreshCost is free which means it'll be our first shop refresh
     **/
    @IBAction func refreshingItemCooldown(_ sender: Any) {
        
        guard let user = userDataToShow else { return }

         if refreshCost == 0 {
             rotateItems()
             saveNextRefreshDate()
             startCountdownTimer()
             refreshCost += 500
             refreshButton.setTitle("\(refreshCost)", for: .normal)
             return
         }
         else if refreshCost < user.totalCoins! {
             user.totalCoins! -= refreshCost
             
             databaseController?.updateUser(user) { success in
                 if success {
                     print("Coins have been deducted from user")
                 } else {
                     print("Failed to update user coins")
                 }
             }
             rotateItems()
             saveNextRefreshDate()
             startCountdownTimer()
             refreshCost += 500
             saveRefreshCost()
             refreshButton.setTitle("\(refreshCost)", for: .normal)
             
         } else {
             showAlert(title: "Not enough coins", message: "you dont have enough coins")
         }
     }
    
    //MARK: - Collection View functions
    
    /**
     returns the amount of items that are displayed
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedItems.count
    }
    
    /**
     Set each of the item's emoji, name and their price
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemViewCell", for: indexPath) as! ShopItemCollectionViewCell
        let item = displayedItems[indexPath.row]
        cell.itemEmoji.text = item.emoji
        cell.itemName.text = item.name
        cell.itemPrice.text = "💰\(item.price)"
        return cell
    }
    
    /**
     Upon selecting on an item an alert will appear asking if we're sure we want to buy this item with said cost
     After we clicked confirm we'll reduce our coins and the item's quantity will also increase. These are then updated to firestore database
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = userDataToShow else { return }
        
        let selectedItem = displayedItems[indexPath.row]
        
        // Find the actual inventory item by ID
        guard let inventoryIndex = inventoryItems.firstIndex(where: { $0.id == selectedItem.id }) else {
            print("Item not found in inventoryItems")
            return
        }
        
        let alert = UIAlertController(
            title: "Buy \(selectedItem.name)?",
            message: "Price: 💰\(selectedItem.price)\nYou have: 💰\(user.totalCoins ?? 0)",
            preferredStyle: .alert
        )
        
        // Confirm action
        let buyAction = UIAlertAction(title: "Buy", style: .default) { _ in
            if let userCoins = user.totalCoins, userCoins >= selectedItem.price {
                // Deduct coins
                user.totalCoins! -= selectedItem.price
                
                // Update user in database
                self.databaseController?.updateUser(user) { success in
                    if success {
                        print("Coins deducted successfully")
                    } else {
                        print("Failed to update user coins")
                    }
                }
                
                // Update the actual inventory item
                var updatedItem = self.inventoryItems[inventoryIndex]
                updatedItem.quantity += 1
                self.inventoryItems[inventoryIndex] = updatedItem // update local array
                
                self.databaseController?.updateInventoryItem(updatedItem) { success in
                    if success {
                        print("Item quantity updated successfully")
                        // Reload only the selected item cell
                        self.collectionView.reloadItems(at: [indexPath])
                    } else {
                        print("Failed to update item quantity")
                    }
                }
            } else {
                self.showAlert(title: "Not enough coins", message: "You don't have enough coins to buy this item.")
            }
        }
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(buyAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

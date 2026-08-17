//
//  PetViewController.swift
//  TaskPals
//
//  Created by B Ouk on 12/11/25.
//

import UIKit
import FirebaseAuth

private let reuseIdentifier = "ItemViewCell"
class PetViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DatabaseListener {
    
    var listenerType = ListenerType.all
    var userDataToShow: User?
    var inventoryItems: [InventoryItem] = []
    var filteredItems: [InventoryItem] = [] // Will show only food/toys/hygiene
    var databaseController: FirebaseController?
    var currentFilter: Category? = nil
    var nextDropTimer: Timer?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var happinessProgressBar: UIProgressView!
    @IBOutlet weak var animalImage: UIImageView!
    @IBOutlet weak var petHappinessLabel: UILabel!
    @IBOutlet weak var nextHappinessDropLabel: UILabel!
    
    // MARK: - database listener
    
    /**
     everytime the user's pet is changed this function will get called to set the userDataToShow to the latest
     userData so that anything that relies on this can change accordingly as well
     */
    func onUserDataChange(change: DatabaseChange, userData: User) {
        
        userDataToShow = userData
    
        if userData.pet == nil {
            showPetSelectionAlert()
        } else {
            updatePetImage()
            updateHappinessUI()
        }
    }
    
    func onTaskListChange(change: DatabaseChange, taskLists: [TaskList]) {
        //Do nothing
    }
    
    func onTaskChange(change: DatabaseChange, tasks: [Task]) {
        //Do nothing
    }
    
    /**
     Any changes to the user's inventory will cause the function to be called so that inventoryItems will be set to the latest
     list of items that are obtained from firestore
     */
    func onInventoryChange(change: DatabaseChange, items: [InventoryItem]) {
        inventoryItems = items
        collectionView.reloadData()
    }
    
    //MARK: - Time releated functions to track the time for the pet's happiness drop
    
    /**
     Helper function used to get convert the second's remaining passed in from param into minutes and seconds so that
     we can then have it displayed to the usere via the label
     */
    func updateNextDropLabel(secondsRemaining: TimeInterval) {
        let minutes = Int(secondsRemaining) / 60
        let seconds = Int(secondsRemaining) % 60
        DispatchQueue.main.async {
            self.nextHappinessDropLabel.text = String(format: "Next happiness drop in %02d:%02d", minutes, seconds)
        }
    }
    
    /**
     The last happiness date is loaded from the UserDefaults object and is then returned
     */
    func loadLastHappinessUpdate() -> Date {
        let defaults = UserDefaults.standard
        guard let uid = Auth.auth().currentUser?.uid else { return Date() }
        if let savedDate = defaults.object(forKey: "pet_lastHappinessUpdate_\(uid)") as? Date {
            return savedDate
        }
        return Date() // default to now if never saved
    }

    /**
     The last happiness update is saved into the UserDefaults for data persistence
     */
    func saveLastHappinessUpdate(_ date: Date) {
        let defaults = UserDefaults.standard
        guard let uid = Auth.auth().currentUser?.uid else { return }
        defaults.set(date, forKey: "pet_lastHappinessUpdate_\(uid)")
    }
    
    /**
     This function will start the cooldown timer to reduce the pet's happiness which will occur every 30 minutes
     the happiness drop label will be updated every second
     */
    func startCooldownTimer() {
        nextDropTimer?.invalidate()
        
        let interval: TimeInterval = 1800 // 30 minutes
        
        nextDropTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let pet = self.userDataToShow?.pet else { return }
            
            let lastUpdate = self.loadLastHappinessUpdate()
            let now = Date()
            let elapsedIntervals = Int(now.timeIntervalSince(lastUpdate) / interval)
            
            //If multiple 30 minutes have been going on in the real world we'll reduce our pet's
            //happiness based off that interval and removePet() and updatePet() will be called depending on
            //wether the happiness is 0
            if elapsedIntervals > 0 {
                // Reduce happiness for all missed intervals
                pet.happiness -= (elapsedIntervals * 5)
                self.saveLastHappinessUpdate(lastUpdate.addingTimeInterval(TimeInterval(elapsedIntervals) * interval))
                
                if pet.happiness <= 0 {
                    self.databaseController?.removePet { success in
                        if success {
                            // Stop the timer when pet is removed
                            self.nextDropTimer?.invalidate()
                            self.nextDropTimer = nil
                        }
                    }
                    timer.invalidate()
                    return
                } else {
                    self.databaseController?.updatePet(pet: pet) { success in
                        if success {
                            print("Pet's happiness updated: \(pet.happiness)")
                        }
                    }
                }
            }
            
            // Update countdown label
            let nextDrop = self.loadLastHappinessUpdate().addingTimeInterval(interval)
            let secondsRemaining = max(0, nextDrop.timeIntervalSinceNow)
            self.updateNextDropLabel(secondsRemaining: secondsRemaining)
        }
        
        nextDropTimer?.fire()
    }
    
    //MARK: - Pet Selection and its helper
    
    /**
     Determiens if its the first time the user is in the pet vc, if so no UserDefault is created which will then cause us to mark it as false
     and also return true. This can be used later on in our pet selsection screen as if its not the user's first time and they encounter the
     pet selection screen again then that means that their pet must have left them.
     */
    func isFirstTimeUser(userId: String) -> Bool {
        let defaults = UserDefaults.standard
        let key = "isFirstTimeUser_\(userId)"
        
        if defaults.object(forKey: key) == nil {
            // First time for this user
            defaults.set(false, forKey: key) // mark as no longer first-time
            return true
        }
        
        return false
    }
    
    /**
     Show an alert to the user and its contents is dependent on wether its the user's first time, this allows the user to create their pet
     and we'll set the UserDefaults to true as well
     */
    func showPetSelectionAlert() {
        guard let userId = userDataToShow?.id else { return }
        let message: String
        let firstTime = isFirstTimeUser(userId: userId)
        
        if firstTime {
            message = "Select a pet to start."
        } else {
            message = "You didn't take care of your pet, please be a better owner next time. Select a new pet to start again."
        }
        
        let alert = UIAlertController(title: "Choose your pet", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dog 🐶", style: .default, handler: { _ in
            self.databaseController?.createPet(of: .dog)
            UserDefaults.standard.set(true, forKey: "isFirstTimeUser_\(userId)")
        }))
        alert.addAction(UIAlertAction(title: "Cat 🐱", style: .default, handler: { _ in
            self.databaseController?.createPet(of: .cat)
            UserDefaults.standard.set(true, forKey: "isFirstTimeUser_\(userId)")
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    /**
     Update the pet's image based on the type of pet the user has
     */
    func updatePetImage() {
        if let pet = userDataToShow?.pet {
            switch pet.type {
            case .cat:
                animalImage.image = UIImage(named: "cat")
            case .dog:
                animalImage.image = UIImage(named: "dog")
            }
        }
    }
    
    /**
     Updates the happiness progress bar and it's colour based off the pet's happiness levels
     */
    func updateHappinessUI() {
        guard let pet = userDataToShow?.pet else { return }
        // Update progress bar
        let progress = Float(pet.happiness) / 100.0
        happinessProgressBar.setProgress(progress, animated: true)
        
        // Change color based on happiness
        switch pet.happiness {
        case 70...100:
            happinessProgressBar.progressTintColor = .systemGreen
        case 40..<70:
            happinessProgressBar.progressTintColor = .systemYellow
        default:
            happinessProgressBar.progressTintColor = .systemRed
        }
        
        // Update label
        petHappinessLabel.text = "\(pet.happiness)/100"
    }
    
    //MARK: - ViewController functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let dbController = appDelegate.databaseController {
            databaseController = dbController as? FirebaseController
        }
        
        // Setup collection view
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Make the progress bar taller (implemented by chatgpt)
        happinessProgressBar.transform = CGAffineTransform(scaleX: 1, y: 3) // 3x taller
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.setupUserListener()
        databaseController?.setupInventoryListener()
        databaseController?.addListener(listener: self)
        
        startCooldownTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        filteredItems.removeAll()
        databaseController?.removeListener(listener: self)
        
        nextDropTimer?.invalidate()
    }
    
    // MARK: Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! InventoryItemCollectionViewCell
        
        let item = filteredItems[indexPath.row]
        cell.itemName.text = item.name
        cell.itemEmoji.text = item.emoji
        cell.itemQuantity.text = "amt: \(item.quantity)"
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let pet = userDataToShow?.pet else { return }
        let selectedItem = filteredItems[indexPath.row]
        
        if selectedItem.quantity <= 0 {
            showAlert(title: "No more items", message: "You don't have any \(selectedItem.name) left.")
            return
        }

        // effects by category
        switch selectedItem.category {
        case .food:
            pet.happiness = min(pet.happiness + 10, 100)
        case .toys:
            pet.happiness = min(pet.happiness + 5, 100)
        case .hygiene:
            pet.happiness = min(pet.happiness + 7, 100)
        }

        // Update the pet in database
        databaseController?.updatePet(pet: pet) { success in
            if success {
                print("Pet updated after using \(selectedItem.name)")
            }
        }
        
        // Save current time as last happiness update
        let now = Date()
        saveLastHappinessUpdate(now)
        print("the pet's happiness was last updated on \(now)")

        //This section was implemented by chatgpt
        if let index = inventoryItems.firstIndex(where: { $0.id == selectedItem.id }) {
            inventoryItems[index].quantity -= 1
            databaseController?.updateInventoryItem(inventoryItems[index]) { success in
                if success {
                    print("\(selectedItem.name) quantity decreased")
                    self.applyCurrentFilter(self.inventoryItems[index].category) // refresh UI
                }
            }
        }

        // Update the UI
        updateHappinessUI()
    }
    
    //MARK: - Filter function to show selective items based on what button was pressed
    
    /**
     This  helper function will apply the filter to show selective items based off the category that was passed in
     */
    func applyCurrentFilter(_ categoryChose: Category) {
        filteredItems = inventoryItems.filter { $0.category == categoryChose }
        collectionView.reloadData()
    }
    
    @IBAction func foodButtonPressed(_ sender: Any) {
        currentFilter = .food
        applyCurrentFilter(currentFilter.unsafelyUnwrapped)
    }
    
    @IBAction func toyButtonPressed(_ sender: Any) {
        currentFilter = .toys
        applyCurrentFilter(currentFilter.unsafelyUnwrapped)
    }
    
    @IBAction func hygieneButtonPressed(_ sender: Any) {
        currentFilter = .hygiene
        applyCurrentFilter(currentFilter.unsafelyUnwrapped)
    }
    
    // MARK: - API Fetch Function and button (Updated)
    
    @IBAction func FactsButtonPressed(_ sender: Any) {
        fetchPetFact()
    }
    
    /**
    It performs a fetch request to Animals API and will return a random fact based off the pet we own
     
    */
    func fetchPetFact() {
        guard let pet = userDataToShow?.pet else {
            showAlert(title: "Error", message: "No pet selected.")
            return
        }

        let petSpecies: String
        let apiURL: String
        
        switch pet.type {
        case .dog:
                petSpecies = "Dog"
                // Corrected Example URL (MUST be replaced with your actual API endpoint)
                apiURL = "https://api.api-ninjas.com/v1/animals?name=dog"
            case .cat:
                petSpecies = "Cat"
                // Corrected Example URL
                apiURL = "https://api.api-ninjas.com/v1/animals?name=cat"
            }

        guard let url = URL(string: apiURL) else {
            print("Error: Invalid URL for \(petSpecies) facts.")
            return
        }

        var request = URLRequest(url: url)
        // ANIMALS API KEY - stored an animal's api key locally with an xconfig file. This feature of fetching random pet facts cant be accessed for the time being for security reasons.
         request.setValue("ANIMAL_API_KEY", forHTTPHeaderField: "X-Api-Key")
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showAlert(title: "Network Error", message: "Could not connect to the API.")
                }
                return
            }

            guard let data = data else {
                print("Error: No data received.")
                return
            }

            // --- Start Decoding ---
            do {
                // 1. Attempt to decode the SUCCESS case: an array of Animal objects
                let animals = try JSONDecoder().decode([Animal].self, from: data)
                
                // Filter: Ensure we only pick a breed that is a "Cat" or "Dog" type (if the API is mixed)
                let relevantBreeds = animals.filter { $0.characteristics.group?.contains(petSpecies) == true || $0.name.contains(petSpecies) }
                
                guard let randomBreed = relevantBreeds.randomElement() else {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "\(petSpecies) Fact", message: "No specific fact found for a \(petSpecies) at this time.")
                    }
                    return
                }
                
                // Prioritize slogan, then temperament, then diet as the 'fact'
                let factText = randomBreed.characteristics.slogan ?? randomBreed.characteristics.temperament ?? "The diet is \(randomBreed.characteristics.diet ?? "unknown")."
                
                DispatchQueue.main.async {
                    self?.showAlert(title: "Fact: \(randomBreed.name) 💡", message: factText)
                }

            } catch {
                // 2. If decoding [Animal] failed, try to decode an API Error Response
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
                   let message = apiError.error ?? apiError.message {
                    
                    DispatchQueue.main.async {
                        self?.showAlert(title: "API Error Response", message: message)
                    }
                    
                } else {
                    // 3. If everything failed, it's a structural or corrupted data error
                    print("Final Decoding Error: \(error)")
                    DispatchQueue.main.async {
                        // This is the message the user is currently seeing:
                        self?.showAlert(title: "Data Error", message: "Could not understand the fact data.")
                    }
                }
            }
        }.resume()
    }
}

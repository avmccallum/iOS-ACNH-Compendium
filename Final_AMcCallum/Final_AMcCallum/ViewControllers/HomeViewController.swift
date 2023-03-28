//
//  HomeViewController.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-10-21.
//

import UIKit
import CoreData

class HomeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    //MARK: Outlets
    @IBOutlet weak var deleteBtn: UIBarButtonItem!
    
    
    //MARK: Actions
    @IBAction func addBtnPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add List", message: "Enter a name for the list:", preferredStyle: .alert)
        alertController.addTextField()
        
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            _ in
            
            //access the textfield in the alert
            let textField = alertController.textFields![0]
            //get the text from the field
            guard let text = textField.text else { return }
            //create the list
            let newList = List(context: self.coreDataStack.managedContext)
            newList.name = text
            newList.id = UUID()
            //save changes and refresh collection view
            self.coreDataStack.saveContext()
            self.fetchLists()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: false)
    }
    
    @IBAction func deleteBtnPressed(_ sender: UIBarButtonItem) {
        guard let listToDelete = self.dataSource.itemIdentifier(for: self.currentIndex) else { return }
        let alertController = UIAlertController(title: "Delete List", message: "Are you sure you want to delete \"\(listToDelete.name)\"?", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {
            _ in
            //delete the list, save, reload data
            self.coreDataStack.managedContext.delete(listToDelete)
            self.coreDataStack.saveContext()
            self.fetchLists()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: false)
    }
    
    //MARK: Properties
    let defaults = UserDefaults.standard
    var currentIndex: IndexPath = [0,0]
    //properties for cell spacing & size
    let itemsPerRow: CGFloat = 1
    let itemSpacing: CGFloat = 40
    let contentSpacing: CGFloat = 20
    //data properties
    var coreDataStack: CoreDataStack!
    lazy var villagers = [VillagerModel]()
    var lists = [List]()
    //datasource
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, List>(collectionView: collectionView) {
        collectionView, indexPath, list in
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeCell", for: indexPath) as! HomeCell
        
        //add list name to label
        cell.nameLabel.text = list.name
        //round corners on name label
        cell.nameBackground.layer.cornerRadius = 20
        
        //depending on the index of the item, change the background image
        let index = indexPath.row % 3
        switch index {
        case 1:
            cell.backgroundImage.image = UIImage(named: "day")
        case 2:
            cell.backgroundImage.image = UIImage(named: "night")
        default:
            cell.backgroundImage.image = UIImage(named: "beach")
        }
        
        if list.name == "All Villagers" {
            //hide edit btn
            cell.editBtn.isHidden = true
        } else {
            //show edit btn
            cell.editBtn.isHidden = false
            //add button action to edit button on cell
            cell.editBtn.addTarget(self, action: #selector(self.editList), for: .touchUpInside)
        }
        cell.backgroundImage.layer.cornerRadius = 30
        
        return cell
    }
    
    //MARK: View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        //hide the delete button on initial load
        self.deleteBtn.isEnabled = false
        self.deleteBtn.tintColor = UIColor.clear
        
        //if the app has not been run before, create the initial list
        if defaults.bool(forKey: "hasBeenLaunched") == false {
            let newList = List(context: coreDataStack.managedContext)
            newList.name = "All Villagers"
            newList.id = UUID()
            //save new list created
            self.coreDataStack.saveContext()
            //get all the villagers for the new list
            downloadVillagers(for: newList)
        }
        //update to note the app has been run and retrieve all the lists
        defaults.set(true, forKey: "hasBeenLaunched")
        fetchLists()
    }
    
    //MARK: createSnapshot
    func createSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, List>()
        snapshot.appendSections([.main])
        snapshot.appendItems(lists, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    //MARK: fetchLists
    //retrieves all the lists from CoreData
    func fetchLists() {
        let fetchRequest: NSFetchRequest<List> = List.fetchRequest()
        do {
            //try to get the lists from core data and create snapshot
            lists = try coreDataStack.managedContext.fetch(fetchRequest)
            createSnapshot()
        } catch {
            print("ERROR fetching lists: \(error)")
        }
    }
    
    //MARK: downloadVillagers
    //retrieves villager data from the API in JSON format
    func downloadVillagers(for list: List) {
        //if the url is valid
        if let url = URL(string: "https://api.nookipedia.com/villagers?nhdetails=true&game=nh") {
            //create the url request to add required api key
            var request = URLRequest(url: url)
            request.addValue("1aa13d13-125c-4eb1-884d-d315dc280ca0", forHTTPHeaderField: "X-API-KEY")
            request.addValue("1.0.0", forHTTPHeaderField: "Accept-Version")
            let villagerTask = URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                if let error = error {
                    print("ERROR: \(error.localizedDescription)")
                } else {
                    do {
                        guard let data = data else {
                            return
                        }

                        let jsonDecoder = JSONDecoder()
                        let retrievedResults = try jsonDecoder.decode([VillagerModel].self, from: data)
                        let villagerResults = retrievedResults
                        
                        DispatchQueue.main.async {
                            self.villagers = villagerResults
                            //for each villager in the results array
                            for villager in self.villagers {
                                //format a new Villager object
                                let newVillager = self.formatVillager(for: villager)
                                //add to the list
                                list.addToVillagers(newVillager)
                                //save
                                self.coreDataStack.saveContext()
                            }
                        }
                    } catch let error {
                        print(error)
                        print("ERROR: \(error.localizedDescription)")
                    }
                }
            }
            villagerTask.resume()
        }
    }
    
    //MARK: editList
    //presents an alert controller to allow a user to edit a list name
    @objc func editList(_ sender: AnyObject) {
        //get the position of the button pressed
        let buttonPosition: CGPoint = sender.convert(CGPoint.zero, to: self.collectionView)
        //get the index path at that position
        let indexPath = self.collectionView.indexPathForItem(at: buttonPosition)

        if let index = indexPath {
            //get the list at the index
            guard let listToEdit = self.dataSource.itemIdentifier(for: index) else { return }
            
            let alertController = UIAlertController(title: "Change List Name", message: "Enter a name for the list:", preferredStyle: .alert)
            alertController.addTextField()
            //set textfield text to current list name
            alertController.textFields![0].text = listToEdit.name
            
            let saveAction = UIAlertAction(title: "Save", style: .default) {
                _ in
                //access the textfield in the alert
                let textField = alertController.textFields![0]
                //get the text from the field
                guard let text = textField.text else { return }
                listToEdit.name = text
                //save changes
                self.coreDataStack.saveContext()
                //refresh collectionview
                self.collectionView.reloadData()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: false)
            
        } else {
            print("Could not find index path")
        }
        
    }
    
    //MARK: formatVillager
    //creates, saves, and returns a Villager from a VillagerModel
    func formatVillager(for villager: VillagerModel) -> Villager {
        let newVillager = Villager(context: self.coreDataStack.managedContext)
        newVillager.api_id = villager.id
        newVillager.name = villager.name
        newVillager.gender = villager.gender
        newVillager.hobby = villager.nh_details.hobby
        newVillager.catchphrase = villager.nh_details.catchphrase
        newVillager.personality = villager.personality
        newVillager.sign = villager.sign
        newVillager.species = villager.species
        newVillager.quote = villager.nh_details.quote
        newVillager.imgURI = villager.image_url
        newVillager.iconURI = villager.nh_details.icon_url
        newVillager.houseImgURI = villager.nh_details.house_exterior_url
        newVillager.url = villager.url
        newVillager.birthdaySaved = false
        newVillager.birthMonth = villager.birthday_month
        
        //attempt to parse day from string provided
        if let parsedDay = Int64(villager.birthday_day) {
            newVillager.birthDay = parsedDay
        } else {
            newVillager.birthDay = 0
        }
        
        //save villager to coredata
        self.coreDataStack.managedContext.insert(newVillager)
        self.coreDataStack.saveContext()
        
        return newVillager
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //get the index for the selected item
        guard let indexes = collectionView.indexPathsForSelectedItems, let index = indexes.first else { return }
        //get the list at the index
        let selectedList = dataSource.itemIdentifier(for: index)
        
        guard let destinationVC = segue.destination as? VillagerListViewController else { return }
        destinationVC.list = selectedList
        destinationVC.coreDataStack = coreDataStack
    }
    
    //MARK: CollectionView  & layout methods

    //invalidates the layout so that on tablet the cell is sized correctly when rotating
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionViewLayout.invalidateLayout()
    }
    
    //sets the size for the collectionview items
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let phoneHeight = view.safeAreaLayoutGuide.layoutFrame.height
        //get the total space needed for the items and spacing
        let totalSpacing = itemsPerRow * contentSpacing
        //get the item height after spacing and insets
        let itemHeight = phoneHeight - totalSpacing - contentSpacing
        //item width is the size of the collection view minus the spacing between items
        let itemWidth = self.collectionView.bounds.size.width - itemSpacing
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
       return UIEdgeInsets(top: contentSpacing, left: contentSpacing, bottom: contentSpacing, right: contentSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        for cell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell) {
                //record the index of the current cell once scrolling has ended
                currentIndex = indexPath
                //if at the first index (the all villagers list) hide the delete btn
                if indexPath == [0,0] {
                    self.deleteBtn.isEnabled = false
                    self.deleteBtn.tintColor = UIColor.clear
                } else {
                    //otherwise show the button
                    self.deleteBtn.isEnabled = true
                    self.deleteBtn.tintColor = UIColor.systemBlue
                }
            }
        }
    }
}

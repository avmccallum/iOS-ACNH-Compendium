//
//  VillagerListViewController.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-10-21.
//

import UIKit
import CoreData

class VillagerListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    //MARK: Properties
    var list: List?
    var villagers = [Villager]()
    var coreDataStack: CoreDataStack!
    var itemsPerRow: CGFloat {
        let horizontalClass = self.traitCollection.horizontalSizeClass
        //if the width is regular and the height is any, have 4 items per row
        if horizontalClass == .regular {
            return 4
        } else {
            //otherwise have 2 per row
            return 2
        }
    }
    let interItemSpacing: CGFloat = 10
    let contentInsets: CGFloat = 10
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Villager>(collectionView: collectionView) {
        collectionView, indexPath, villager in
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VillagerCell", for: indexPath) as! VillagerCell
        
        cell.villagerName.text = villager.name
        self.getImage(for: villager.iconURI, in: cell)
        cell.layer.cornerRadius = 20
        
        if self.list?.name != "All Villagers" {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.deleteVillager))
            longPress.minimumPressDuration = 0.5
            longPress.delegate = self
            longPress.delaysTouchesBegan = true
            
            cell.addGestureRecognizer(longPress)
        }
        
        return cell
    }

    //MARK: View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        createSnapshot()
    }
    
    //MARK: createSnapshot
    func createSnapshot() {
        //get all the villagers for the list as an array of Villager objects
        villagers = list?.villagers.allObjects as! [Villager]
        //sort alphabetically descending
        villagers = villagers.sorted(by: { $0.name < $1.name })
        var snapshot = NSDiffableDataSourceSnapshot<Section, Villager>()
        snapshot.appendSections([.main])
        snapshot.appendItems(villagers, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    //MARK: deleteVillager
    //removes a villager from a list
    @objc func deleteVillager(_ gestureRecognizer: UILongPressGestureRecognizer) {
        //if the long press has begun
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            //get the location the gesture came from
            let p = gestureRecognizer.location(in: self.collectionView)
            //get the index path of that location
            let indexPath = self.collectionView.indexPathForItem(at: p)

            if let index = indexPath {
                //get the villager at the index
                guard let villagerToRemove = self.dataSource.itemIdentifier(for: index) else { return }
                
                let alertController = UIAlertController(title: "Delete Villager", message: "Are you sure you want to delete \(villagerToRemove.name) from this list?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {
                    _ in
                    
                    //remove the villager from the list, save, refresh
                    self.list?.removeFromVillagers(villagerToRemove)
                    self.coreDataStack.saveContext()
                    self.createSnapshot()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(deleteAction)
                present(alertController, animated: false)
            } else {
                print("Could not find index path")
            }
        }
    }
    
    //MARK: getImage
    //loads an image to the cell for the provided path
    func getImage(for path: String, in cell: VillagerCell) {
        guard let imgURL = URL(string: path) else {return}
        
        let imageTask = URLSession.shared.downloadTask(with: imgURL) {
            url, response, error in
            
            //if there is no error try and load the data to the cell imageview
            if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    cell.villagerImage.image = image
                }
            }
        }
        imageTask.resume()
    }

    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //get the index for the selected item
        guard let indexes = collectionView.indexPathsForSelectedItems, let index = indexes.first else { return }
        //get the villager at the index
        let selectedVillager = dataSource.itemIdentifier(for: index)
        
        guard let destinationVC = segue.destination as? DetailViewController else {return}
        destinationVC.villager = selectedVillager
        destinationVC.coreDataStack = coreDataStack
    }

    //MARK: CollectionView methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let phoneWidth = view.safeAreaLayoutGuide.layoutFrame.width
        //get the total space needed for the items and spacing
        let totalSpacing = itemsPerRow * interItemSpacing
        //get the width per item
        let itemWidth = (phoneWidth - totalSpacing - contentInsets) / itemsPerRow
        let itemHeight = itemWidth * 1.25
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
       return UIEdgeInsets(top: contentInsets, left: contentInsets, bottom: contentInsets, right: contentInsets)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }
}

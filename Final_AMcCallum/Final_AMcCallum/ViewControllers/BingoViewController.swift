//
//  BingoViewController.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-11-07.
//

import UIKit
import CoreData

class BingoViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var randomizeBtn: UIButton!
    
    //MARK: Actions
    @IBAction func randomizeBtnPressed(_ sender: UIButton) {
        //animate the button on press
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: [], animations: {
            self.randomizeBtn.transform = CGAffineTransform(scaleX: 5, y: 5)
            self.randomizeBtn.transform = .identity
        })
        resetGame()
    }
    
    @IBAction func selectModeBtnPressed(_ sender: UIButton) {
        presentModeController()
    }
    
    //MARK: Properties
    let defaults = UserDefaults.standard
    //layout properties
    let itemsPerRow: CGFloat = 5
    let interItemSpacing: CGFloat = 2
    let contentInsets: CGFloat = 10
    //data properties
    var coreDataStack: CoreDataStack!
    var tiles = [BingoTile]()
    private lazy var game = Game()
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, BingoTile>(collectionView: collectionView) {
        collectionView, indexPath, tile in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BingoCell", for: indexPath) as! BingoCell
        cell.layer.cornerRadius = 10
        
        cell.villagerName.text = tile.name

        //if the cell is the MIDDLE cell in a 5x5 grid
        if indexPath.row == 12 {
            //set the image and text to the free space
            cell.villagerImg.image = UIImage(named: "default_leaf")
            cell.villagerName.text = "Free Space"
        } else {
            self.getImage(for: tile.iconURI, in: cell)
        }
        
        //if the tile has been played show the stamp to mark it as such
        if tile.isPlayed {
            cell.bingoStamp.isHidden = false
        } else {
            cell.bingoStamp.isHidden = true
        }
        
        return cell
    }
    
    //MARK: View methods
    override func viewDidLoad() {
        super.viewDidLoad()

        //if the game has not been played before, create the initial card
        if defaults.bool(forKey: "hasBeenPlayed") == false {
            newGame()
        }
        //update to note the game has been played and retrieve all the card
        defaults.set(true, forKey: "hasBeenPlayed")
        //load the game and tiles saved regardless of if they were just created or previously saved
        loadGame()
        fetchTiles()
        
        collectionView.delegate = self
        //reload the collection view to ensure formatting
        collectionView.reloadData()
        modeLabel.text = game.mode
    }
    
    //MARK: getImage
    //loads an image to the cell for the provided path
    func getImage(for path: String, in cell: BingoCell) {
        guard let imgURL = URL(string: path) else {return}
        
        let imageTask = URLSession.shared.downloadTask(with: imgURL) {
            url, response, error in
            
            //if there is no error try and load the data to the cell imageview
            if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    cell.villagerImg.image = image
                }
            }
        }
        imageTask.resume()
    }
    
    //MARK: changeMode
    //changes the game mode
    func changeMode(to mode: String) {
        game.mode = mode
        modeLabel.text = game.mode
        coreDataStack.saveContext()
    }
    
    //MARK: presentModeController
    //presents an action sheet allowing the user to change the game mode
    func presentModeController() {
        let modeSheet = UIAlertController(title: "Select Mode", message: "Change the game mode you would like to play", preferredStyle: .actionSheet)
        //for each key representing a combo
        for key in keys {
            //create and add a corresponding action
            let keyAction = UIAlertAction(title: key, style: .default) {
                _ in
                self.changeMode(to: key)
            }
            modeSheet.addAction(keyAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        modeSheet.addAction(cancelAction)
        present(modeSheet, animated: false)
    }
    
    //MARK: fetchTiles
    //retrieves the saved bingo tiles from core data
    func fetchTiles() {
        let fetchRequest: NSFetchRequest<BingoTile> = BingoTile.fetchRequest()
        do {
            //try to get the tiles from core data and create snapshot
            tiles = try coreDataStack.managedContext.fetch(fetchRequest)
            //order the tiles by value
            tiles = tiles.sorted(by: { $0.tileValue < $1.tileValue })
            createSnapshot()
        } catch {
            print("ERROR fetching lists: \(error)")
        }
    }
    
    //MARK: createSnapshot
    func createSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, BingoTile>()
        snapshot.appendSections([.main])
        snapshot.appendItems(tiles, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    //MARK: newGame
    //create a new game with default options
    func newGame() {
        //create a new game and card and refresh the display, set game total to 0
        game = Game(context: self.coreDataStack.managedContext)
        game.mode = rowKey
        game.score = 0
        createNewCard()
        fetchTiles()
    }
    
    //MARK: loadGame
    //loads a game from core data
    func loadGame() {
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        do {
            //fetch request returns an array
            var games = [Game]()
            games = try coreDataStack.managedContext.fetch(fetchRequest)
            //get the game at index 0 because there should only be one active
            game = games[0]
        } catch {
            print("ERROR fetching game: \(error)")
        }
    }
    
    //MARK: createNewCard
    //creates a new bingo card game by retrieving villagers and creating bingo tiles
    func createNewCard() {
        var randVillagers = [Villager]()
        let fetchRequest: NSFetchRequest<Villager> = Villager.fetchRequest()
        do {
            //try to get random villagers from the data stack
            randVillagers = try coreDataStack.managedContext.fetch(fetchRequest)
        } catch {
            print("ERROR fetching lists: \(error)")
        }
        
        randVillagers.shuffle()
        randVillagers = Array(randVillagers[0..<25])

        //for each villager retrieved create a tile
        for i in 0..<25 {
            let tile = BingoTile(context: self.coreDataStack.managedContext)
            tile.id = UUID()
            tile.isPlayed = false
            tile.tileValue = Int64(pow(Double(2), Double(i)))
            tile.name = randVillagers[i].name
            tile.iconURI = randVillagers[i].iconURI
            tiles.append(tile)
        }
        
        //save generated card
        self.coreDataStack.saveContext()
    }
    
    //MARK: resetGame
    //removes all the tiles from core data and starts a new game
    func resetGame() {
        //remove all tiles from core data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "BingoTile")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try coreDataStack.managedContext.execute(deleteRequest)
        } catch let error as NSError {
            print("ERROR removing tiles: \(error)")
        }
        newGame()
    }
    
    //MARK: didSelectItemAt
    //when an item is selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! BingoCell
        //once selected, show stamp
        cell.bingoStamp.isHidden = false
        
        let tile = tiles[indexPath.row]
        //if the tile was not played before
        if !tile.isPlayed {
            //add the tile value to the game total
            game.score += tile.tileValue
            //mark the tile as played
            tile.isPlayed = true
        }
        
        self.coreDataStack.saveContext()
        
        //check if the game is over
        checkWin()
    }
    
    //MARK: checkWin
    //checks if the game has been won
    func checkWin() {
        //get the array of scores using the game mode as a key
        if let winningScores = winCombos[game.mode] {
            //for each score in the winning scores array
            for score in winningScores {
                //check if the score is a winning number
                if(Int(game.score) & score) == score {
                    //present an alert controller to notify user
                    let alertController = UIAlertController(title: "Congratulations!", message: "You got BINGO!", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default) {
                        _ in
                        //on ok if the game mode is anything but blackout, allow user to choose new mode
                        if self.game.mode != blackoutKey {
                            self.presentModeController()
                        } else {
                            //otherwise if the game is blackout, the entire board has been filled, a new game must be started
                            self.resetGame()
                        }
                    }
                    alertController.addAction(okAction)
                    present(alertController, animated: false)
                }
            }
        }
    }
    
    //MARK: motionBegan
    //on shake reset the game
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        resetGame()
    }
}

//MARK: Extensions
extension BingoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let phoneWidth = view.safeAreaLayoutGuide.layoutFrame.width
        //get the total space needed for the items and spacing
        let totalSpacing = itemsPerRow * interItemSpacing
        //get the width per item
        let itemWidth = (phoneWidth - totalSpacing - (contentInsets * 2)) / itemsPerRow
        let itemHeight = itemWidth * 1.25
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
       return UIEdgeInsets(top: 0, left: contentInsets, bottom: contentInsets, right: contentInsets)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }
}

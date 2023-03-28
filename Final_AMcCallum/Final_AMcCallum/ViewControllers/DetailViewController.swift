//
//  DetailViewController.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-10-21.
//

import UIKit
import SafariServices
import CoreData

class DetailViewController: UIViewController {
    
    //MARK: Properties
    var villager: Villager?
    var coreDataStack: CoreDataStack!

    //MARK: Outlets
    @IBOutlet weak var mainBackground: UIView!
    @IBOutlet weak var villagerImgBackground: UIView!
    @IBOutlet weak var villagerImg: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var quoteBackground: UIView!
    @IBOutlet weak var quoteLabel: UILabel!
    @IBOutlet weak var villagerQuoteCredit: UILabel!
    @IBOutlet weak var detailsBackground: UIView!
    @IBOutlet weak var speciesLabel: UILabel!
    @IBOutlet weak var personalityLabel: UILabel!
    @IBOutlet weak var hobbyLabel: UILabel!
    @IBOutlet weak var catchphraseLabel: UILabel!
    @IBOutlet weak var signLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var houseBackground: UIView!
    @IBOutlet weak var houseImg: UIImageView!
    @IBOutlet weak var bellBtn: UIButton!
    
    //MARK: Actions
    @IBAction func bellBtnPressed(_ sender: UIButton) {
        toggleBirthdayReminder()
    }
    
    @IBAction func editBtnPressed(_ sender: UIButton) {
        changeCatchphrase()
    }
    
    @IBAction func favouriteBtnPressed(_ sender: UIBarButtonItem) {
        let fetchRequest: NSFetchRequest<List> = List.fetchRequest()
        do {
            //try to get the lists from core data and present the alert
            let lists = try coreDataStack.managedContext.fetch(fetchRequest)
            presentListSheet(with: lists)
        } catch {
            print("ERROR fetching lists: \(error)")
        }
    }
    
    //MARK: View methods
    override func viewDidLoad() {
        super.viewDidLoad()

        mainBackground.layer.cornerRadius = 15
        villagerImgBackground.layer.cornerRadius = 15
        quoteBackground.layer.cornerRadius = 10
        detailsBackground.layer.cornerRadius = 15
        houseBackground.layer.cornerRadius = 15
        
        if let villager = villager {
            nameLabel.text = villager.name
            birthdayLabel.text = "\(villager.birthMonth) \(formatDay(for: villager.birthDay))"
            quoteLabel.text = "\"\(villager.quote)\""
            villagerQuoteCredit.text = "- \(villager.name)"
            speciesLabel.text = "Species:  \(villager.species)"
            personalityLabel.text = "Personality:  \(villager.personality)"
            hobbyLabel.text = "Hobby:  \(villager.hobby)"
            catchphraseLabel.text = "Catchphrase:  \"\(villager.catchphrase)\""
            signLabel.text = "Sign:  \(getSign(for: villager.sign))"
            linkLabel.text = villager.url
            
            //add tap recognizer to open link on tap
            let tap = UITapGestureRecognizer(target: self, action: #selector(openLink))
            linkLabel.isUserInteractionEnabled = true
            linkLabel.addGestureRecognizer(tap)
            
            if villager.gender.lowercased() == "male" {
                genderLabel.text = "♂"
            } else if villager.gender.lowercased() == "female" {
                genderLabel.text = "♀"
            }
            
            getImage(for: villager.imgURI, in: villagerImg)
            getImage(for: villager.houseImgURI, in: houseImg)
            
            if villager.birthdaySaved {
                bellBtn.setImage(UIImage(systemName: "bell.fill"), for: .normal)
            } else {
                bellBtn.setImage(UIImage(systemName: "bell"), for: .normal)
            }
        }
    }
    
    //MARK: openLink
    //opens the villager's link to a safari view
    @objc func openLink() {
        if let villager = villager, let url = URL(string: villager.url) {
            //configure the safari view controller
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            //show the new view controller
            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
    }
    
    //MARK: presentListSheet
    //presents an action sheet with the lists a villager can be saved to
    func presentListSheet(with lists: [List]) {
        if let villager = villager {
            let actionSheet = UIAlertController(title: "Save Villager", message: "Select the list you want to save \(villager.name) to:", preferredStyle: .actionSheet)
            //for each list create a new action
            for list in lists {
                //do not create an action for the "All Villagers" list
                if list.name != "All Villagers" {
                    //do not create an action for the lists the villager is already on
                    if !villager.lists.contains(list) {
                        let listAction = UIAlertAction(title: "\(list.name)", style: .default) {
                            _ in
                            
                            //save the list to the villager selected
                            list.addToVillagers(villager)
                            self.coreDataStack.saveContext()
                        }
                        //add each action to the action sheet
                        actionSheet.addAction(listAction)
                    }
                }
            }
            //add the cancel action
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(cancelAction)
            present(actionSheet, animated: false)
        }
    }
    
    //MARK: toggleBirthdayReminder
    //toggles the notification reminder for a villager's birthday
    //if the notification is already added, it removes it
    //otherwise it adds a new notification which repeats annually
    func toggleBirthdayReminder() {
        let center = UNUserNotificationCenter.current()
        //request permission for notifications
        center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {
            granted, error in
            if granted {
                print("granted")
            } else {
                print("denied")
            }
        })
        
        if let villager = self.villager {
            //if the birthday is already saved
            if villager.birthdaySaved {
                //remove the notifications scheduled for that villager
                center.removePendingNotificationRequests(withIdentifiers: ["notification.date.\(villager.api_id)"])
                villager.birthdaySaved = false
                //update bell image
                self.bellBtn.setImage(UIImage(systemName: "bell"), for: .normal)
                
            } else {
                //otherwise, create a notification and add it to the center
                let content = UNMutableNotificationContent()
                content.title = "It's \(villager.name)'s birthday!"
                content.body = "Don't forget to celebrate!"
                
                var month = 0
                //villager month is stored as a string so it must be parsed to a valid integer
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "LLLL"
                //if a valid date can be read from the month string
                if let date = formatter.date(from: villager.birthMonth) {
                    //use that as the month for the notification
                    month = Calendar.current.component(.month, from: date)
                }
                
                let calendarComponents: Set<Calendar.Component> = [.month, .day]
                var date = Calendar.current.dateComponents(calendarComponents, from: Date())
                //set the month and day to the villager's birthday
                date.month = month
                date.day = Int(villager.birthDay)
                //notification repeats annually
                print(date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                let request = UNNotificationRequest(identifier: "notification.date.\(villager.api_id)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) {
                    error in
                    if let error = error {
                        print("Notif error: \(error.localizedDescription)")
                    }
                }
                villager.birthdaySaved = true
                //update bell image
                self.bellBtn.setImage(UIImage(systemName: "bell.fill"), for: .normal)
                
                //present alert controller to let user know a notification was set
                let alertController = UIAlertController(title: "Reminder Set", message: "You'll be notified when it's \(villager.name)'s birthday", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(okAction)
                self.present(alertController, animated: false)
            }
        }
        //save changes
        self.coreDataStack.saveContext()
    }
    
    //MARK: changeCatchphrase
    //presents an alert controller to change a villager's catchphrase
    func changeCatchphrase() {
        if let villager = villager {
            let alertController = UIAlertController(title: "Change Catchphrase", message: "Enter the new catchprase:", preferredStyle: .alert)
            alertController.addTextField()
            alertController.textFields![0].text = villager.catchphrase
            
            let saveAction = UIAlertAction(title: "Save", style: .default) {
                _ in
                //get the text at the textfield and change the villager's catchphrase
                let textField = alertController.textFields![0]
                guard let text = textField.text else { return }
                villager.catchphrase = text
                //update label on screen
                self.catchphraseLabel.text = "Catchphrase:  \"\(villager.catchphrase)\""
                
                //save changes
                self.coreDataStack.saveContext()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: false)
        }
    }
    
    //MARK: formatDay
    //adds a suffix to a provided int day
    func formatDay(for day: Int64) -> String {
        var suffix = ""
        if day % 10 == 1 && day != 11 {
            suffix = "st"
        } else if day % 10 == 2 && day != 12 {
            suffix = "nd"
        } else if day % 10 == 3 && day != 13 {
            suffix = "rd"
        } else {
            suffix = "th"
        }
        
        let formattedDate = "\(day)\(suffix)"
        return formattedDate
    }
    
    //MARK: getSign
    //formats and returns a string with a villager's sign and the image representing it
    func getSign(for sign: String) -> String {
        var symbol = ""
        switch sign.lowercased() {
        case "aries":
            symbol = "♈︎"
        case "taurus":
            symbol = "♉︎"
        case "gemini":
            symbol = "♊︎"
        case "cancer":
            symbol = "♋︎"
        case "leo":
            symbol = "♌︎"
        case "virgo":
            symbol = "♍︎"
        case "libra":
            symbol = "♎︎"
        case "scorpio":
            symbol = "♏︎"
        case "sagittarius":
            symbol = "♐︎"
        case "capricorn":
            symbol = "♑︎"
        case "aquarius":
            symbol = "♒︎"
        case "pisces":
            symbol = "♓︎"
        default:
            symbol = ""
        }
        let formattedSign = "\(sign)   \(symbol)"
        return formattedSign
    }
    
    //MARK: getImage
    //loads an image to the cell for the provided path
    func getImage(for path: String, in imageView: UIImageView) {
        guard let imgURL = URL(string: path) else {return}
        
        let imageTask = URLSession.shared.downloadTask(with: imgURL) {
            url, response, error in
            
            //if there is no error try and load the data to the cell imageview
            if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
        imageTask.resume()
    }
}

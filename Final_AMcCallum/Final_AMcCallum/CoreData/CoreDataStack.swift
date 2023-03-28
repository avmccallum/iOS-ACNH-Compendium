//
//  CoreDataStack.swift
//  Midterm_AMcCallum
//
//  Created by Ashley Mccallum on 2022-10-17.
//

import Foundation
import CoreData


class CoreDataStack{
    private let modelName: String
    
    init(modelName: String){
        self.modelName = modelName
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        //access the container with the provided model name
        let container = NSPersistentContainer(name: self.modelName)
        //load the items in the container
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var managedContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    func saveContext () {
        //check if there are changes
        guard managedContext.hasChanges else { return }
        
        do {
            //try to save
            try managedContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
    }
    
}

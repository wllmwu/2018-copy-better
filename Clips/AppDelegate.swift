//
//  AppDelegate.swift
//  Clips
//
//  Created by Bill Wu on 6/11/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData
import ClipsKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var managedObjectContext: NSManagedObjectContext!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if !DefaultsManager.hasLaunched {
            // first launch ever - set some default settings and data
            self.managedObjectContext = self.persistentContainer.viewContext
            self.persistentContainer.setUpFirstLaunch()
            
            DefaultsManager.favoritesEnabled = true
            DefaultsManager.showLastCopiedInApp = true
            DefaultsManager.askForTitleForLastCopiedInApp = true
            DefaultsManager.autoAddLastCopiedInApp = false
            DefaultsManager.wrapClipsInKeyboard = false
            
            DefaultsManager.hasLaunched = true
            DefaultsManager.hasLaunched2_0 = true
            DefaultsManager.hasLaunched2_1 = true
        }
        if !DefaultsManager.hasLaunched2_0 {
            // has launched before updating to version 2.0 - migrate old clips to the new model
            self.managedObjectContext = self.persistentContainer.viewContext
            self.persistentContainer.migrateModelV1To2()
            DefaultsManager.hasLaunched2_0 = true
        }
        if !DefaultsManager.hasLaunched2_1 {
            // has launched before updating to version 2.1 - add new settings defaults
            DefaultsManager.favoritesEnabled = true
            DefaultsManager.askForTitleForLastCopiedInApp = true
            DefaultsManager.autoAddLastCopiedInApp = false
            DefaultsManager.wrapClipsInKeyboard = false
            DefaultsManager.hasLaunched2_1 = true
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let navigation = self.window?.rootViewController as? UINavigationController else {
            return false
        }
        if url.path.starts(with: "/main") {
            DefaultsManager.urlToHandleInMain = url
            navigation.dismiss(animated: false, completion: nil)
            navigation.popToRootViewController(animated: false)
        }
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == "CopyClipIntent" {
            guard let intent = userActivity.interaction?.intent as? CopyClipIntent, let clipReference = intent.clip, let clip = Clip.getReferencedClip(from: clipReference, context: self.persistentContainer.viewContext) else {
                return false
            }
            ClipboardManager.copyToPasteboard(item: clip.contents)
            NotificationCenter.default.post(name: Notification.Name("ShowCopiedToast"), object: nil)
            return true
        }
        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        guard let navigation = self.window?.rootViewController as? UINavigationController else {
            return
        }
        if DefaultsManager.shouldRefreshAppContext {
            guard let root = navigation.viewControllers.first as? MainTableViewController else {
                return
            }
            navigation.dismiss(animated: false, completion: nil)
            navigation.popToRootViewController(animated: false)
            self.persistentContainer.viewContext.reset()
            root.refreshRootFolder()
            DefaultsManager.shouldRefreshAppContext = false
        }
        else {
            guard let viewController = navigation.visibleViewController as? MainTableViewController else {
                return
            }
            viewController.loadData()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        DefaultsManager.shouldRefreshAppContext = false
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: ClipsPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = ClipsPersistentContainer(name: "Clips")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                AppDelegate.alertFatalError(error: error)
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                AppDelegate.alertFatalError(error: nserror)
            }
        }
    }
    
    // MARK: - If this function is called, things are bad
    
    static func alertFatalError(error: NSError) {
        alertFatalError(message: "Unresolved error: \(error), \(error.userInfo)")
    }
    
    static func alertFatalError(message: String) {
        print(message)
        let alert = UIAlertController(title: "An error occurred", message: "Failed to access the container or Core Data in some way, most likely because the phone is out of storage space. The app may not work properly.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        let root: UINavigationController? = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        root?.present(alert, animated: true, completion: nil)
    }

}


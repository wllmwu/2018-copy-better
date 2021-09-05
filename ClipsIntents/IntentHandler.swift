//
//  IntentHandler.swift
//  ClipsIntents
//
//  Created by Bill Wu on 8/27/21.
//  Copyright © 2021 William Wu. All rights reserved.
//

import Intents
import CoreData
import ClipsKit

class IntentHandler: INExtension, CopyClipIntentHandling, AddClipIntentHandling {
    
    private var _managedObjectContext: NSManagedObjectContext?
    
    private func getContext() -> NSManagedObjectContext? {
        if self._managedObjectContext == nil {
            let container = ClipsPersistentContainer(name: "Clips")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if error == nil {
                    self._managedObjectContext = container.viewContext
                }
            })
        }
        return self._managedObjectContext
    }
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    // MARK: - CopyClipIntentHandling protocol
    
    func handle(intent: CopyClipIntent, completion: @escaping (CopyClipIntentResponse) -> Void) {
        guard let context = self.getContext() else {
            return completion(CopyClipIntentResponse(code: .failure, userActivity: nil))
        }
        guard let clipReference = intent.clip, let clip = Clip.getReferencedClip(from: clipReference, context: context) else {
            return completion(CopyClipIntentResponse(code: .failureNonexistent, userActivity: nil))
        }
        
        ClipboardManager.copyToPasteboard(item: clip.contents)
        let response = CopyClipIntentResponse.success(clipContents: ClipboardManager.stringFromItem(clip.contents) ?? "")
        return completion(response)
    }
    
    func resolveClip(for intent: CopyClipIntent, with completion: @escaping (CopyClipClipResolutionResult) -> Void) {
        guard let clipReference = intent.clip else {
            return completion(.needsValue())
        }
        guard let context = self.getContext() else {
            return completion(.unsupported(forReason: .unknownError))
        }
        guard let _ = Clip.getReferencedClip(from: clipReference, context: context) else {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", clipReference.displayString)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            
            let matchingClips: [Clip]
            do {
                matchingClips = try context.fetch(request)
            }
            catch {
                return completion(.unsupported(forReason: .unknownError))
            }
            
            if matchingClips.count == 0 {
                return completion(.unsupported(forReason: .noMatches))
            }
            else {
                var choices: [ClipReference] = []
                for clip in matchingClips {
                    if let ref = Clip.getIntentReference(for: clip) {
                        choices.append(ref)
                    }
                }
                return completion(.disambiguation(with: choices))
            }
        }
        
        return completion(.success(with: clipReference))
    }
    
    func provideClipOptionsCollection(for intent: CopyClipIntent, searchTerm: String?, with completion: @escaping (INObjectCollection<ClipReference>?, Error?) -> Void) {
        guard let context = self.getContext() else {
            return completion(nil, nil)
        }
        
        let request = NSFetchRequest<Clip>(entityName: "Clip")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        if let searchString = searchTerm {
            request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchString)
        }
        else {
            request.predicate = NSPredicate(format: "title != NIL")
        }
        
        let matchingClips: [Clip]
        do {
            matchingClips = try context.fetch(request)
        }
        catch {
            return completion(nil, nil)
        }
        
        var choices: [ClipReference] = []
        for clip in matchingClips {
            if let ref = Clip.getIntentReference(for: clip) {
                choices.append(ref)
            }
        }
        return completion(INObjectCollection(items: choices), nil)
    }
    
    // MARK: - AddClipIntentHandling protocol
    
    func handle(intent: AddClipIntent, completion: @escaping (AddClipIntentResponse) -> Void) {
        guard let context = self.getContext(), let entity = NSEntityDescription.entity(forEntityName: "Clip", in: context) else {
            return completion(AddClipIntentResponse(code: .failure, userActivity: nil))
        }
        guard let rootFolder = Folder.getRootFolder(context: context) else {
            return completion(AddClipIntentResponse(code: .failureRequiringAppLaunch, userActivity: nil))
        }
        
        for clip in rootFolder.clipsArray {
            clip.index += 1
        }
        
        let contents = ClipboardManager.itemFromPlaintext(intent.contents ?? "")
        let title = intent.title ?? ""
        
        let newClip = Clip(entity: entity, insertInto: context)
        if title.count > 0 {
            newClip.title = title
        }
        newClip.contents = contents
        newClip.index = 0
        newClip.folder = rootFolder
        
        do {
            try context.save()
            let defaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
            defaults.set(true, forKey: "shouldRefreshAppContext")
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
            return completion(AddClipIntentResponse(code: .failure, userActivity: nil))
        }
        
        let response = AddClipIntentResponse.success(inputText: intent.contents ?? "")
        return completion(response)
    }
    
    func resolveTitle(for intent: AddClipIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        completion(.success(with: intent.title ?? ""))
    }
    
}

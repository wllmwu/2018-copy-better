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

class IntentHandler: INExtension, CopyClipIntentHandling {
    
    private var managedObjectContext: NSManagedObjectContext?
    
    private func getContext() -> NSManagedObjectContext? {
        if self.managedObjectContext == nil {
            let container = ClipsPersistentContainer(name: "Clips")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if error == nil {
                    self.managedObjectContext = container.viewContext
                }
            })
        }
        return self.managedObjectContext
    }
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    func handle(intent: CopyClipIntent, completion: @escaping (CopyClipIntentResponse) -> Void) {
        guard let context = self.getContext() else {
            return completion(CopyClipIntentResponse(code: .failure, userActivity: nil))
        }
        guard let clipReference = intent.clip, let clip = Clip.getReferencedClip(from: clipReference, context: context) else {
            return completion(CopyClipIntentResponse(code: .failureNonexistent, userActivity: nil))
        }
        print("title: \(clip.title ?? "nil")")
        print("contents: \(clip.contents)")
        
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
    
}

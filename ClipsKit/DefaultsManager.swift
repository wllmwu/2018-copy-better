//
//  DefaultsManager.swift
//  ClipsKit
//
//  Created by William Wu on 9/16/21.
//  Copyright © 2021 William Wu. All rights reserved.
//

import UIKit

public class DefaultsManager: NSObject {
    
    private static let defaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    
    private static var HAS_LAUNCHED_KEY = "launchedBefore"
    public static var hasLaunched: Bool {
        get {
            return defaults.bool(forKey: HAS_LAUNCHED_KEY)
        }
        set {
            defaults.set(newValue, forKey: HAS_LAUNCHED_KEY)
        }
    }
    
    private static var HAS_LAUNCHED_2_0_KEY = "launched2.0"
    public static var hasLaunched2_0: Bool {
        get {
            return defaults.bool(forKey: HAS_LAUNCHED_2_0_KEY)
        }
        set {
            defaults.set(newValue, forKey: HAS_LAUNCHED_2_0_KEY)
        }
    }
    
    private static var HAS_LAUNCHED_2_1_KEY = "launched2.1"
    public static var hasLaunched2_1: Bool {
        get {
            return defaults.bool(forKey: HAS_LAUNCHED_2_1_KEY)
        }
        set {
            defaults.set(newValue, forKey: HAS_LAUNCHED_2_1_KEY)
        }
    }
    
    private static var HAS_LAUNCHED_2_2_KEY = "launched2.2"
    public static var hasLaunched2_2: Bool {
        get {
            return defaults.bool(forKey: HAS_LAUNCHED_2_2_KEY)
        }
        set {
            defaults.set(newValue, forKey: HAS_LAUNCHED_2_2_KEY)
        }
    }
    
    private static var HAS_LAUNCHED_2_3_KEY = "launched2.3"
    public static var hasLaunched2_3: Bool {
        get {
            return defaults.bool(forKey: HAS_LAUNCHED_2_3_KEY)
        }
        set {
            defaults.set(newValue, forKey: HAS_LAUNCHED_2_3_KEY)
        }
    }
    
    private static var HAS_LAUNCHED_2_4_KEY = "launched2.4"
    public static var hasLaunched2_4: Bool {
        get {
            return defaults.bool(forKey: HAS_LAUNCHED_2_4_KEY)
        }
        set {
            defaults.set(newValue, forKey: HAS_LAUNCHED_2_4_KEY)
        }
    }
    
    private static var FAVORITES_ENABLED_KEY = "enableFavorites"
    public static var favoritesEnabled: Bool {
        get {
            return defaults.bool(forKey: FAVORITES_ENABLED_KEY)
        }
        set {
            defaults.set(newValue, forKey: FAVORITES_ENABLED_KEY)
        }
    }
    
    private static var SHOW_LAST_COPIED_KEY = "showLastCopiedInMain"
    public static var showLastCopiedInApp: Bool {
        get {
            return defaults.bool(forKey: SHOW_LAST_COPIED_KEY)
        }
        set {
            defaults.set(newValue, forKey: SHOW_LAST_COPIED_KEY)
        }
    }
    
    private static var ASK_FOR_TITLE_KEY = "askForTitleAddingLastCopied"
    public static var askForTitleForLastCopiedInApp: Bool {
        get {
            return defaults.bool(forKey: ASK_FOR_TITLE_KEY)
        }
        set {
            defaults.set(newValue, forKey: ASK_FOR_TITLE_KEY)
        }
    }
    
    private static var AUTO_ADD_KEY = "autoAddLastCopied"
    public static var autoAddLastCopiedInApp: Bool {
        get {
            return defaults.bool(forKey: AUTO_ADD_KEY)
        }
        set {
            defaults.set(newValue, forKey: AUTO_ADD_KEY)
        }
    }
    
    private static var PASTEBOARD_COUNT_FOR_AUTO_ADD_KEY = "pasteboardCountForAutoAdd"
    public static var pasteboardCountForAutoAdd: Int {
        get {
            return defaults.integer(forKey: PASTEBOARD_COUNT_FOR_AUTO_ADD_KEY)
        }
        set {
            defaults.set(newValue, forKey: PASTEBOARD_COUNT_FOR_AUTO_ADD_KEY)
        }
    }
    
    private static var STORE_CLIP_FORMATTING_KEY = "storeClipFormattingInApp"
    public static var storeClipFormattingInApp: Bool {
        get {
            return defaults.bool(forKey: STORE_CLIP_FORMATTING_KEY)
        }
        set {
            defaults.set(newValue, forKey: STORE_CLIP_FORMATTING_KEY)
        }
    }
    
    private static var SHOW_LAST_COPIED_KEYBOARD_KEY = "showLastCopiedInKeyboard"
    public static var showLastCopiedInKeyboard: Bool {
        get {
            return defaults.bool(forKey: SHOW_LAST_COPIED_KEYBOARD_KEY)
        }
        set {
            defaults.set(newValue, forKey: SHOW_LAST_COPIED_KEYBOARD_KEY)
        }
    }
    
    private static var WRAP_CLIPS_KEY = "wrapClipsInKeyboard"
    public static var wrapClipsInKeyboard: Bool {
        get {
            return defaults.bool(forKey: WRAP_CLIPS_KEY)
        }
        set {
            defaults.set(newValue, forKey: WRAP_CLIPS_KEY)
        }
    }
    
    private static var URL_TO_HANDLE_KEY = "urlToHandleInMain"
    public static var urlToHandleInMain: URL? {
        get {
            return defaults.url(forKey: URL_TO_HANDLE_KEY)
        }
        set {
            defaults.set(newValue, forKey: URL_TO_HANDLE_KEY)
        }
    }
    
    private static var REFRESH_CONTEXT_KEY = "shouldRefreshAppContext"
    public static var shouldRefreshAppContext: Bool {
        get {
            return defaults.bool(forKey: REFRESH_CONTEXT_KEY)
        }
        set {
            defaults.set(newValue, forKey: REFRESH_CONTEXT_KEY)
        }
    }
    
}

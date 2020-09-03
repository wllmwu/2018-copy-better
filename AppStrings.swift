//
//  AppStrings.swift
//  Clips
//
//  Created by Bill Wu on 8/17/20.
//  Copyright © 2020 William Wu. All rights reserved.
//

import Foundation

struct AppStrings {
    static var DEFAULT_CLIP_TITLE_1: String {
        return NSLocalizedString("Shrug", comment: "default clip title 1")
    }
    
    static var DEFAULT_CLIP_TITLE_2: String {
        return NSLocalizedString("Example", comment: "default clip title 2")
    }
    
    static var SEARCH_BAR_PLACEHOLDER: String {
        return NSLocalizedString("Search", comment: "search bar placeholder")
    }
    
    static var TOAST_MESSAGE_COPIED: String {
        return NSLocalizedString("Copied", comment: "\"Copied\" toast message")
    }
    
    static var TOAST_MESSAGE_ADDED: String {
        return NSLocalizedString("Added", comment: "\"Added\" toast message")
    }
    
    static var EMPTY_CLIP_PLACEHOLDER: String {
        return NSLocalizedString("(Empty)", comment: "empty clip contents placeholder")
    }
    
    static var COPY_BUTTON_TITLE: String {
        return NSLocalizedString("Copy", comment: "\"Copy\" button title")
    }
    
    static var ADD_TO_LIST_BUTTON_TITLE: String {
        return NSLocalizedString("Add to list", comment: "\"Add to list\" button title")
    }
    
    static var LAST_COPIED_TITLE: String {
        return NSLocalizedString("Last copied", comment: "\"Last copied\" title")
    }
    
    static var TOAST_MESSAGE_SAVED: String {
        return NSLocalizedString("Saved", comment: "\"Saved\" toast message")
    }
    
    static var ADD_CLIP_TITLE: String {
        return NSLocalizedString("Add Clip", comment: "\"Add Clip\" title")
    }
    
    static var ADD_BUTTON_TITLE: String {
        return NSLocalizedString("Add", comment: "\"Add\" button title")
    }
    
    static var TITLE_CONFIG_TITLE: String {
        return NSLocalizedString("Title", comment: "\"Title\" share configuration item title")
    }
    
    static var KEYBOARD_ERROR_MESSAGE: String {
        return NSLocalizedString("Error retrieving clips[...]", comment: "keyboard error message")
    }
    
    static var KEYBOARD_EMPTY_MESSAGE: String {
        return NSLocalizedString("(No items)", comment: "keyboard empty list message")
    }
    
    static var ADD_ITEM_TITLE: String {
        return NSLocalizedString("Add item", comment: "\"Add item\" title")
    }
    
    static var NEW_FOLDER_ACTION: String {
        return NSLocalizedString("New folder", comment: "\"New folder\" action")
    }
    
    static var NEW_CLIP_ACTION: String {
        return NSLocalizedString("New clip", comment: "\"New clip\" action")
    }
    
    static var CANCEL_ACTION: String {
        return NSLocalizedString("Cancel", comment: "\"Cancel\" action")
    }
    
    static var SAVE_ACTION: String {
        return NSLocalizedString("Save", comment: "\"Save\" action")
    }
    
    static var OK_ACTION: String {
        return NSLocalizedString("OK", comment: "\"OK\" action")
    }
    
    static var FOLDER_NAME_PLACEHOLDER: String {
        return NSLocalizedString("Folder name", comment: "\"Folder name\" placeholder")
    }
    
    static var EMPTY_FOLDER_NAME_MESSAGE: String {
        return NSLocalizedString("Name cannot be empty!", comment: "empty folder name error message")
    }
    
    static var DELETE_FOLDER_CONFIRM_MESSAGE_1: String {
        return NSLocalizedString("Delete folder", comment: "delete folder confirm 1")
    }
    
    static var DELETE_FOLDER_CONFIRM_MESSAGE_2: String {
        return NSLocalizedString("and its contents", comment: "delete folder confirm 2")
    }
    
    static var NO_UNDO_MESSAGE: String {
        return NSLocalizedString("You cannot undo[...]", comment: "no undo message")
    }
}

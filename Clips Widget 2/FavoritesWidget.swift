//
//  FavoritesWidget.swift
//  Clips Widget 2Extension
//
//  Created by William Wu on 9/7/21.
//  Copyright © 2021 William Wu. All rights reserved.
//

import SwiftUI
import WidgetKit
import CoreData
import ClipsKit

struct FavoritesProvider: TimelineProvider {
    
    private let NUM_TO_DISPLAY_LARGE_WIDGET = 10
    private let NUM_TO_DISPLAY_MEDIUM_WIDGET = 5
    
    private func fetchFavorites(in context: Context) -> [ClipIdentifiable]? {
        let container = ClipsPersistentContainer(name: "Clips")
        var foundStores = true
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if error != nil {
                foundStores = false
            }
        })
        if !foundStores {
            return nil
        }
        
        let limit = context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET
        guard let favoriteClips = Clip.getFavorites(context: container.viewContext, limit: limit) else {
            return nil
        }
        
        var references: [ClipIdentifiable] = []
        for clip in favoriteClips {
            references.append(ClipIdentifiable(uri: clip.uriRepresentation, title: clip.title, contents: ClipboardManager.stringFromPlaintext(inItem: clip.contents) ?? ""))
        }
        
        return references
    }
    
    private func generateEntry(in context: Context) -> FolderTimelineEntry {
        let count = (context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET) + 1
        let cellHeight = context.displaySize.height / CGFloat(count)
        return FolderTimelineEntry(date: Date(), folderName: "", clips: self.fetchFavorites(in: context) ?? [], cellHeight: cellHeight)
    }
    
    func placeholder(in context: Context) -> FolderTimelineEntry {
        let mockFavorites = [ClipIdentifiable(uri: "1", title: AppStrings.DEFAULT_CLIP_TITLE_1, contents: AppStrings.DEFAULT_CLIP_CONTENTS_1), ClipIdentifiable(uri: "2", title: AppStrings.DEFAULT_CLIP_TITLE_2, contents: AppStrings.DEFAULT_CLIP_CONTENTS_2)]
        let count = (context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET) + 1
        let cellHeight = context.displaySize.height / CGFloat(count)
        return FolderTimelineEntry(date: Date(), folderName: "", clips: mockFavorites, cellHeight: cellHeight)
    }

    func getSnapshot(in context: Context, completion: @escaping (FolderTimelineEntry) -> ()) {
        if context.isPreview {
            return completion(self.placeholder(in: context))
        }
        return completion(self.generateEntry(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FolderTimelineEntry>) -> ()) {
        let timeline = Timeline<FolderTimelineEntry>(entries: [self.generateEntry(in: context)], policy: .never)
        completion(timeline)
    }
}

struct FavoritesWidgetEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: FavoritesProvider.Entry
    
    var body: some View {
        ZStack {
            Color("WidgetBackground")
            VStack(spacing: 0.0) {
                ZStack {
                    Rectangle()
                        .fill(Color("AccentColor"))
                        .frame(minWidth: nil, idealWidth: nil, maxWidth: nil, minHeight: nil, idealHeight: nil, maxHeight: entry.cellHeight, alignment: .leading)
                    HStack {
                        Text(AppStrings.FAVORITES_TITLE)
                            .fontWeight(.bold)
                            .truncationMode(.head)
                        Spacer()
                        Link(destination: URL(string: "copybetter:///main?action=clear")!, label: {
                            HStack(spacing: 0.0) {
                                Image(systemName: "clear.fill")
                                Text(AppStrings.CLEAR_CLIPBOARD_WIDGET_ACTION)
                                    .padding(.trailing)
                            }
                        })
                    }
                    .padding(.leading)
                }
                ForEach(entry.clips) { clipIdentifiable in
                    Link(destination: URL(string: "copybetter:///main/favorites?action=copy&uri=\(clipIdentifiable.uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!, label: {
                        HStack {
                            if let title = clipIdentifiable.title {
                                Text(title)
                                    .fontWeight(.bold)
                            }
                            Text(clipIdentifiable.contents)
                            Spacer()
                            Text(AppStrings.COPY_BUTTON_TITLE)
                                .foregroundColor(Color("AccentColor"))
                        }
                        .padding(.horizontal)
                        .frame(minWidth: nil, idealWidth: nil, maxWidth: .infinity, minHeight: nil, idealHeight: nil, maxHeight: entry.cellHeight, alignment: .leading)
                    })
                    .background(Color("WidgetBackground"))
                }
                Spacer(minLength: 0)
            }
        }
        .widgetURL(URL(string: "copybetter:///main/favorites/"))
    }
}

struct FavoritesWidget: Widget {
    let kind: String = "com.williamwu.clips.favorites-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoritesProvider()) { entry in
            FavoritesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(AppStrings.FAVORITES_WIDGET_DISPLAY_NAME)
        .description(AppStrings.FAVORITES_WIDGET_DESCRIPTION)
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct FavoritesWidget_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesWidgetEntryView(entry: FolderTimelineEntry(date: Date(), folderName: "", clips: [ClipIdentifiable(uri: "a", title: "AAA", contents: "aaa"), ClipIdentifiable(uri: "b", title: "BBB", contents: "bbb"), ClipIdentifiable(uri: "c", title: "CCC CCC CCC CCC CCC CCC", contents: "ccc ccc ccc ccc ccc ccc"), ClipIdentifiable(uri: "d", title: nil, contents: "qwertyuiop asdfghjkl;"), ClipIdentifiable(uri: "e", title: nil, contents: "qwertyuiop qwertyuiop qwertyuiop")], cellHeight: 31.5))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

//
//  ClipsFavoritesWidget.swift
//  ClipsFavoritesWidget
//
//  Created by Bill Wu on 9/6/21.
//  Copyright © 2021 William Wu. All rights reserved.
//

import SwiftUI
import WidgetKit
import CoreData
import ClipsKit

struct FavoritesReference: Identifiable {
    let uri: String
    let title: String?
    let contents: String
    var id: String { uri }
}

struct FavoritesEntry: TimelineEntry {
    let date: Date
    let favorites: [FavoritesReference]
}

struct Provider: TimelineProvider {
    
    private func fetchFavorites(in context: Context) -> [FavoritesReference]? {
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
        
        let limit = context.family == .systemLarge ? 10 : 5
        guard let favoriteClips = Clip.getFavorites(context: container.viewContext, limit: limit) else {
            return nil
        }
        
        var references: [FavoritesReference] = []
        for clip in favoriteClips {
            references.append(FavoritesReference(uri: clip.uriRepresentation, title: clip.title, contents: ClipboardManager.stringFromPlaintext(inItem: clip.contents) ?? ""))
        }
        
        return references
    }
    
    private func generateEntry(in context: Context) -> FavoritesEntry {
        return FavoritesEntry(date: Date(), favorites: self.fetchFavorites(in: context) ?? [])
    }
    
    func placeholder(in context: Context) -> FavoritesEntry {
        let mockFavorites = [FavoritesReference(uri: "", title: AppStrings.DEFAULT_CLIP_TITLE_1, contents: AppStrings.DEFAULT_CLIP_CONTENTS_1), FavoritesReference(uri: "", title: AppStrings.DEFAULT_CLIP_TITLE_2, contents: AppStrings.DEFAULT_CLIP_CONTENTS_2)]
        return FavoritesEntry(date: Date(), favorites: mockFavorites)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> ()) {
        if context.isPreview {
            return completion(self.placeholder(in: context))
        }
        return completion(self.generateEntry(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> ()) {
        let timeline = Timeline<FavoritesEntry>(entries: [self.generateEntry(in: context)], policy: .never)
        completion(timeline)
    }
}

struct ClipsFavoritesWidgetEntryView : View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            ForEach(entry.favorites) { clipReference in
                Text(clipReference.title ?? "")
            }
        }
    }
}

@main
struct ClipsFavoritesWidget: Widget {
    let kind: String = "ClipsFavoritesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClipsFavoritesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(AppStrings.FAVORITES_WIDGET_DISPLAY_NAME)
        .description(AppStrings.FAVORITES_WIDGET_DESCRIPTION)
    }
}

struct ClipsFavoritesWidget_Previews: PreviewProvider {
    static var previews: some View {
        ClipsFavoritesWidgetEntryView(entry: FavoritesEntry(date: Date(), favorites: [FavoritesReference(uri: "a", title: "AAA", contents: "aaa"), FavoritesReference(uri: "b", title: "BBB", contents: "bbb"), FavoritesReference(uri: "c", title: "CCC", contents: "ccc")]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

//
//  FavoritesWidget.swift
//  Clips Widget 2Extension
//
//  Created by Bill Wu on 9/7/21.
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
    let cellHeight: CGFloat
}

struct FavoritesProvider: TimelineProvider {
    
    private let NUM_TO_DISPLAY_LARGE_WIDGET = 10
    private let NUM_TO_DISPLAY_MEDIUM_WIDGET = 5
    
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
        
        let limit = context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET
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
        let count = context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET
        let cellHeight = context.displaySize.height / CGFloat(count)
        return FavoritesEntry(date: Date(), favorites: self.fetchFavorites(in: context) ?? [], cellHeight: cellHeight)
    }
    
    func placeholder(in context: Context) -> FavoritesEntry {
        let mockFavorites = [FavoritesReference(uri: "1", title: AppStrings.DEFAULT_CLIP_TITLE_1, contents: AppStrings.DEFAULT_CLIP_CONTENTS_1), FavoritesReference(uri: "2", title: AppStrings.DEFAULT_CLIP_TITLE_2, contents: AppStrings.DEFAULT_CLIP_CONTENTS_2)]
        let count = context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET
        let cellHeight = context.displaySize.height / CGFloat(count)
        return FavoritesEntry(date: Date(), favorites: mockFavorites, cellHeight: cellHeight)
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

struct FavoritesWidgetEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: FavoritesProvider.Entry
    
    var body: some View {
        ZStack {
            Color("WidgetBackground")
            VStack {
                ForEach(entry.favorites) { clipReference in
                    Link(destination: URL(string: "copybetter:///main/favorites?action=copy&uri=\(clipReference.uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!, label: {
                        HStack {
                            if let title = clipReference.title {
                                Text(title)
                                    .fontWeight(.bold)
                            }
                            Text(clipReference.contents)
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
        FavoritesWidgetEntryView(entry: FavoritesEntry(date: Date(), favorites: [FavoritesReference(uri: "a", title: "AAA", contents: "aaa"), FavoritesReference(uri: "b", title: "BBB", contents: "bbb"), FavoritesReference(uri: "c", title: "CCC CCC CCC CCC CCC CCC", contents: "ccc ccc ccc ccc ccc ccc"), FavoritesReference(uri: "d", title: nil, contents: "qwertyuiop asdfghjkl;"), FavoritesReference(uri: "e", title: nil, contents: "qwertyuiop qwertyuiop qwertyuiop")], cellHeight: 31.5))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

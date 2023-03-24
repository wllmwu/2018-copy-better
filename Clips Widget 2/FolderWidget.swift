//
//  FolderWidget.swift
//  Clips Widget 2Extension
//
//  Created by William Wu on 3/24/23.
//  Copyright © 2023 William Wu. All rights reserved.
//

import SwiftUI
import WidgetKit
import CoreData
import ClipsKit

struct ClipIdentifiable: Identifiable {
    let uri: String
    let title: String?
    let contents: String
    var id: String { uri }
}

struct FolderTimelineEntry: TimelineEntry {
    let date: Date
    let clips: [ClipIdentifiable]
    let cellHeight: CGFloat
}

struct FolderTimelineProvider: IntentTimelineProvider {
    
    private let NUM_TO_DISPLAY_LARGE_WIDGET = 10
    private let NUM_TO_DISPLAY_MEDIUM_WIDGET = 5
    
    private func fetchClips(from folderRef: FolderReference, in context: Context) -> [ClipIdentifiable]? {
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
        
        guard let folder = Folder.getReferencedFolder(from: folderRef, context: container.viewContext) else {
            return nil
        }
        let limit = context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET
        let sliceEnd = min(limit, folder.clipsArray.count)
        let clips = folder.clipsArray[..<sliceEnd]
        
        var identifiables: [ClipIdentifiable] = []
        for clip in clips {
            identifiables.append(ClipIdentifiable(uri: clip.uriRepresentation, title: clip.title, contents: ClipboardManager.stringFromPlaintext(inItem: clip.contents) ?? ""))
        }
        
        return identifiables
    }
    
    private func generateEntry(for configuration: SelectFolderIntent, in context: Context) -> FolderTimelineEntry {
        let count = context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET
        let cellHeight = context.displaySize.height / CGFloat(count)
        guard let folderRef = configuration.folder else {
            return FolderTimelineEntry(date: Date(), clips: [], cellHeight: cellHeight)
        }
        return FolderTimelineEntry(date: Date(), clips: self.fetchClips(from: folderRef, in: context) ?? [], cellHeight: cellHeight)
    }
    
    func placeholder(in context: Context) -> FolderTimelineEntry {
        let mockClips = [ClipIdentifiable(uri: "1", title: AppStrings.DEFAULT_CLIP_TITLE_1, contents: AppStrings.DEFAULT_CLIP_CONTENTS_1), ClipIdentifiable(uri: "2", title: AppStrings.DEFAULT_CLIP_TITLE_2, contents: AppStrings.DEFAULT_CLIP_CONTENTS_2)]
        let count = context.family == .systemLarge ? NUM_TO_DISPLAY_LARGE_WIDGET : NUM_TO_DISPLAY_MEDIUM_WIDGET
        let cellHeight = context.displaySize.height / CGFloat(count)
        return FolderTimelineEntry(date: Date(), clips: mockClips, cellHeight: cellHeight)
    }

    func getSnapshot(for configuration: SelectFolderIntent, in context: Context, completion: @escaping (FolderTimelineEntry) -> ()) {
        if context.isPreview {
            return completion(self.placeholder(in: context))
        }
        return completion(self.generateEntry(for: configuration, in: context))
    }

    func getTimeline(for configuration: SelectFolderIntent, in context: Context, completion: @escaping (Timeline<FolderTimelineEntry>) -> ()) {
        let timeline = Timeline<FolderTimelineEntry>(entries: [self.generateEntry(for: configuration, in: context)], policy: .never)
        completion(timeline)
    }
}

struct FolderWidgetEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: FolderTimelineProvider.Entry
    
    var body: some View {
        ZStack {
            Color("WidgetBackground")
            VStack {
                ForEach(entry.clips) { clipIdentifiable in
                    Link(destination: URL(string: "copybetter:///main?action=copy&uri=\(clipIdentifiable.uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!, label: {
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
        .widgetURL(URL(string: "copybetter:///main"))
    }
}

struct FolderWidget: Widget {
    let kind: String = "com.williamwu.clips.folder-widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectFolderIntent.self, provider: FolderTimelineProvider()) { entry in
            FolderWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(AppStrings.FAVORITES_WIDGET_DISPLAY_NAME)
        .description(AppStrings.FAVORITES_WIDGET_DESCRIPTION)
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct FolderWidget_Previews: PreviewProvider {
    static var previews: some View {
        FolderWidgetEntryView(entry: FolderTimelineEntry(date: Date(), clips: [ClipIdentifiable(uri: "a", title: "AAA", contents: "aaa"), ClipIdentifiable(uri: "b", title: "BBB", contents: "bbb"), ClipIdentifiable(uri: "c", title: "CCC CCC CCC CCC CCC CCC", contents: "ccc ccc ccc ccc ccc ccc"), ClipIdentifiable(uri: "d", title: nil, contents: "qwertyuiop asdfghjkl;"), ClipIdentifiable(uri: "e", title: nil, contents: "qwertyuiop qwertyuiop qwertyuiop")], cellHeight: 31.5))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

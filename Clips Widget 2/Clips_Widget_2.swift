//
//  Clips_Widget_2.swift
//  Clips Widget 2
//
//  Created by William Wu on 9/25/20.
//  Copyright © 2020 William Wu. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [SimpleEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Clips_Widget_2EntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color("WidgetBackground")
            HStack {
                Image(systemName: "paperclip")
                    .renderingMode(.template)
                    .foregroundColor(Color("AccentColor"))
                    .font(.system(size: 100, weight: .light))
                Image(systemName: "plus.circle.fill")
                    .renderingMode(.template)
                    .foregroundColor(Color(.systemGray2))
                    .font(.system(size: 25))
                    .padding(EdgeInsets(top: 0, leading: -5, bottom: 70, trailing: 0))
            }
        }
        .widgetURL(URL(string: "copybetter:///main?action=addcopied"))
    }
}

struct Clips_Widget_2: Widget {
    let kind: String = "com.williamwu.clips.add-copied-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Clips_Widget_2EntryView(entry: entry)
        }
        .configurationDisplayName(AppStrings.WIDGET_DISPLAY_NAME)
        .description(AppStrings.WIDGET_DESCRIPTION)
        .supportedFamilies([.systemSmall])
    }
}

struct Clips_Widget_2_Previews: PreviewProvider {
    static var previews: some View {
        Clips_Widget_2EntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

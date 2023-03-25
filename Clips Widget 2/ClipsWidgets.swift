//
//  ClipsWidgets.swift
//  Clips Widget 2Extension
//
//  Created by William Wu on 9/7/21.
//  Copyright © 2021 William Wu. All rights reserved.
//

import SwiftUI

@main
struct ClipsWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        Clips_Widget_2()
        FavoritesWidget()
        FolderWidget()
    }
}

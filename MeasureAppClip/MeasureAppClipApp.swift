//
//  MeasureAppClipApp.swift
//  MeasureAppClip
//
//  Created by Ploggvn on 15/1/26.
//  Copyright © 2026 levantAJ. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct MeasureAppClipApp: App {
    var body: some Scene {
            WindowGroup {
                // Gọi giao diện cầu nối
                MeasureView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
}

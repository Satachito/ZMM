//
//  ZMMApp.swift
//  ZMM
//
//  Created by 小倉哲 on 2024/10/06.
//

import SwiftUI

@main
struct ZMMApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ZMMDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}

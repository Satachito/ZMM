//
//  ContentView.swift
//  ZMM
//
//  Created by 小倉哲 on 2024/10/06.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ZMMDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(ZMMDocument()))
}

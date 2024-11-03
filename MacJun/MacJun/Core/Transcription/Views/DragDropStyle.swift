//
//  DragDropStyle.swift
//  Jun
//
//  Created by Jiacheng Mao on 2024/11/3.
//

import SwiftUI

struct DragDropStyle: ViewModifier {
    let isTargeted: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTargeted ? Color.accentColor : Color.gray, style: StrokeStyle(lineWidth: 2, dash: [6]))
            )
            .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}

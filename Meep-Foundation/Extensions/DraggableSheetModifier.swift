//
//  DraggableSheetModifier.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/1/25.
//

import SwiftUI

struct DraggableSheet: ViewModifier {
    // Two bindings: one for the current offset and one for the last offset.
    @Binding var offset: CGFloat
    @Binding var lastOffset: CGFloat
    let minOffset: CGFloat
    let midOffset: CGFloat
    let maxOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newOffset = lastOffset + value.translation.height
                        if newOffset >= minOffset && newOffset <= maxOffset {
                            offset = newOffset
                        }
                    }
                    .onEnded { value in
                        let dragAmount = value.translation.height
                        let threshold = UIScreen.main.bounds.height * 0.15  // Sensitivity threshold

                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 1)) {
                            if dragAmount < -threshold {
                                // Dragging up
                                if offset <= midOffset {
                                    offset = minOffset
                                } else {
                                    offset = midOffset
                                }
                            } else if dragAmount > threshold {
                                // Dragging down
                                if offset >= midOffset {
                                    offset = maxOffset
                                } else {
                                    offset = midOffset
                                }
                            } else {
                                // Snap to the nearest point based on distance
                                let distanceToMid = abs(offset - midOffset)
                                let distanceToMin = abs(offset - minOffset)
                                let distanceToMax = abs(offset - maxOffset)
                                
                                if distanceToMid < distanceToMin && distanceToMid < distanceToMax {
                                    offset = midOffset
                                } else if distanceToMin < distanceToMax {
                                    offset = minOffset
                                } else {
                                    offset = maxOffset
                                }
                            }
                        }
                        // Debounce: update the last offset after a slight delay for smoothness.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            lastOffset = offset
                        }
                    }
            )
    }
}

extension View {
    func draggableSheet(offset: Binding<CGFloat>,
                        lastOffset: Binding<CGFloat>,
                        minOffset: CGFloat,
                        midOffset: CGFloat,
                        maxOffset: CGFloat) -> some View {
        self.modifier(DraggableSheet(offset: offset,
                                     lastOffset: lastOffset,
                                     minOffset: minOffset,
                                     midOffset: midOffset,
                                     maxOffset: maxOffset))
    }
}

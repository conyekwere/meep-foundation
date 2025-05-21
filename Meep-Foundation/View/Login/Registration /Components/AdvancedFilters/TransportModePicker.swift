//
//  TransportModePicker.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/17/25.
//
import SwiftUI

struct TransportModePicker: View {
    let title: String
    @Binding var selectedMode: TransportMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.regular)
                .fontWidth(.expanded)
                .padding(.bottom,16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(TransportMode.allCases) { mode in
                        Button(action: {
                            selectedMode = mode
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: mode.systemImageName)
                                    .font(.body)
                            }
                            .frame(minWidth: 50, maxWidth: 100)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(selectedMode == mode ? Color.gray.opacity(0.1) : Color.white)
                            .foregroundColor(selectedMode == mode ? Color(.label) : .black)
                            .fontWeight(selectedMode == mode ? .medium : .regular)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .scrollClipDisabled(true)
        }
    }
}

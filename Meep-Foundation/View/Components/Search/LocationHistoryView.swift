//
//  LocationHistoryView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/22/25.
//

import SwiftUI

struct LocationHistoryView: View {
    let histories: [String]
    let onSelectLocation: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !histories.isEmpty {
                Text("Recent Locations")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                ForEach(histories, id: \.self) { address in
                    Button(action: {
                        onSelectLocation(address)
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: "E8F0FE"))
                                .clipShape(Circle())
                            
                            Text(address)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

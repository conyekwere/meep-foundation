//
//  MeepAnnotation+View.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/1/25.
//

import SwiftUI

extension MeepAnnotation {
    var annotationView: some View {
        VStack {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(type == .place ? .red : .blue)
            Text(title)
                .font(.caption)
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(5)
        }
    }
}

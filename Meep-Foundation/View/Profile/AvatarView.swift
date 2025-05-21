//
//  AvatarView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/16/25.
//


//
//  AvatarView.swift
//  syce-foundation
//
//  Created by Chima onyekwere on 5/16/24.
//

import SwiftUI
import Kingfisher

struct AvatarView: View {
    let user: MeepUser
    let size:AvatarSize
    var body: some View {
        if !user.profileImageUrl.isEmpty {
            let imageUrl = user.profileImageUrl
            KFImage(URL(string: imageUrl))
                .placeholder {
                    ProgressView()
                        .frame(width: size.dimension, height: size.dimension)
                }
                .resizable()
                .scaledToFill()
                .frame(width:size.dimension,height: size.dimension)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width:size.dimension,height: size.dimension)
                .clipShape(Circle())
                .foregroundStyle(Color(.systemGray4))
        }
    }
}

#Preview{
    VStack{
        AvatarView(user: DeveloperPreview.meepUser,size: .xLarge)
        AvatarView(user: DeveloperPreview.meepUser,size: .large)
        AvatarView(user: DeveloperPreview.meepUser,size: .medium)
        AvatarView(user: DeveloperPreview.meepUser,size: .small)
        AvatarView(user: DeveloperPreview.meepUser,size: .xSmall)
        AvatarView(user: DeveloperPreview.meepUser,size: .xxSmall)
    }
}

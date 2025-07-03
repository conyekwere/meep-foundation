//
//  BlockUsersListView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/3/25.
//

import SwiftUI

struct BlockUsersListView: View {
    let blockedUsers: [MeepUser]
    let onUnblock: (MeepUser) -> Void
    
    var body: some View {
        List {
            ForEach(blockedUsers, id: \.id) { user in
                BlockUserRow(user: user) {
                    onUnblock(user)
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

#Preview {
    let mockUsers = [
        MeepUser(id: "1", displayName: "Vasquez Rodriguez", username: "vasquez_r", profileImageUrl: "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "2", displayName: "Kyra Mora", username: "kyra_mora", profileImageUrl: "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "3", displayName: "Ryan Dires", username: "ryan_dires", profileImageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "4", displayName: "Sammy Rhea", username: "sammyrhea", profileImageUrl: "https://images.pexels.com/photos/3778876/pexels-photo-3778876.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "5", displayName: "James Brimstone", username: "j_brimstone", profileImageUrl: "https://images.pexels.com/photos/4029925/pexels-photo-4029925.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "6", displayName: "John Armando", username: "johnarmando", profileImageUrl: "https://images.pexels.com/photos/13767165/pexels-photo-13767165.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "7", displayName: "Amy Ko", username: "amyko", profileImageUrl: "https://images.pexels.com/photos/5490276/pexels-photo-5490276.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "8", displayName: "Sarah Johnson", username: "sarah_j", profileImageUrl: "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "9", displayName: "Mike Chen", username: "mikechen", profileImageUrl: "https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "10", displayName: "Lisa Park", username: "lisapark", profileImageUrl: "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2")
    ]
    
    BlockUsersListView(blockedUsers: mockUsers) { user in
        print("Unblocking \(user.displayName)")
    }
}

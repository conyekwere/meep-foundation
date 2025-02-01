//
//  SearchBarWithAction.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/23/25.
//


import SwiftUI

struct SearchBarWithAction: View {
    let title: String
    let subtitle: String
    let leadingIcon: String
    let trailingIcon: String
    let isDirty: Bool
    let onLeadingIconTap: () -> Void
    let onTrailingIconTap: () -> Void
    let onContainerTap: () -> Void

    var body: some View {
        Button(action: {
            onContainerTap()
        }) {
            HStack {
                // Leading Icon
                Button(action: {
                    onLeadingIconTap()
                }) {
                    Image(systemName: leadingIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(11)
                        .font(.system(size: 16))
                        .frame(width: 40, height: 40, alignment: .center)
                        .foregroundColor(Color(.gray))
                }

                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout)
                        .fontWidth(.expanded)
                        .fontWeight(.medium)
                        .foregroundColor(Color(.darkGray))
                    Text(subtitle)
                        .font(.footnote)
                        .fontWidth(.expanded)
                        .foregroundColor(Color(.gray))
                }

                Spacer()

                // Trailing Icon
                Button(action: {
                    onTrailingIconTap()
                }) {
                    if isDirty {
                        Image(systemName: trailingIcon)
                            .foregroundColor(Color(.gray))
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                            .rotationEffect(.degrees(-90))
                       
                    }
                    else{
                        AsyncImage(url: URL(string: trailingIcon)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        
                    }
                }
            }

        }
    }
}


#Preview {
    SearchBarWithAction(
        title: "35 Meeting Points",
        subtitle: "777 Broadway · 210 E 121st St",
        leadingIcon: "chevron.left",
        trailingIcon: "slider.horizontal.3",
        isDirty: true,
        onLeadingIconTap: {
            print("Back button tapped")
        },
        onTrailingIconTap: {
            print("Filters tapped")
        },
        onContainerTap: {
            print("Edit Search Bar tapped")
        }
    )

    SearchBarWithAction(
        title: "Find where to meet",
        subtitle: "My Location · Friends location",
        leadingIcon: "magnifyingglass",
        trailingIcon:"https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
        isDirty: false,
        onLeadingIconTap: {
            print("Search button tapped")
        },
        onTrailingIconTap: {
            print("User profile tapped")
        },
        onContainerTap: {
            print("Entire Search bar tapped")
        }
    )
}

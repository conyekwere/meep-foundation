//
//  LocationPermissionView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/16/25.
//

import SwiftUI

struct LocationPermissionView: View {
    let onContinue: () -> Void
    var profileImageUrl: String = "" // default fallback
    var fullName: String
    var body: some View {
        ZStack {
            


            VStack(spacing: 8) {
                Spacer()

                HStack(spacing:-8) {
                    
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: 150, height: 180)
                  
                        .overlay {
                            AsyncImage(url: URL(string: profileImageUrl)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .scaledToFill()
                                        .frame(width: 150, height: 180)
                                } else {
                                    Image("grass")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .scaledToFill()
                                        .frame(width: 150, height: 180)
                                    
                                    ZStack {
                                        
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill( Color(#colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1))
                                            .opacity(0.7))
                                            .frame(width: 150, height: 180)
                                        
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(#colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)),
                                                        Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 90, height: 90)

                                    }
                                    .overlay(
                                        Text(String(fullName.prefix(1)))
                                            .font(.system(size: 44))
                                            .fontWeight(.semibold)
                                            .fontWidth(.expanded)
                                            .foregroundColor(.white)
                                    )
                                }
                            }
                        }
                        .cornerRadius(16)
                        .rotationEffect(.degrees(-9))
                        .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.30000001192092896)), radius:1.8686153888702393, x:0, y:0.6228718161582947)
                        .zIndex(1)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .frame(width: 140, height: 180)
                            .overlay {
                                ZStack {
                                    Image("grass")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .scaledToFill()
                                        .frame(width: 150, height: 180)
                                    VisualEffectBlur(blurStyle: .light)
                                        .edgesIgnoringSafeArea(.all)
                                        .opacity(0.5)
                                }
                                .cornerRadius(16)
                            }
                        
                        Image("meep-mascot")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                    }
                    .rotationEffect(.degrees(9))
                    .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.30000001192092896)), radius:1.8686153888702393, x:0, y:0.6228718161582947)
               
                    
                    
                }

                Text("Enable Location")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontWidth(.expanded)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineSpacing(16)
                    .padding(.top, 32)
                

                
                Text("You‘ll need to enable your location in order to use Meep")
                    .font(.title3)
                    .foregroundColor(.white).opacity(0.8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()

                Button(action: onContinue) {
                    Text("Allow Location")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(40)
                        .padding(.horizontal)
                    
                }
                .padding(.bottom,32)

                
            }


        }
    }
}

#Preview {
    LocationPermissionView(onContinue: {}, profileImageUrl: "https://example.com/photo.jpg",fullName: "Chima")
}

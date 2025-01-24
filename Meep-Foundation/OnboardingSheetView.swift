//
//  OnboardingSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI

struct OnboardingSheetView: View {
    @ObservedObject var viewModel: MeepViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var isLocationAllowed: Bool


    var body: some View {
        ZStack{
            VisualEffectBlur(blurStyle: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
                .cornerRadius(16)
                .ignoresSafeArea(edges: .bottom)
            
            VStack(spacing: 16) {
                // Drag Handle
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(Color(.lightGray).opacity(0.4))
                
                
                ScrollView {
                    VStack(spacing:24) {
                        VStack{
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "67DB92"),Color(hex: "41AC99")]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                
                                VStack(spacing:8) {
                                    
                                    ZStack {
                                        Circle()
                                            .fill(Color(#colorLiteral(red: 0.3455161154270172, green: 0.5001650452613831, blue: 0.9254494905471802, alpha: 1)))
                                            .strokeBorder(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), lineWidth: 1)
                                            .frame(width: 16, height: 16)
                                            .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.30000001192092896)), radius:2.1352040767669678, x:0, y:0.7117347121238708)
                                        
                                        Circle()
                                            .strokeBorder(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), lineWidth: 1)
                                            .frame(width: 60, height: 60)
                                        
                                        Circle()
                                            .strokeBorder(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), lineWidth: 1)
                                            .frame(width: 108, height: 108)
                                        
                                    }
                                    .padding(.bottom, 16)
                                    
                                    Text("Allow location")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .fontWidth(.expanded)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .textCase(.uppercase)
                                        .lineSpacing(14)
                                        .minimumScaleFactor(0.9)
                                    
                                    
                                    Text("Allow location to get from A to B")
                                        .font(.title3)
                                        .foregroundColor(Color(.white))
                                        .padding(.bottom, 24)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.9)
                                    Button(action: {
                                        
                                        viewModel.requestUserLocation()
                                        withAnimation {
                                        }
                                    }) {
                                        Text("Allow")
                                            .font(.title3)
                                            .foregroundColor(Color(.darkGray))
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color(.white))
                                            .cornerRadius(10)
                                    }
                                    .frame(height:44)
                                }
                                .padding(24)
                                
                                
                            }
                            
                        }
                        .frame(height: 360)
                        .cornerRadius(12)
                        .padding(.horizontal,16)
                        
                        VStack() {
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "145492"),Color(hex: "3D9FF5")]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                
                                VStack(spacing:16) {
                                    
                                    ZStack {
                                        Image(systemName: "mappin.circle")
                                            .resizable()
                                            .frame(width: 34, height: 34)
                                            .foregroundStyle(Color.white)
                                        
                                        Circle()
                                            .strokeBorder(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)).opacity(0.5),  style: StrokeStyle(lineWidth: 3, dash: [4,4]))
                                            .frame(width: 74, height: 74)
                                        
                                        Circle()
                                            .strokeBorder(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)).opacity(0.5), lineWidth: 2)
                                            .frame(width: 108, height: 108)
                                        
                                    }
                                    .padding(.bottom, 8)
                                    
                                    
                                    Text("Meet Your Friends Halfway")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .fontWidth(.expanded)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .textCase(.uppercase)
                                        .lineSpacing(14)
                                        .minimumScaleFactor(0.9)
                                    
                                    
                                    Text("Search the Perfect Meeting Point")
                                        .font(.title3)
                                        .foregroundColor(Color(.white))
                                        .padding(.bottom, 10)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.9)
                                    Button(action: {
                                        // Simulate search action
                                        withAnimation {
                                            
                                        }
                                    }) {
                                        Text("Search")
                                            .font(.title3)
                                            .foregroundColor(Color(.darkGray))
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color(.white))
                                            .cornerRadius(10)
                                    }
                                    .frame(height:44)
                                    .padding(.top, 8)
                                    .padding(.bottom, 16)
                                }
                                .padding(24)
                                
                                
                                
                            }
                            
                        }
                        .frame(height: 390)
                        .cornerRadius(12)
                        .padding(.horizontal,16)
                    }
                }
                
            }
            .padding(.top, 8)
            .padding(.bottom, 32)

            .cornerRadius(16)
            .ignoresSafeArea(edges: .bottom)
            

        }
        
    }
}


#Preview {
    OnboardingSheetView(viewModel: MeepViewModel(), isLocationAllowed:  .constant(false)) // Replace MeepViewModel() with your mock data
                .previewLayout(.sizeThatFits) // Ensures the bottom sheet view fits the preview size
                .background(Color.gray.opacity(0.2)) // Optional background to visualize contrast
}

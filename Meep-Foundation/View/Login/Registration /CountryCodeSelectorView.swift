//
//  CountryCodeSelectorView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//


import SwiftUI

struct CountryCodeSelectorView: View {
    @Binding var selectedCountry: Country 
    @Environment(\.presentationMode) var presentationMode

    @State private var searchText: String = "" // Search query

    // List of countries and their country codes
    let allCountries: [Country] = [
        Country(name: "United States", code: "+1", flag: "🇺🇸", maxLength: 10),
        Country(name: "Canada", code: "+1", flag: "🇨🇦", maxLength: 10),
        Country(name: "United Kingdom", code: "+44", flag: "🇬🇧", maxLength: 10),
        Country(name: "Australia", code: "+61", flag: "🇦🇺", maxLength: 9),
        Country(name: "Germany", code: "+49", flag: "🇩🇪", maxLength: 11),
        Country(name: "France", code: "+33", flag: "🇫🇷", maxLength: 9),
        Country(name: "Spain", code: "+34", flag: "🇪🇸", maxLength: 9),
        Country(name: "Italy", code: "+39", flag: "🇮🇹", maxLength: 10),
        Country(name: "Japan", code: "+81", flag: "🇯🇵", maxLength: 10),
        Country(name: "China", code: "+86", flag: "🇨🇳", maxLength: 11),
        Country(name: "India", code: "+91", flag: "🇮🇳", maxLength: 10),
        Country(name: "Brazil", code: "+55", flag: "🇧🇷", maxLength: 11),
        Country(name: "Mexico", code: "+52", flag: "🇲🇽", maxLength: 10),
        Country(name: "South Korea", code: "+82", flag: "🇰🇷", maxLength: 10),
        Country(name: "Russia", code: "+7", flag: "🇷🇺", maxLength: 10)
    ]
    
    // Filtered countries based on search text
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return allCountries
        } else {
            return allCountries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                TextField("Search countries", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)

                // Country List
                List(filteredCountries, id: \.code) { country in
                    HStack {
                        Text(country.flag) // Flag
                            .font(.largeTitle)

                        VStack(alignment: .leading) {
                            Text(country.name) // Country name
                                .font(.headline)
                            Text(country.code) // Country code
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Update selected country code and dismiss
                        selectedCountry = country 
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .listStyle(.plain) // Clean list style
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                            .frame(width: 40, height: 40, alignment: .center)
                            .background(Color(.lightGray).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.primary)
                }
            }
        }
    }
}
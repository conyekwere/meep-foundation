//
//  Country.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//


import Foundation

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
    let maxLength: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Country, rhs: Country) -> Bool {
        return lhs.id == rhs.id
    }
}

class CountryData {
    static let allCountries: [Country] = [
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
        Country(name: "Netherlands", code: "+31", flag: "🇳🇱", maxLength: 9),
        Country(name: "Switzerland", code: "+41", flag: "🇨🇭", maxLength: 9),
        Country(name: "South Korea", code: "+82", flag: "🇰🇷", maxLength: 10),
        Country(name: "Singapore", code: "+65", flag: "🇸🇬", maxLength: 8),
        Country(name: "Sweden", code: "+46", flag: "🇸🇪", maxLength: 9),
        Country(name: "Norway", code: "+47", flag: "🇳🇴", maxLength: 8),
        Country(name: "Denmark", code: "+45", flag: "🇩🇰", maxLength: 8),
        Country(name: "Finland", code: "+358", flag: "🇫🇮", maxLength: 9),
        Country(name: "Belgium", code: "+32", flag: "🇧🇪", maxLength: 9),
        Country(name: "New Zealand", code: "+64", flag: "🇳🇿", maxLength: 9),
        Country(name: "Ireland", code: "+353", flag: "🇮🇪", maxLength: 9),
        Country(name: "Austria", code: "+43", flag: "🇦🇹", maxLength: 10),
        Country(name: "Portugal", code: "+351", flag: "🇵🇹", maxLength: 9),
        Country(name: "Greece", code: "+30", flag: "🇬🇷", maxLength: 10),
        Country(name: "Israel", code: "+972", flag: "🇮🇱", maxLength: 9),
        Country(name: "United Arab Emirates", code: "+971", flag: "🇦🇪", maxLength: 9),
        Country(name: "Russia", code: "+7", flag: "🇷🇺", maxLength: 10),
        Country(name: "Turkey", code: "+90", flag: "🇹🇷", maxLength: 10),
        Country(name: "Poland", code: "+48", flag: "🇵🇱", maxLength: 9),
        Country(name: "South Africa", code: "+27", flag: "🇿🇦", maxLength: 9),
        Country(name: "Argentina", code: "+54", flag: "🇦🇷", maxLength: 10),
        Country(name: "Chile", code: "+56", flag: "🇨🇱", maxLength: 9),
        Country(name: "Colombia", code: "+57", flag: "🇨🇴", maxLength: 10),
        Country(name: "Peru", code: "+51", flag: "🇵🇪", maxLength: 9),
        Country(name: "Saudi Arabia", code: "+966", flag: "🇸🇦", maxLength: 9),
        Country(name: "Malaysia", code: "+60", flag: "🇲🇾", maxLength: 9),
        Country(name: "Indonesia", code: "+62", flag: "🇮🇩", maxLength: 10)
    ]
    
    // Function to get a country by code
    static func getCountry(byCode code: String) -> Country? {
        return allCountries.first { $0.code == code }
    }
    
    // Function to get a country by name
    static func getCountry(byName name: String) -> Country? {
        return allCountries.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // Get the default country (usually United States)
    static func getDefaultCountry() -> Country {
        return allCountries.first { $0.code == "+1" && $0.name == "United States" } ?? allCountries[0]
    }
}
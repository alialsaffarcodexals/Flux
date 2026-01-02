//
//  HomeViewModel.swift
//  Flux
//

import UIKit

// MARK: - Company Model (for Recommended - NO star)
struct Company {
    var name: String
    var description: String
    var backgroundColor: UIColor
    var category: String
    var price: Double
    var rating: Double
    var iconName: String
}

// MARK: - Service Model (for Services - WITH star)
struct ServiceItem {
    var id: String
    var name: String
    var providerName: String
    var category: String
    var price: Double
    var rating: Double
    var iconName: String
    var backgroundColor: UIColor
    var isFavorite: Bool
}

// MARK: - Filter Options Model
struct FilterOptions {
    var maxPrice: Double = 200
    var minRating: Double = 0
    var selectedCategory: String? = nil
    var sortBy: SortOption = .relevance
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case rating = "Highest Rated"
        case newest = "Newest First"
    }
}

// MARK: - Home View Model
class HomeViewModel {
    
    private var allCompanies: [Company] = []
    private var allServices: [ServiceItem] = []
    
    var recommendedCompanies: [Company] = []
    var services: [ServiceItem] = []
    var categories: [String] = []
    
    func loadDummyData() {
        loadCategories()
        loadCompanies()
        loadServices()
    }
    
    private func loadCategories() {
        categories = [
            "All", "Cleaning", "Repairs", "Beauty", "Tutoring", "Fitness",
            "Tech", "Photo", "Music", "Cooking", "Driving", "Pets",
            "Health", "Legal", "Finance", "Events", "Moving", "Security"
        ]
    }
    
    private func loadCompanies() {
        allCompanies = [
            Company(name: "CleanMax", description: "Home Cleaning Service", backgroundColor: .systemGreen, category: "Cleaning", price: 50.0, rating: 4.8, iconName: "sparkles"),
            Company(name: "FixIt Pro", description: "Home Repairs & Maintenance", backgroundColor: .systemOrange, category: "Repairs", price: 75.0, rating: 4.6, iconName: "wrench.and.screwdriver"),
            Company(name: "GreenThumb", description: "Garden & Landscaping", backgroundColor: .systemGreen.withAlphaComponent(0.7), category: "Cleaning", price: 60.0, rating: 4.9, iconName: "leaf"),
            Company(name: "GlamSquad", description: "Beauty & Makeup", backgroundColor: .systemPink, category: "Beauty", price: 80.0, rating: 4.7, iconName: "scissors"),
            Company(name: "TechGenius", description: "IT Support & Repairs", backgroundColor: .systemBlue, category: "Tech", price: 90.0, rating: 4.5, iconName: "desktopcomputer"),
            Company(name: "FitLife", description: "Personal Training", backgroundColor: .systemRed, category: "Fitness", price: 45.0, rating: 4.9, iconName: "figure.run"),
            Company(name: "TutorPro", description: "Academic Tutoring", backgroundColor: .systemPurple, category: "Tutoring", price: 35.0, rating: 5.0, iconName: "book"),
            Company(name: "PetCare", description: "Pet Services", backgroundColor: .systemBrown, category: "Pets", price: 30.0, rating: 4.8, iconName: "pawprint")
        ]
        recommendedCompanies = allCompanies
    }
    
    private func loadServices() {
        allServices = [
            // Cleaning
            ServiceItem(id: "1", name: "Deep Home Cleaning", providerName: "CleanMax", category: "Cleaning", price: 50.0, rating: 4.8, iconName: "sparkles", backgroundColor: .systemGreen, isFavorite: false),
            ServiceItem(id: "2", name: "Office Cleaning", providerName: "SparkleTeam", category: "Cleaning", price: 75.0, rating: 4.6, iconName: "building.2", backgroundColor: .systemTeal, isFavorite: true),
            ServiceItem(id: "3", name: "Car Wash & Detail", providerName: "AutoShine", category: "Cleaning", price: 35.0, rating: 4.7, iconName: "car", backgroundColor: .systemBlue, isFavorite: false),
            ServiceItem(id: "4", name: "Window Cleaning", providerName: "ClearView", category: "Cleaning", price: 40.0, rating: 4.5, iconName: "square.split.2x2", backgroundColor: .systemCyan, isFavorite: false),
            
            // Repairs
            ServiceItem(id: "5", name: "Plumbing Repair", providerName: "FixIt Pro", category: "Repairs", price: 80.0, rating: 4.5, iconName: "wrench", backgroundColor: .systemOrange, isFavorite: false),
            ServiceItem(id: "6", name: "Electrical Work", providerName: "PowerFix", category: "Repairs", price: 90.0, rating: 4.8, iconName: "bolt", backgroundColor: .systemYellow, isFavorite: true),
            ServiceItem(id: "7", name: "AC Maintenance", providerName: "CoolAir", category: "Repairs", price: 60.0, rating: 4.4, iconName: "snowflake", backgroundColor: .systemCyan, isFavorite: false),
            ServiceItem(id: "8", name: "Appliance Repair", providerName: "QuickFix", category: "Repairs", price: 55.0, rating: 4.6, iconName: "gearshape", backgroundColor: .systemGray, isFavorite: false),
            
            // Beauty
            ServiceItem(id: "9", name: "Haircut & Styling", providerName: "GlamSquad", category: "Beauty", price: 40.0, rating: 4.9, iconName: "scissors", backgroundColor: .systemPink, isFavorite: true),
            ServiceItem(id: "10", name: "Makeup Artist", providerName: "BeautyPro", category: "Beauty", price: 70.0, rating: 4.7, iconName: "paintbrush", backgroundColor: .systemPurple, isFavorite: false),
            ServiceItem(id: "11", name: "Nail Art", providerName: "NailBar", category: "Beauty", price: 30.0, rating: 4.6, iconName: "hand.raised", backgroundColor: .systemRed, isFavorite: false),
            ServiceItem(id: "12", name: "Spa & Massage", providerName: "RelaxZone", category: "Beauty", price: 85.0, rating: 4.8, iconName: "leaf", backgroundColor: .systemMint, isFavorite: true),
            
            // Tutoring
            ServiceItem(id: "13", name: "Math Tutoring", providerName: "TutorPro", category: "Tutoring", price: 25.0, rating: 5.0, iconName: "function", backgroundColor: .systemIndigo, isFavorite: false),
            ServiceItem(id: "14", name: "English Lessons", providerName: "LinguaLearn", category: "Tutoring", price: 30.0, rating: 4.8, iconName: "textformat", backgroundColor: .systemBrown, isFavorite: true),
            ServiceItem(id: "15", name: "Science Tutor", providerName: "ScienceHub", category: "Tutoring", price: 35.0, rating: 4.7, iconName: "atom", backgroundColor: .systemGreen, isFavorite: false),
            ServiceItem(id: "16", name: "Arabic Lessons", providerName: "ArabicPro", category: "Tutoring", price: 28.0, rating: 4.9, iconName: "book", backgroundColor: .systemTeal, isFavorite: false),
            
            // Fitness
            ServiceItem(id: "17", name: "Personal Training", providerName: "FitLife", category: "Fitness", price: 45.0, rating: 4.9, iconName: "dumbbell", backgroundColor: .systemRed, isFavorite: true),
            ServiceItem(id: "18", name: "Yoga Classes", providerName: "ZenYoga", category: "Fitness", price: 30.0, rating: 4.8, iconName: "figure.mind.and.body", backgroundColor: .systemMint, isFavorite: false),
            ServiceItem(id: "19", name: "Swimming Coach", providerName: "AquaFit", category: "Fitness", price: 50.0, rating: 4.6, iconName: "drop", backgroundColor: .systemBlue, isFavorite: false),
            ServiceItem(id: "20", name: "Boxing Training", providerName: "FightClub", category: "Fitness", price: 40.0, rating: 4.7, iconName: "figure.boxing", backgroundColor: .systemOrange, isFavorite: false),
            
            // Tech
            ServiceItem(id: "21", name: "Phone Repair", providerName: "TechGenius", category: "Tech", price: 60.0, rating: 4.5, iconName: "iphone", backgroundColor: .systemGray, isFavorite: false),
            ServiceItem(id: "22", name: "Laptop Repair", providerName: "PCDoctor", category: "Tech", price: 80.0, rating: 4.7, iconName: "laptopcomputer", backgroundColor: .systemBlue, isFavorite: true),
            ServiceItem(id: "23", name: "Smart Home Setup", providerName: "HomeAuto", category: "Tech", price: 100.0, rating: 4.4, iconName: "house", backgroundColor: .systemPurple, isFavorite: false),
            ServiceItem(id: "24", name: "Website Design", providerName: "WebPro", category: "Tech", price: 150.0, rating: 4.8, iconName: "globe", backgroundColor: .systemIndigo, isFavorite: false),
            
            // Photo
            ServiceItem(id: "25", name: "Event Photography", providerName: "PhotoStudio", category: "Photo", price: 150.0, rating: 4.9, iconName: "camera", backgroundColor: .systemPink, isFavorite: true),
            ServiceItem(id: "26", name: "Portrait Session", providerName: "SnapPro", category: "Photo", price: 80.0, rating: 4.7, iconName: "person", backgroundColor: .systemPurple, isFavorite: false),
            ServiceItem(id: "27", name: "Product Photos", providerName: "CommercialPix", category: "Photo", price: 120.0, rating: 4.6, iconName: "cube", backgroundColor: .systemOrange, isFavorite: false),
            
            // Music
            ServiceItem(id: "28", name: "Piano Lessons", providerName: "MusicMentor", category: "Music", price: 40.0, rating: 4.8, iconName: "pianokeys", backgroundColor: .systemYellow, isFavorite: false),
            ServiceItem(id: "29", name: "Guitar Lessons", providerName: "StringMaster", category: "Music", price: 35.0, rating: 4.6, iconName: "guitars", backgroundColor: .systemBrown, isFavorite: true),
            ServiceItem(id: "30", name: "Vocal Training", providerName: "VoicePro", category: "Music", price: 45.0, rating: 4.7, iconName: "music.mic", backgroundColor: .systemRed, isFavorite: false),
            
            // Cooking
            ServiceItem(id: "31", name: "Private Chef", providerName: "ChefAtHome", category: "Cooking", price: 120.0, rating: 4.9, iconName: "fork.knife", backgroundColor: .systemRed, isFavorite: false),
            ServiceItem(id: "32", name: "Cooking Classes", providerName: "CookSchool", category: "Cooking", price: 50.0, rating: 4.7, iconName: "flame", backgroundColor: .systemOrange, isFavorite: false),
            
            // Pets
            ServiceItem(id: "33", name: "Dog Walking", providerName: "PetPals", category: "Pets", price: 20.0, rating: 4.8, iconName: "dog", backgroundColor: .systemBrown, isFavorite: true),
            ServiceItem(id: "34", name: "Pet Grooming", providerName: "FurryFresh", category: "Pets", price: 45.0, rating: 4.6, iconName: "pawprint", backgroundColor: .systemGreen, isFavorite: false),
            
            // Driving
            ServiceItem(id: "35", name: "Driving Lessons", providerName: "DriveRight", category: "Driving", price: 40.0, rating: 4.5, iconName: "car", backgroundColor: .systemBlue, isFavorite: false),
            
            // Health
            ServiceItem(id: "36", name: "Home Nurse", providerName: "CarePlus", category: "Health", price: 100.0, rating: 4.9, iconName: "cross.case", backgroundColor: .systemRed, isFavorite: true),
            ServiceItem(id: "37", name: "Physiotherapy", providerName: "PhysioHome", category: "Health", price: 70.0, rating: 4.7, iconName: "figure.walk", backgroundColor: .systemBlue, isFavorite: false),
            
            // Events
            ServiceItem(id: "38", name: "Event Planning", providerName: "PartyPro", category: "Events", price: 200.0, rating: 4.8, iconName: "party.popper", backgroundColor: .systemPink, isFavorite: false),
            
            // Moving
            ServiceItem(id: "39", name: "Home Moving", providerName: "QuickMove", category: "Moving", price: 180.0, rating: 4.5, iconName: "shippingbox", backgroundColor: .systemBrown, isFavorite: false),
        ]
        services = allServices
    }
    
    func toggleFavorite(at index: Int) {
        guard index < services.count else { return }
        services[index].isFavorite.toggle()
        if let originalIndex = allServices.firstIndex(where: { $0.id == services[index].id }) {
            allServices[originalIndex].isFavorite = services[index].isFavorite
        }
    }
    
    func applyFilters(_ filters: FilterOptions) {
        var filtered = allServices
        
        if let category = filters.selectedCategory, category != "All" {
            filtered = filtered.filter { $0.category == category }
        }
        
        filtered = filtered.filter { $0.price <= filters.maxPrice }
        
        if filters.minRating > 0 {
            filtered = filtered.filter { $0.rating >= filters.minRating }
        }
        
        switch filters.sortBy {
        case .relevance: break
        case .priceLowToHigh: filtered.sort { $0.price < $1.price }
        case .priceHighToLow: filtered.sort { $0.price > $1.price }
        case .rating: filtered.sort { $0.rating > $1.rating }
        case .newest: break
        }
        
        services = filtered
    }
    
    func filterByCategory(_ category: String?) {
        if let category = category, category != "All" {
            services = allServices.filter { $0.category == category }
        } else {
            services = allServices
        }
    }
}

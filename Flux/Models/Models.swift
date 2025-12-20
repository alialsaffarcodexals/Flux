//
//  Models.swift
//  Flux
//
//  Created by Mohammed Alnooh on 20/12/2025.
//
import Foundation
import FirebaseFirestore

// MARK: - 1. User Model
struct AppUser: Codable {
    @DocumentID var id: String? // Automatically maps the document ID
    let uid: String
    let name: String
    let email: String
    let mobileNumber: String
    let role: String            // "Provider", "Seeker", "Admin"
    let currentMode: String     // "Provider" or "Seeker"
    let isProvider: Bool
    let isApproved: Bool
    let interests: [String]?
    
    // Use @ServerTimestamp to handle Firestore dates automatically
    @ServerTimestamp var createdAt: Date?
}

// MARK: - 2. Provider Details Model (Complex)
struct ProviderDetails: Codable {
    @DocumentID var id: String? // This should match the User UID
    let workDays: [String]
    let skills: [ProviderSkill]
    let portfolio: [PortfolioItem]
}

// Nested Struct for Skills (from screenshot)
struct ProviderSkill: Codable {
    let name: String
    let description: String
    let skillLevel: String      // e.g., "Expert"
    let status: String          // e.g., "Pending"
}

// Nested Struct for Portfolio (from screenshot)
struct PortfolioItem: Codable {
    let project: String
    let description: String
    let image: String           // URL string
    let date: Date?             // Firestore Timestamp converts to Date
}

// MARK: - 3. Service Model
struct Service: Codable {
    @DocumentID var id: String?
    let uid: String             // Matches document ID usually
    let providerID: String
    let title: String
    let description: String
    let price: Double
    let coverImage: String?
}

// MARK: - 4. Request (Order) Model
struct RequestOrder: Codable {
    @DocumentID var id: String?
    let requestID: String       // Your custom ID e.g., "Req_01"
    let seekerID: String
    let providerID: String
    let serviceID: String
    let status: String          // "Pending", "Completed"
    
    let dateTime: Date?         // Appointment time
    
    // Review info (optional)
    let reviewComment: String?
    let reviewStars: Int?
    
    @ServerTimestamp var createdAt: Date?
}

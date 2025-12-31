import Foundation
import UIKit

struct Company {
    var name: String
    var description: String
    var backgroundColor: UIColor
}

class HomeViewModel {
    
    // This array holds the data for your Collection View
    var services: [Service] = []
    
    var recommendedCompanies: [Company] = []
    
    // This loads fake data so we can test the UI
    func loadDummyData() {
        
        recommendedCompanies = [
            Company(name: "CleanMax", description: "Home Cleaning Service", backgroundColor: .green),
            Company(name: "Max J.", description: "Video Editor", backgroundColor: .blue.withAlphaComponent(0.5)),
            Company(name: "Sam Altman", description: "Social Media Manager", backgroundColor: .orange)]
            
        
        
        services = [
            Service(
                id: "1",
                providerId: "user123",
                title: "Deep Home Cleaning",
                description: "Professional cleaning for 3 bedroom apartment",
                category: "Cleaning",
                sessionPrice: 50.0,
                currencyCode: "BHD",
                coverImageURL: "cleaning_image", // We will deal with images later
                rating: 4.8,
                reviewCount: 120,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Service(
                id: "2",
                providerId: "user456",
                title: "Car Oil Change",
                description: "Full synthetic oil change at your doorstep",
                category: "Automotive",
                sessionPrice: 25.0,
                currencyCode: "BHD",
                coverImageURL: "car_mechanic",
                rating: 4.5,
                reviewCount: 85,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Service(
                id: "3",
                providerId: "user789",
                title: "Math Tutoring",
                description: "High school algebra and calculus",
                category: "Education",
                sessionPrice: 15.0,
                currencyCode: "BHD",
                coverImageURL: "tutor_image",
                rating: 5.0,
                reviewCount: 40,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
}

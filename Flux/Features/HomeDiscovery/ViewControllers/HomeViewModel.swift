import Foundation

class HomeViewModel {
    
    // This array holds the data for your Collection View
    var services: [Service] = []
    
    // This loads fake data so we can test the UI
    func loadDummyData() {
        services = [
            Service(
                id: "1",
                providerId: "user123",
                title: "Deep Home Cleaning",
                description: "Professional cleaning for 3 bedroom apartment",
                category: "Cleaning",
                price: 50.0,
                pricingUnit: .session,
                coverImageURL: "cleaning_image", // We will deal with images later
                rating: 4.8,
                reviewCount: 120,
                createdAt: Date()
            ),
            Service(
                id: "2",
                providerId: "user456",
                title: "Car Oil Change",
                description: "Full synthetic oil change at your doorstep",
                category: "Automotive",
                price: 25.0,
                pricingUnit: .session,
                coverImageURL: "car_mechanic",
                rating: 4.5,
                reviewCount: 85,
                createdAt: Date()
            ),
            Service(
                id: "3",
                providerId: "user789",
                title: "Math Tutoring",
                description: "High school algebra and calculus",
                category: "Education",
                price: 15.0,
                pricingUnit: .hour,
                coverImageURL: "tutor_image",
                rating: 5.0,
                reviewCount: 40,
                createdAt: Date()
            )
        ]
    }
}

import Foundation
import FirebaseFirestore

class ServiceSeeder {
    
    static func uploadDummyData() {
        let db = Firestore.firestore()
        let collection = db.collection("services")
        
        // This is your specific User ID from the screenshots so you can edit them if needed
        let myUserID = "Tv9bE9tfUKc5q3NsDQ4ePSJZt393"
        let otherProviderID = "88n24idt58SlOC7fNQdD78dmOYC2"
        
        let services: [[String: Any]] = [
            // 1. Cleaning
            [
                "title": "Deep Apartment Cleaning",
                "description": "Full deep cleaning service including windows, floors, and sanitization for 2-bedroom apartments.",
                "category": "Cleaning",
                "sessionPrice": 35.0,
                "currencyCode": "BHD",
                "rating": 4.9,
                "reviewCount": 42,
                "isActive": true,
                "providerId": myUserID,
                "coverImageURL": "https://images.unsplash.com/photo-1581578731117-104f2a921a2b?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 2. Lessons
            [
                "title": "Private Math Tutor (Algebra)",
                "description": "One-on-one algebra and calculus tutoring for high school and university students.",
                "category": "Lessons",
                "sessionPrice": 15.0,
                "currencyCode": "BHD",
                "rating": 5.0,
                "reviewCount": 18,
                "isActive": true,
                "providerId": otherProviderID,
                "coverImageURL": "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 3. Media
            [
                "title": "Professional Portrait Photography",
                "description": "1-hour outdoor photoshoot with 10 edited high-res photos included.",
                "category": "Media",
                "sessionPrice": 50.0,
                "currencyCode": "BHD",
                "rating": 4.7,
                "reviewCount": 105,
                "isActive": true,
                "providerId": myUserID,
                "coverImageURL": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 4. Cleaning
            [
                "title": "Car Interior Detailing",
                "description": "Complete interior shampoo, leather conditioning, and vacuuming.",
                "category": "Cleaning",
                "sessionPrice": 25.0,
                "currencyCode": "BHD",
                "rating": 4.5,
                "reviewCount": 8,
                "isActive": true,
                "providerId": otherProviderID,
                "coverImageURL": "https://images.unsplash.com/photo-1601362840469-51e4d8d58785?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 5. Courses
            [
                "title": "Intro to Swift Programming",
                "description": "Learn the basics of iOS development using Swift and Xcode. Beginner friendly.",
                "category": "Courses",
                "sessionPrice": 120.0,
                "currencyCode": "BHD",
                "rating": 4.8,
                "reviewCount": 210,
                "isActive": true,
                "providerId": myUserID,
                "coverImageURL": "https://images.unsplash.com/photo-1587620962725-abab7fe55159?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 6. Media
            [
                "title": "Video Editing Service",
                "description": "Professional editing for YouTube videos, vlogs, and social media reels.",
                "category": "Media",
                "sessionPrice": 40.0,
                "currencyCode": "BHD",
                "rating": 4.6,
                "reviewCount": 33,
                "isActive": true,
                "providerId": otherProviderID,
                "coverImageURL": "https://images.unsplash.com/photo-1574717432707-c25643283f71?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 7. Cleaning
            [
                "title": "Sofa & Carpet Cleaning",
                "description": "Steam cleaning to remove stains and odors from your furniture.",
                "category": "Cleaning",
                "sessionPrice": 20.0,
                "currencyCode": "BHD",
                "rating": 4.2,
                "reviewCount": 5,
                "isActive": true,
                "providerId": myUserID,
                "coverImageURL": "https://images.unsplash.com/photo-1584622050111-993a426fbf0a?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 8. Lessons
            [
                "title": "IELTS Preparation Course",
                "description": "Intensive English preparation for the IELTS exam. Speaking and writing focus.",
                "category": "Lessons",
                "sessionPrice": 30.0,
                "currencyCode": "BHD",
                "rating": 4.9,
                "reviewCount": 55,
                "isActive": true,
                "providerId": otherProviderID,
                "coverImageURL": "https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 9. Courses
            [
                "title": "Digital Marketing Masterclass",
                "description": "Master SEO, Google Ads, and Social Media strategies.",
                "category": "Courses",
                "sessionPrice": 90.0,
                "currencyCode": "BHD",
                "rating": 4.4,
                "reviewCount": 12,
                "isActive": true,
                "providerId": myUserID,
                "coverImageURL": "https://images.unsplash.com/photo-1533750349088-cd871a92f312?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],
            // 10. Media
            [
                "title": "Logo Design & Branding",
                "description": "Custom logo creation and full brand identity package.",
                "category": "Media",
                "sessionPrice": 60.0,
                "currencyCode": "BHD",
                "rating": 5.0,
                "reviewCount": 89,
                "isActive": true,
                "providerId": otherProviderID,
                "coverImageURL": "https://images.unsplash.com/photo-1626785774573-4b7993143a2d?auto=format&fit=crop&w=400&q=80",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
        ]
        
        print("Starting Upload of 10 Services...")
        
        for (index, serviceData) in services.enumerated() {
            collection.addDocument(data: serviceData) { error in
                if let error = error {
                    print("Error uploading item \(index + 1): \(error.localizedDescription)")
                } else {
                    print("Successfully uploaded item \(index + 1): \(serviceData["title"] ?? "")")
                }
            }
        }
    }
}

/*
 File: DummyDataSeeder.swift
 Purpose: Seeds the Firestore database with high-volume dummy data for development.
 Location: Services/Utilities/DummyDataSeeder.swift
 Description: Generates ~20 items per model (Services, Skills, Bookings, Reviews, Portfolio) for the current user.
*/

import Foundation
import FirebaseAuth
import FirebaseFirestore

#if DEBUG

final class DummyDataSeeder {
    
    static let shared = DummyDataSeeder()
    private init() {}
    
    private let serviceRepo = ServiceRepository.shared
    private let skillRepo = SkillRepository.shared
    private let bookingRepo = BookingRepository.shared
    private let reviewRepo = ReviewRepository.shared
    private let portfolioRepo = PortfolioRepository.shared
    
    // MARK: - Public API
    
    func seedIfNeeded() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ [Seeder] No user logged in. Skipping seed.")
            return
        }
        
        let key = "didSeedDummyData_Volume_\(uid)" // Changed key to force re-seed if user had old key
        if UserDefaults.standard.bool(forKey: key) {
            print("✅ [Seeder] Data already seeded for user \(uid). Skipping.")
            return
        }
        
        print("🌱 [Seeder] Starting HIGH VOLUME dummy data seed for user \(uid)...")
        seedAll(for: uid) { success in
            if success {
                UserDefaults.standard.set(true, forKey: key)
                print("🏁 [Seeder] Seeding complete! 🚀")
            } else {
                print("❌ [Seeder] Seeding failed partially.")
            }
        }
    }
    
    func resetSeedFlag() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let key = "didSeedDummyData_Volume_\(uid)"
        UserDefaults.standard.set(false, forKey: key)
        print("🔄 [Seeder] Reset seed flag for \(uid).")
    }
    
    // MARK: - Master Seed Method
    
    func seedAll(for uid: String, completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        
        // 1. Seed Categories (Global-ish) & Services
        group.enter()
        seedServices(for: uid) { group.leave() }
        
        // 2. Seed Skills
        group.enter()
        seedSkills(for: uid) { group.leave() }
        
        // 3. Seed Portfolio
        group.enter()
        seedPortfolio(for: uid) { group.leave() }
        
        // 4. Seed Bookings
        group.enter()
        seedBookings(for: uid) { group.leave() }
        
        // 5. Seed Reviews
        group.enter()
        seedReviews(for: uid) { group.leave() }
        
        group.notify(queue: .main) {
            completion(true)
        }
    }
    
    // MARK: - Individual Seeders
    
    private func seedServices(for uid: String, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        // Ensure some categories exist
        let categories = ["Cleaning", "Education", "Plumbing", "Electrical", "moving", "Beauty", "Fitness", "Automotive"]
        for catName in categories {
            group.enter()
            let cat = ServiceCategory(id: nil, name: catName, iconURL: nil, isActive: true)
            serviceRepo.createServiceCategory(cat) { _ in group.leave() }
        }
        
        // Create 20 Services
        for i in 1...20 {
            group.enter()
            let category = categories[i % categories.count]
            let service = Service(
                id: nil,
                providerId: uid,
                title: "Service #\(i) - \(category) Special",
                description: "This is a detailed description for service number \(i). We provide excellent results.",
                category: category,
                sessionPrice: Double(10 + i * 2),
                currencyCode: "BHD",
                coverImageURL: "", 
                rating: Double.random(in: 3.5...5.0),
                reviewCount: Int.random(in: 0...50),
                isActive: true,
                createdAt: Date().addingTimeInterval(-Double(i) * 3600),
                updatedAt: Date()
            )
            serviceRepo.createService(service) { _ in group.leave() }
        }
        
        group.notify(queue: .main) {
            print("   - [20 Services + Categories] seeded.")
            completion()
        }
    }
    
    private func seedSkills(for uid: String, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        let statuses: [SkillStatus] = [.approved, .approved, .approved, .pending, .rejected]
        let levels: [SkillLevel] = [.expert, .intermediate, .beginner, .expert]
        
        for i in 1...20 {
            group.enter()
            let status = statuses[i % statuses.count]
            let level = levels[i % levels.count]
            
            let skill = Skill(
                id: nil,
                providerId: uid,
                name: "Skill #\(i) (e.g. Kotlin)",
                level: level,
                description: "Description for skill \(i)",
                proofImageURL: nil,
                status: status,
                adminFeedback: status == .rejected ? "Proof unclear" : nil
            )
            skillRepo.createSkill(skill) { _ in group.leave() }
        }
        
        group.notify(queue: .main) {
            print("   - [20 Skills] seeded.")
            completion()
        }
    }
    
    private func seedPortfolio(for uid: String, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        for i in 1...20 {
            group.enter()
            let project = PortfolioProject(
                id: nil,
                providerId: uid,
                title: "Project #\(i) Showcase",
                description: "A wonderful project completed recently. See photos attached.",
                imageURLs: [],
                timestamp: Date().addingTimeInterval(-Double(i) * 86400 * 5)
            )
            portfolioRepo.createPortfolioProject(project) { _ in group.leave() }
        }
        
        group.notify(queue: .main) {
            print("   - [20 Portfolio Projects] seeded.")
            completion()
        }
    }
    
    private func seedBookings(for uid: String, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        // 20 Bookings (Mix of History/Completed and Upcoming/Accepted)
        for i in 1...20 {
            group.enter()
            
            // Alternate between being Seeker (History) vs Provider (Jobs)
            // Even numbers = Seeker (History)
            // Odd numbers = Provider (Upcoming)
            let isHistory = (i % 2 == 0)
            
            let status: BookingStatus = isHistory ? .completed : .accepted
            let offsetDays = isHistory ? -Double(i) : Double(i)
            
            let booking = Booking(
                id: nil,
                seekerId: isHistory ? uid : "dummy_seeker_\(i)",
                providerId: isHistory ? "dummy_provider_\(i)" : uid,
                serviceId: "dummy_service_\(i)",
                serviceTitle: isHistory ? "History Service #\(i)" : "Upcoming Job #\(i)",
                priceAtBooking: Double(20 + i),
                currencyCode: "BHD",
                coverImageURLAtBooking: nil,
                scheduledAt: Date().addingTimeInterval(offsetDays * 86400),
                note: "Booking note #\(i)",
                status: status,
                acceptedAt: Date().addingTimeInterval(offsetDays * 86400 - 3600),
                startedAt: isHistory ? Date().addingTimeInterval(offsetDays * 86400) : nil,
                completedAt: isHistory ? Date().addingTimeInterval(offsetDays * 86400 + 7200) : nil,
                rejectedAt: nil,
                createdAt: Date().addingTimeInterval(offsetDays * 86400 - 7200)
            )
            
            bookingRepo.createBooking(booking) { _ in group.leave() }
        }
        
        group.notify(queue: .main) {
            print("   - [20 Bookings] seeded.")
            completion()
        }
    }
    
    private func seedReviews(for uid: String, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        for i in 1...20 {
            group.enter()
            
            // Generate some reasonable ratings
            let rating = [3, 4, 5, 5, 5, 4, 2, 5][i % 8]
            
            let review = Review(
                id: nil,
                bookingId: "dummy_booking_\(i)",
                serviceId: "dummy_service_\(i)",
                providerId: uid, // Reviews FOR us
                seekerId: "dummy_user_\(i)",
                rating: rating,
                comment: "Automated review comment #\(i). This service was \(rating >= 4 ? "great" : "okay").",
                timestamp: Date().addingTimeInterval(-Double(i) * 86400)
            )
            reviewRepo.createReview(review) { _ in group.leave() }
        }
        
        group.notify(queue: .main) {
            print("   - [20 Reviews] seeded.")
            completion()
        }
    }
}

#endif

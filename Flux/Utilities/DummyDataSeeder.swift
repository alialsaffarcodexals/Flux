///*
// File: DummyDataSeeder.swift
// Purpose: Seeds the Firestore database with dummy data for development.
// Location: Services/Utilities/DummyDataSeeder.swift
// Description: Generates test data for Services, Skills, Bookings, Reviews, etc. scoped to the current user.
//*/
//
//import Foundation
//import FirebaseAuth
//import FirebaseFirestore
//
//#if DEBUG
//
//final class DummyDataSeeder {
//    
//    static let shared = DummyDataSeeder()
//    private init() {}
//    
//    private let serviceRepo = ServiceRepository.shared
//    private let skillRepo = SkillRepository.shared
//    private let bookingRepo = BookingRepository.shared
//    private let reviewRepo = ReviewRepository.shared
//    private let portfolioRepo = PortfolioRepository.shared // Assuming existence based on file list
//    // private let chatRepo = ChatRepository.shared // Assuming existence
//    // private let reportRepo = ReportRepository.shared // Assuming existence
//    
//    // MARK: - Public API
//    
//    func seedIfNeeded() {
//        guard let uid = Auth.auth().currentUser?.uid else {
//            print("[Seeder] No user logged in. Skipping seed.")
//            return
//        }
//        
//        let key = "didSeedDummyData_\(uid)"
//        if UserDefaults.standard.bool(forKey: key) {
//            print("[Seeder] Data already seeded for user \(uid). Skipping.")
//            return
//        }
//        
//        print("[Seeder] Starting dummy data seed for user \(uid)...")
//        seedAll(for: uid) { success in
//            if success {
//                UserDefaults.standard.set(true, forKey: key)
//                print("[Seeder] Seeding complete! ")
//            } else {
//                print("[Seeder] Seeding failed partially.")
//            }
//        }
//    }
//    
//    func resetSeedFlag() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let key = "didSeedDummyData_\(uid)"
//        UserDefaults.standard.set(false, forKey: key)
//        print("[Seeder] Reset seed flag for \(uid).")
//    }
//    
//    // MARK: - Master Seed Method
//    
//    func seedAll(for uid: String, completion: @escaping (Bool) -> Void) {
//        let group = DispatchGroup()
//        
//        // 1. Seed Categories & Services
//        group.enter()
//        seedServices(for: uid) { group.leave() }
//        
//        // 2. Seed Skills
//        group.enter()
//        seedSkills(for: uid) { group.leave() }
//        
//        // 3. Seed Portfolio
//        group.enter()
//        seedPortfolio(for: uid) { group.leave() }
//        
//        // 4. Seed Bookings
//        group.enter()
//        seedBookings(for: uid) { group.leave() }
//        
//        // 5. Seed Reviews
//        group.enter()
//        seedReviews(for: uid) { group.leave() }
//        
//        // 6. Seed Chats (Optional/Later)
//        // group.enter()
//        // seedChats(for: uid) { group.leave() }
//
//        group.notify(queue: .main) {
//            completion(true)
//        }
//    }
//    
//    // MARK: - Individual Seeders
//    
//    private func seedServices(for uid: String, completion: @escaping () -> Void) {
//        // Create 2 dummy services
//        let s1 = Service(
//            id: nil,
//            providerId: uid,
//            title: "Premium House Cleaning",
//            description: "Deep cleaning for your home using eco-friendly products. Includes dusting, vacuuming, and sanitizing.",
//            category: "Cleaning",
//            sessionPrice: 45.0,
//            currencyCode: "BHD",
//            coverImageURL: "", // Placeholder or leave empty
//            rating: 4.8,
//            reviewCount: 12,
//            isActive: true,
//            createdAt: Date(),
//            updatedAt: Date()
//        )
//        
//        let s2 = Service(
//            id: nil,
//            providerId: uid,
//            title: "Math Tutoring (Algebra)",
//            description: "One-on-one algebra tutoring sessions for high school students. 1 hour session.",
//            category: "Education",
//            sessionPrice: 20.0,
//            currencyCode: "BHD",
//            coverImageURL: "",
//            rating: 5.0,
//            reviewCount: 5,
//            isActive: true,
//            createdAt: Date(),
//            updatedAt: Date()
//        )
//        
//        let group = DispatchGroup()
//        
//        group.enter()
//        serviceRepo.createService(s1) { _ in group.leave() }
//        
//        group.enter()
//        serviceRepo.createService(s2) { _ in group.leave() }
//        
//        // Ensure Categories exist (Optional: Create global categories if needed)
//        // ideally categories are global, but we can seed one just in case
//        let c1 = ServiceCategory(id: nil, name: "Cleaning", iconURL: nil, isActive: true)
//        let c2 = ServiceCategory(id: nil, name: "Education", iconURL: nil, isActive: true)
//        
//        group.enter()
//        serviceRepo.createServiceCategory(c1) { _ in group.leave() }
//        group.enter()
//        serviceRepo.createServiceCategory(c2) { _ in group.leave() }
//        
//        group.notify(queue: .main) {
//            print("- Services & Categories seeded.")
//            completion()
//        }
//    }
//    
//    private func seedSkills(for uid: String, completion: @escaping () -> Void) {
//        let sk1 = Skill(
//            id: nil,
//            providerId: uid,
//            name: "Swift Programming",
//            level: .expert,
//            description: "5+ years of iOS development experience.",
//            proofImageURL: nil,
//            status: .approved,
//            adminFeedback: nil
//        )
//        
//        let sk2 = Skill(
//            id: nil,
//            providerId: uid,
//            name: "Interior Design",
//            level: .intermediate,
//            description: "Certified interior decorator.",
//            proofImageURL: nil,
//            status: .pending,
//            adminFeedback: nil
//        )
//        
//        let group = DispatchGroup()
//        group.enter()
//        skillRepo.createSkill(sk1) { _ in group.leave() }
//        group.enter()
//        skillRepo.createSkill(sk2) { _ in group.leave() }
//        
//        group.notify(queue: .main) {
//            print("- Skills seeded.")
//            completion()
//        }
//    }
//    
//    private func seedPortfolio(for uid: String, completion: @escaping () -> Void) {
//        // Assuming PortfolioRepository exists and has createPortfolioProject
//        // If not, we skip.
//        
//        let p1 = PortfolioProject(
//            id: nil,
//            providerId: uid,
//            title: "Modern Apartment Renovation",
//            description: "Complete redesign of a 2-bedroom apartment in downtown.",
//            imageURLs: [],
//            timestamp: Date()
//        )
//        
//        // NOTE: If PortfolioRepository doesn't strictly exist or match signature, this might fail to compile.
//        // I'll assume standard naming based on user prompt "repositories/CRUD helpers for each model".
//        // I will use `PortfolioRepository.shared.createPortfolioProject(...)` pattern.
//        
//        portfolioRepo.createPortfolioProject(p1) { _ in
//            print("- Portfolio seeded.")
//            completion()
//        }
//    }
//    
//    private func seedBookings(for uid: String, completion: @escaping () -> Void) {
//        // Create a booking where we are the SEEKER (history)
//        let b1 = Booking(
//            id: nil,
//            seekerId: uid,
//            providerId: "dummy_provider_id_99", // Fake provider
//            serviceId: "dummy_service_id_99", providerName: "Ali Abdullah",
//            serviceTitle: "AC Maintenance",
//            priceAtBooking: 30.0,
//            currencyCode: "BHD",
//            coverImageURLAtBooking: nil,
//            scheduledAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
//            note: "Please check the cooling unit.",
//            status: .completed,
//            acceptedAt: Date().addingTimeInterval(-86400 * 3),
//            startedAt: Date().addingTimeInterval(-86400 * 2),
//            completedAt: Date().addingTimeInterval(-86400 * 2 + 3600),
//            rejectedAt: nil,
//            createdAt: Date().addingTimeInterval(-86400 * 5)
//        )
//        
//        // Create a booking where we are the PROVIDER (upcoming job)
//        let b2 = Booking(
//            id: nil,
//            seekerId: "dummy_seeker_id_88", // Fake seeker
//            providerId: uid,
//            serviceId: "dummy_service_id_101", providerName: "Son Huge Min",
//            serviceTitle: "Premium House Cleaning",
//            priceAtBooking: 45.0,
//            currencyCode: "BHD",
//            coverImageURLAtBooking: nil,
//            scheduledAt: Date().addingTimeInterval(86400), // Tomorrow
//            note: "Key is under the mat.",
//            status: .accepted,
//            acceptedAt: Date(),
//            startedAt: nil,
//            completedAt: nil,
//            rejectedAt: nil,
//            createdAt: Date()
//        )
//        
//        let group = DispatchGroup()
//        group.enter()
//        bookingRepo.createBooking(b1) { _ in group.leave() }
//        group.enter()
//        bookingRepo.createBooking(b2) { _ in group.leave() }
//        
//        group.notify(queue: .main) {
//            print("- Bookings seeded.")
//            completion()
//        }
//    }
//    
//    private func seedReviews(for uid: String, completion: @escaping () -> Void) {
//        // Review FOR us (as Provider)
//        let r1 = Review(
//            
//            bookingId: "dummy_booking_id_1",
//            serviceId: "dummy_service_id_101",
//            providerId: uid,
//            seekerId: "dummy_seeker_id_88",
//            rating: 5,
//            comment: "Excellent service! Very professional and thorough.",
//            
//        )
//        
//        // Review BY us (as Seeker)
//        let r2 = Review(
//            
//            bookingId: "dummy_booking_id_2",
//            serviceId: "dummy_service_id_99",
//            providerId: "dummy_provider_id_99",
//            seekerId: uid,
//            rating: 4,
//            comment: "Good job, but arrived a bit late.",
//            
//        )
//        
//        let group = DispatchGroup()
//        group.enter()
//        reviewRepo.createReview(r1) { _ in group.leave() }
//        group.enter()
//        reviewRepo.createReview(r2) { _ in group.leave() }
//        
//        group.notify(queue: .main) {
//            print("- Reviews seeded.")
//            completion()
//        }
//    }
//}
//
//#endif

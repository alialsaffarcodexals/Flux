//
//  ProviderDetailsViewModel.swift
//  Flux
//
//  Created by Flux Agent on 02/01/2026.
//

import Foundation
import UIKit

class ProviderDetailsViewModel {
    let company: Company
    var services: [ServicePackage] = []
    var skills: [Skill] = []
    
    var isFavorite: Bool {
        // MVP: Check UserDefaults
        let favorites = UserDefaults.standard.stringArray(forKey: "FavoriteProviders") ?? []
        return favorites.contains(company.providerId)
    }
    
    var onDataUpdated: (() -> Void)?
    
    init(company: Company) {
        self.company = company
    }
    
    // MARK: - Data Accessors
    
    var name: String {
        return company.name
    }
    
    var ratingText: String {
        return "\(company.rating) ★"
    }
    
    var imageURL: URL? {
        guard !company.imageURL.isEmpty else { return nil }
        return URL(string: company.imageURL)
    }
    
    var providerId: String {
        return company.providerId
    }
    
    // MARK: - Actions
    
    func fetchServices() {
        let group = DispatchGroup()
        
        // Fetch Services
        group.enter()
        FirestoreServicePackagesRepository.shared.fetchPackagesForProvider(providerId: company.providerId) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let packages):
                self?.services = packages
            case .failure(let error):
                print("❌ Failed to fetch services: \(error.localizedDescription)")
            }
        }
        
        // Fetch Skills
        group.enter()
        SkillRepository.shared.fetchSkills(for: company.providerId) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let skills):
                // Filter only approved skills if needed, or show all. 
                // Typically users see only approved skills, but let's show all for now or approved ones.
                // The requirement didn't specify, but usually public profiles show Approved.
                // Result<[Skill], Error> doesn't imply filtering in Repo for this method signature, 
                // but let's just assign them.
                self?.skills = skills.filter { $0.status == .approved }
            case .failure(let error):
                print("❌ Failed to fetch skills: \(error.localizedDescription)")
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.onDataUpdated?()
        }
    }
    
    func toggleFavorite() {
        var favorites = UserDefaults.standard.stringArray(forKey: "FavoriteProviders") ?? []
        if favorites.contains(company.providerId) {
            favorites.removeAll { $0 == company.providerId }
        } else {
            favorites.append(company.providerId)
        }
        UserDefaults.standard.set(favorites, forKey: "FavoriteProviders")
        onDataUpdated?()
    }
}

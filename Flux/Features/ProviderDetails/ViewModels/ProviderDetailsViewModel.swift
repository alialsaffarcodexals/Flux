//
//  ProviderDetailsViewModel.swift
//  Flux
//
//  Created by Flux Agent on 02/01/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

class ProviderDetailsViewModel {
    let company: Company
    var services: [ServicePackage] = []
    var skills: [Skill] = []
    
    var isFavorite: Bool = false
    
    var onDataUpdated: (() -> Void)?
    
    init(company: Company) {
        self.company = company
        checkIfFavorite()
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
                print("Failed to fetch services: \(error.localizedDescription)")
            }
        }
        
        // Fetch Skills
        group.enter()
        SkillRepository.shared.fetchSkills(for: company.providerId) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let skills):
                self?.skills = skills.filter { $0.status == .approved }
            case .failure(let error):
                print("Failed to fetch skills: \(error.localizedDescription)")
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.onDataUpdated?()
        }
    }
    
    private func checkIfFavorite() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        UserRepository.shared.getUser(uid: currentUserID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                if let favorites = user.favoriteProviderIds {
                    self.isFavorite = favorites.contains(self.company.providerId)
                    DispatchQueue.main.async {
                        self.onDataUpdated?()
                    }
                }
            case .failure(let error):
                print("Failed to fetch user for favorite check: \(error)")
            }
        }
    }
    
    func toggleFavorite() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // Optimistic update
        isFavorite.toggle()
        onDataUpdated?()
        
        if isFavorite {
            UserRepository.shared.addFavoriteProvider(userId: currentUserID, providerId: company.providerId) { error in
                if case .failure(let error) = error {
                    print("Failed to add favorite: \(error)")
                    // Revert on failure
                    self.isFavorite.toggle()
                    self.onDataUpdated?()
                }
            }
        } else {
            UserRepository.shared.removeFavoriteProvider(userId: currentUserID, providerId: company.providerId) { error in
                if case .failure(let error) = error {
                    print("Failed to remove favorite: \(error)")
                    // Revert on failure
                    self.isFavorite.toggle()
                    self.onDataUpdated?()
                }
            }
        }
    }
}

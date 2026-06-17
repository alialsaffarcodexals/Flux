/*
 File: FavoritesVM.swift
 Purpose: ViewModel for Favorites screen
 Location: Features/Favorites/ViewModels/FavoritesVM.swift
*/

import Foundation
import FirebaseAuth

/// Represents a favorite provider for display
struct FavoriteDisplayItem {
    let providerId: String
    let providerName: String
    let serviceName: String
    let profileImageURL: String?
}

final class FavoritesVM {
    
    // MARK: - Properties
    private(set) var favoriteItems: [FavoriteDisplayItem] = []
    private(set) var filteredItems: [FavoriteDisplayItem] = []
    private var isSearching = false
    
    // MARK: - Callbacks
    var onDataChanged: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Dependencies
    private let userRepo = UserRepository.shared

    
    // MARK: - Computed Properties
    var displayItems: [FavoriteDisplayItem] {
        return isSearching ? filteredItems : favoriteItems
    }
    
    var itemCount: Int {
        return displayItems.count
    }
    
    // MARK: - Public Methods
    // MARK: - Public Methods
    func loadFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else {
            onDataChanged?()
            return
        }
        
        // Get current user's favorite provider IDs
        userRepo.getUser(uid: userId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                let favoriteIds = user.favoriteProviderIds ?? []
                
                if favoriteIds.isEmpty {
                    DispatchQueue.main.async {
                        self.favoriteItems = []
                        self.onDataChanged?()
                    }
                } else {
                    self.fetchProviderDetails(for: favoriteIds)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.onError?(error)
                    // If fetching user fails, we might still want to show empty or handle it gracefullly
                    self.favoriteItems = []
                    self.onDataChanged?()
                }
            }
        }
    }
    
    private func fetchProviderDetails(for providerIds: [String]) {
        // Use batch fetch from Repository
        userRepo.fetchUsers(byIds: providerIds) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let providers):
                let items = providers.compactMap { provider -> FavoriteDisplayItem? in
                    guard let providerId = provider.id else { return nil }
                    let serviceName = provider.businessName ?? "Service Provider"
                    return FavoriteDisplayItem(
                        providerId: providerId,
                        providerName: provider.name,
                        serviceName: serviceName,
                        profileImageURL: provider.providerProfileImageURL
                    )
                }
                
                DispatchQueue.main.async {
                    self.favoriteItems = items
                    self.onDataChanged?()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Failed to fetch favorite providers: \(error)")
                    // On error, show empty or keep previous
                    self.favoriteItems = []
                    self.onDataChanged?()
                }
            }
        }
    }
    
    func item(at index: Int) -> FavoriteDisplayItem? {
        guard displayItems.indices.contains(index) else { return nil }
        return displayItems[index]
    }
    
    func removeFromFavorites(at index: Int) {
        guard displayItems.indices.contains(index),
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let item = displayItems[index]
        let providerId = item.providerId
        
        // Optimistic remove from UI
        if isSearching {
           filteredItems.remove(at: index)
           favoriteItems.removeAll { $0.providerId == providerId }
        } else {
           favoriteItems.remove(at: index)
        }
        onDataChanged?()
        
        // Remove from Backend via Repository
        userRepo.removeFavoriteProvider(userId: userId, providerId: providerId) { [weak self] result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                     // Revert if failed (complex to insert back at same index, just reload)
                     print("Failed to remove favorite: \(error)")
                     self?.onError?(error)
                     self?.loadFavorites() // Reload to restore state
                }
            }
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            isSearching = false
            filteredItems = []
        } else {
            isSearching = true
            filteredItems = favoriteItems.filter { item in
                item.providerName.lowercased().contains(query.lowercased()) ||
                item.serviceName.lowercased().contains(query.lowercased())
            }
        }
        onDataChanged?()
    }
    
    func clearSearch() {
        isSearching = false
        filteredItems = []
        onDataChanged?()
    }
}

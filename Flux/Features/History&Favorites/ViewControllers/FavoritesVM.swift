/*
 File: FavoritesVM.swift
 Purpose: ViewModel for Favorites screen
 Location: Features/Favorites/ViewModels/FavoritesVM.swift
*/

import Foundation
import FirebaseAuth
import FirebaseFirestore

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
    private let db = Firestore.firestore()
    
    // MARK: - Computed Properties
    var displayItems: [FavoriteDisplayItem] {
        return isSearching ? filteredItems : favoriteItems
    }
    
    var itemCount: Int {
        return displayItems.count
    }
    
    // MARK: - Public Methods
    func loadFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else {
            onDataChanged?()
            return
        }
        
        // Get current user's favorite provider IDs
        userRepo.getUser(uid: userId) { [weak self] result in
            switch result {
            case .success(let user):
                let favoriteIds = user.favoriteProviderIds ?? []
                if favoriteIds.isEmpty {
                    DispatchQueue.main.async {
                        self?.favoriteItems = []
                        self?.onDataChanged?()
                    }
                } else {
                    self?.fetchProviderDetails(for: favoriteIds)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.onError?(error)
                }
            }
        }
    }
    
    private func fetchProviderDetails(for providerIds: [String]) {
        let group = DispatchGroup()
        var items: [FavoriteDisplayItem] = []
        
        for providerId in providerIds {
            group.enter()
            
            userRepo.getUser(uid: providerId) { result in
                defer { group.leave() }
                
                switch result {
                case .success(let provider):
                    let serviceName = provider.businessName ?? "Service Provider"
                    let item = FavoriteDisplayItem(
                        providerId: providerId,
                        providerName: provider.name,
                        serviceName: serviceName,
                        profileImageURL: provider.profileImageURL
                    )
                    items.append(item)
                case .failure:
                    // Skip providers we can't fetch
                    break
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.favoriteItems = items
            self?.onDataChanged?()
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
        
        // Remove from Firebase
        db.collection("users").document(userId).updateData([
            "favoriteProviderIds": FieldValue.arrayRemove([providerId])
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.onError?(error)
                    return
                }
                
                // Remove from local data
                self?.favoriteItems.removeAll { $0.providerId == providerId }
                self?.filteredItems.removeAll { $0.providerId == providerId }
                self?.onDataChanged?()
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

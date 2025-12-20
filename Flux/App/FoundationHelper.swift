//
//  FoundationHelper.swift
//  Flux
//
//  Created by Mohammed Alnooh on 20/12/2025.
//
import Foundation

class FoundationHelper {
    
    static let shared = FoundationHelper()
    private let db = DatabaseFoundation.shared
    
    // Collection Names (to avoid typos)
    private let kUsers = "users"
    private let kProviders = "provider_details"
    private let kServices = "services"
    private let kRequests = "requests"
    
    private init() {}
    
    // MARK: - 1. Get User Data
    func getUserProfile(uid: String, completion: @escaping (AppUser?, String?) -> Void) {
        db.fetchDocument(collection: kUsers, docId: uid) { (result: Result<AppUser, Error>) in
            switch result {
            case .success(let user):
                completion(user, nil)
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    // MARK: - 2. Get Provider Details (Skills, Portfolio)
    func getProviderDetails(uid: String, completion: @escaping (ProviderDetails?, String?) -> Void) {
        // Note: The docID for provider_details is the same as the User UID
        db.fetchDocument(collection: kProviders, docId: uid) { (result: Result<ProviderDetails, Error>) in
            switch result {
            case .success(let details):
                completion(details, nil)
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    // MARK: - 3. Get Specific Service Data
    func getService(serviceID: String, completion: @escaping (Service?, String?) -> Void) {
        db.fetchDocument(collection: kServices, docId: serviceID) { (result: Result<Service, Error>) in
            switch result {
            case .success(let service):
                completion(service, nil)
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    // MARK: - 4. Get All Services for a specific Provider
    func getServicesForProvider(providerUID: String, completion: @escaping ([Service]?, String?) -> Void) {
        let filter = ("providerID", providerUID)
        
        db.fetchCollection(collection: kServices, filters: [filter]) { (result: Result<[Service], Error>) in
            switch result {
            case .success(let services):
                completion(services, nil)
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    // MARK: - 5. Get Requests (Orders)
    // If isProvider = true, gets incoming orders. If false, gets my requests.
    func getRequests(forUID uid: String, isProvider: Bool, completion: @escaping ([RequestOrder]?, String?) -> Void) {
        let fieldName = isProvider ? "providerID" : "seekerID"
        
        db.fetchCollection(collection: kRequests, filters: [(fieldName, uid)]) { (result: Result<[RequestOrder], Error>) in
            switch result {
            case .success(let requests):
                completion(requests, nil)
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }
    }
}

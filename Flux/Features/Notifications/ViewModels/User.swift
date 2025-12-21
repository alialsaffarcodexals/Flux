/*
 File: User.swift
 Purpose: struct User, struct RegisterUserRequest
 Location: Features/Notifications/ViewModels/User.swift
*/









import Foundation




/// Struct User: Value type that models the User data and related helpers.
struct User {
    let uid: String
    let name: String
    let email: String
    let role: String
    
    
    let username: String?
    let profileImageURL: String?
    
    
    init?(dictionary: [String: Any]) {
        
        guard let name = dictionary["name"] as? String,
              let email = dictionary["email"] as? String,
              let role = dictionary["role"] as? String else {
            return nil
        }
        
        
        self.uid = dictionary["uid"] as? String ?? ""
        self.name = name
        self.email = email
        self.role = role
        
        
        self.username = dictionary["username"] as? String
        self.profileImageURL = dictionary["profileImageURL"] as? String
    }
}




/// Struct RegisterUserRequest: Value type that models the RegisterUserRequest data and related helpers.
struct RegisterUserRequest {
    let name: String
    let email: String
    let password: String
    let role: String 
    let phone: String
}

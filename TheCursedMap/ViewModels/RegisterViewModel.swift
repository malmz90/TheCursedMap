//
//  RegisterViewModel.swift
//  TheCursedMap
//
//  Created by Emilia Forsheim on 2025-05-20.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class RegisterViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var errorMessage: String = ""
    
    init() {}
    
    func register(completion: @escaping (Bool) -> Void) {
        guard validate() else {
            completion(false)
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self, let user = result?.user, error == nil else {
                DispatchQueue.main.async {
                    self?.errorMessage = error?.localizedDescription ?? "Registration Failed"
                    completion(false)
                }
                return
            }

            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = self.name
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Failed to set displayName: \(error.localizedDescription)")
                }
            }

            self.createUser(id: user.uid) {
                completion(true)
            }
        }
    }
    private func createUser(id: String, completion: @escaping () -> Void) {
        let newUser = UserModel(id: id, name: name, email: email)
        let db = Firestore.firestore()
        
        db.collection("users")
            .document(id)
            .setData(newUser.asDict()) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    }
                    completion()
                }
            }
    }
    
    // MARK: Input validation
    private func validate() -> Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty,
              !name.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            errorMessage = "Enter a valid Email/Password. Fill in all the fields"
            return false
        }
        
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Enter a valid Email"
            return false
        }
        
        guard password.count > 5 else {
            errorMessage = "Password should be at least 6 characters long"
            return false
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return false
        }
        return true
    }
}

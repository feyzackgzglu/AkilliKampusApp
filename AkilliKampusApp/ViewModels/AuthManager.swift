import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    // Kampüs domain kısıtlamaları (Atatürk Üniversitesi)
    private let allowedDomains = ["atauni.edu.tr", "ogr.atauni.edu.tr"]
    private var db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var userListenerRegistration: ListenerRegistration?
    
    init() {
        startAuthListener()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        userListenerRegistration?.remove()
    }

    // Google Sign-In
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Root View Controller not found")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard error == nil else {
                self?.authError = error?.localizedDescription
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    self?.authError = error.localizedDescription
                    return
                }
                
                // Firestore'a kaydet (eğer ilk kez giriyorsa)
                if let firebaseUser = result?.user {
                    self?.checkAndCreateGoogleUser(firebaseUser: firebaseUser, googleUser: user)
                }
            }
        }
    }

    private func checkAndCreateGoogleUser(firebaseUser: FirebaseAuth.User, googleUser: GIDGoogleUser) {
        let uid = firebaseUser.uid
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if !((snapshot?.exists) ?? false) {
                // Yeni kullanıcı, kaydet
                let name = googleUser.profile?.name ?? "Google User"
                let email = googleUser.profile?.email ?? ""
                
                let newUser = User(
                    id: uid,
                    name: name,
                    email: email,
                    department: "Bilinmiyor", // Google'dan gelmez, kullanıcı güncelleyebilir
                    role: .user,
                    followedIncidentIds: []
                )
                self?.saveUserToFirestore(user: newUser)
            }
        }
    }
    
    private func startAuthListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, authUser in
            if let authUser = authUser {
                // Kullanıcı giriş yapmış, Firestore'dan detayları çek
                self?.startListeningForUser(uid: authUser.uid)
            } else {
                // Çıkış yapmış
                self?.currentUser = nil
                self?.isAuthenticated = false
                self?.userListenerRegistration?.remove()
                self?.userListenerRegistration = nil
            }
        }
    }
    
    // Login
    func login(email: String, password: String) {
        if email.isEmpty || password.isEmpty {
            authError = "Lütfen e-posta ve şifrenizi giriniz."
            return
        }
        
        // Admin kontrolü (Opsiyonel: Eğer admin paneli girişi farklıysa burası kalabilir, 
        // ancak Firebase kullanıyorsak admin hesabı da Firebase'de olmalı. 
        // Şimdilik admin hardcode'unu kaldırdım, Firebase'de 'admin@kampus.edu.tr' açılabilir.)

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.authError = error.localizedDescription
                return
            }
            self?.authError = nil
            // Listener durumu güncelleyecek
        }
    }
    
    // Register
    func register(name: String, email: String, department: String, password: String) {
        if name.isEmpty || email.isEmpty || password.isEmpty {
            authError = "Lütfen tüm alanları doldurun."
            return
        }
        
        // Domain kontrolü
        let hasValidDomain = allowedDomains.contains { email.lowercased().hasSuffix("@" + $0) }
        if !hasValidDomain {
            authError = "Kayıt olmak için üniversite e-postası (@atauni.edu.tr veya @ogr.atauni.edu.tr) gereklidir."
            return
        }
        
        if password.count < 6 {
            authError = "Şifreniz en az 6 karakter olmalıdır."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.authError = error.localizedDescription
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            // Yeni kullanıcı modelini oluştur
            let newUser = User(
                id: uid,
                name: name,
                email: email,
                department: department,
                role: .user, // Varsayılan rol
                followedIncidentIds: []
            )
            
            // Firestore'a kaydet
            self?.saveUserToFirestore(user: newUser)
            
            self?.authError = nil
            // Başarılı olunca listener devreye girip currentUser'ı set edecek
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            authError = nil
        } catch {
            authError = "Çıkış yapılırken hata oluştu: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Firestore Operations
    
    private func saveUserToFirestore(user: User) {
        let userData: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "department": user.department ?? "",
            "role": user.role.rawValue,
            "followedIncidentIds": user.followedIncidentIds.map { $0.uuidString },
            "notificationPreferences": user.notificationPreferences
        ]
        
        db.collection("users").document(user.id).setData(userData) { [weak self] error in
            if let error = error {
                print("Error saving user data: \(error)")
                self?.authError = "Kullanıcı bilgileri kaydedilemedi."
            } else {
                self?.currentUser = user
                self?.isAuthenticated = true
            }
        }
    }
    
    func toggleNotificationPreference(type: IncidentType) {
        guard var user = currentUser else { return }
        let typeStr = type.rawValue
        
        if user.notificationPreferences.contains(typeStr) {
            user.notificationPreferences.removeAll { $0 == typeStr }
        } else {
            user.notificationPreferences.append(typeStr)
        }
        
        // Firestore'u güncelle
        db.collection("users").document(user.id).updateData([
            "notificationPreferences": user.notificationPreferences
        ])
    }
    
    private func startListeningForUser(uid: String) {
        userListenerRegistration?.remove()
        userListenerRegistration = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error listening for user: \(error)")
                self?.authError = "Kullanıcı bilgileri alınamadı."
                return
            }
            
            guard let data = snapshot?.data() else {
                print("User data not found in Firestore")
                return
            }
            
            // Manual Decoding
            let id = data["id"] as? String ?? uid
            let name = data["name"] as? String ?? "Unknown"
            let email = data["email"] as? String ?? ""
            let department = data["department"] as? String
            let roleString = data["role"] as? String ?? "User"
            let role = UserRole(rawValue: roleString.lowercased().capitalized) ?? .user
            let followedIdsStrings = data["followedIncidentIds"] as? [String] ?? []
            let followedIds = followedIdsStrings.compactMap { UUID(uuidString: $0) }
            let notificationPrefs = data["notificationPreferences"] as? [String] ?? IncidentType.allCases.map { $0.rawValue }
            
            let user = User(
                id: id,
                name: name,
                email: email,
                department: department,
                role: role,
                followedIncidentIds: followedIds,
                notificationPreferences: notificationPrefs
            )
            
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = true
            }
        }
    }
}

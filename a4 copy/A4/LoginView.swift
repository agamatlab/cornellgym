import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: View {
    var action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

func getRootViewController() -> UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = scene.windows.first?.rootViewController else {
        return nil
    }
    return getVisibleViewController(from: rootViewController)
}

func getVisibleViewController(from vc: UIViewController) -> UIViewController {
    if let nav = vc as? UINavigationController {
        return getVisibleViewController(from: nav.visibleViewController!)
    }
    if let tab = vc as? UITabBarController {
        return getVisibleViewController(from: tab.selectedViewController!)
    }
    if let presented = vc.presentedViewController {
        return getVisibleViewController(from: presented)
    }
    return vc
}

struct LoginView: View {
    var onLoginSuccess: (String, [String: Any]) -> Void
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            MeshGradientBackground()
            
            BlurryWelcomeText()
            
            AnimatedTextView(text: "RedGYM")
            
            VStack {
                Spacer()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
                
                GoogleSignInButton(action: handleSignupButton)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .disabled(isLoading || isAuthenticating)
                    .opacity(isLoading ? 0.7 : 1.0)
                
                if isLoading {
                    ProgressView()
                        .padding(.bottom, 20)
                }
            }
        }
        .onDisappear {
            isAuthenticating = false
            isLoading = false
        }
    }
    
    func handleSignupButton() {
        guard !isAuthenticating else {
            return
        }
        
        isAuthenticating = true
        isLoading = true
        errorMessage = nil
        
        if let rootViewController = getRootViewController() {
            GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            ) { result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        isAuthenticating = false
                        errorMessage = "Sign-in failed: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let result = result else {
                    DispatchQueue.main.async {
                        isLoading = false
                        isAuthenticating = false
                        errorMessage = "Sign-in failed: No result returned"
                    }
                    return
                }
                
                let idToken = result.user.idToken?.tokenString
                authenticateWithBackend(idToken: idToken, user: result.user)
            }
        }
    }
    
    func authenticateWithBackend(idToken: String?, user: GIDGoogleUser?) {
        guard let idToken = idToken else {
            DispatchQueue.main.async {
                isLoading = false
                isAuthenticating = false
                errorMessage = "Missing ID token from Google"
            }
            return
        }
        
        let profile = user?.profile
        let email = profile?.email ?? "user@example.com"
        let firstName = profile?.givenName ?? "User"
        let lastName = profile?.familyName ?? ""
        
        // Get profile image URL - request high resolution (200px)
        let profileImageUrl = profile?.imageURL(withDimension: 200)?.absoluteString
        
        var requestData: [String: Any] = [
            "google_id_token": idToken,
            "email": email,
            "first_name": firstName,
            "last_name": lastName
        ]
        
        // Add profile image URL to request if available
        if let profileImageUrl = profileImageUrl {
            requestData["picture"] = profileImageUrl
        }
        
        let urlString = "http://34.59.215.239/api/google-login/"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                isLoading = false
                isAuthenticating = false
                errorMessage = "Invalid server URL"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                isAuthenticating = false
                errorMessage = "Failed to prepare request data"
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isAuthenticating = false
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.isAuthenticating = false
                        self.errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                    }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isAuthenticating = false
                    self.errorMessage = "No data received from server"
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let error = json["error"] as? String {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.isAuthenticating = false
                            self.errorMessage = "Server error: \(error)"
                        }
                        return
                    }
                    
                    if let sessionToken = json["session_token"] as? String {
                        // Create user data dictionary
                        var userData: [String: Any] = [:]
                        
                        // Add all relevant user data from the response
                        if let id = json["id"] as? Int {
                            userData["id"] = String(id)
                        }
                        
                        if let email = json["email"] as? String {
                            userData["email"] = email
                        }
                        
                        if let firstName = json["first_name"] as? String {
                            userData["first_name"] = firstName
                        }
                        
                        if let lastName = json["last_name"] as? String {
                            userData["last_name"] = lastName
                        }
                        
                        if let username = json["username"] as? String {
                            userData["username"] = username
                        }
                        
                        // Add profile image URL to userData if it exists
                        if let profileImageUrl = profileImageUrl {
                            userData["picture"] = profileImageUrl
                        }
                        
                        if let updateToken = json["update_token"] as? String {
                            UserDefaults.standard.set(updateToken, forKey: "updateToken")
                        }
                        
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.isAuthenticating = false
                            self.onLoginSuccess(sessionToken, userData)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.isAuthenticating = false
                            self.errorMessage = "Invalid server response: missing session token"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.isAuthenticating = false
                        self.errorMessage = "Failed to parse server response"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isAuthenticating = false
                    self.errorMessage = "Error processing server response"
                }
            }
        }.resume()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager()
        
        return LoginView(onLoginSuccess: { (_, _) in
            // Do nothing in preview
        })
        .environmentObject(authManager)
        .preferredColorScheme(.dark)
    }
}

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var formError: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        // Registration form
                        VStack(spacing: 20) {
                            TextField("Username", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            
                            if let errorMessage = formError ?? authViewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .padding(.top, 5)
                            }
                            
                            Button {
                                register()
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    Text("Register")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .disabled(authViewModel.isLoading || !formIsValid)
                        }
                        
                        Spacer()
                        
                        // Login link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .navigationBarItems(
                leading: Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            )
        }
    }
    
    private var formIsValid: Bool {
        // Don't modify formError state during view evaluation
        if username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            return false
        }
        
        if username.count < 3 {
            return false
        }
        
        if !isValidEmail(email) {
            return false
        }
        
        if password.count < 6 {
            return false
        }
        
        if password != confirmPassword {
            return false
        }
        
        return true
    }
    
    // Separate method to validate form and set error message
    private func validateForm() -> Bool {
        if username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            formError = "All fields are required"
            return false
        }
        
        if username.count < 3 {
            formError = "Username must be at least 3 characters"
            return false
        }
        
        if !isValidEmail(email) {
            formError = "Please enter a valid email address"
            return false
        }
        
        if password.count < 6 {
            formError = "Password must be at least 6 characters"
            return false
        }
        
        if password != confirmPassword {
            formError = "Passwords do not match"
            return false
        }
        
        formError = nil
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func register() {
        if validateForm() {
            Task {
                await authViewModel.register(username: username, email: email, password: password)
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
} 
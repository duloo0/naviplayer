//
//  LoginView.swift
//  naviplayer
//
//  Server connection and login screen
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?

    enum Field {
        case url
        case username
        case password
    }

    var body: some View {
        ZStack {
            // Background
            Color.Background.default
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl2) {
                    // Logo/Header
                    headerSection
                        .padding(.top, Spacing.xl3)

                    // Form
                    VStack(spacing: Spacing.lg) {
                        // Server URL
                        InputField(
                            title: "Server URL",
                            placeholder: "https://your-server.com",
                            text: $viewModel.serverURL,
                            keyboardType: .URL,
                            autocapitalization: .never
                        )
                        .focused($focusedField, equals: .url)

                        // Username
                        InputField(
                            title: "Username",
                            placeholder: "Your username",
                            text: $viewModel.username,
                            autocapitalization: .never
                        )
                        .focused($focusedField, equals: .username)

                        // Password
                        InputField(
                            title: "Password",
                            placeholder: "Your password",
                            text: $viewModel.password,
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)
                    }
                    .padding(.horizontal, Spacing.Page.horizontal)

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.Navi.caption)
                            .foregroundColor(Color.Accent.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.Page.horizontal)
                    }

                    // Connect button
                    Button {
                        Task {
                            await viewModel.connect()
                        }
                    } label: {
                        HStack {
                            if viewModel.isConnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isConnecting ? "Connecting..." : "Connect")
                                .font(.Navi.labelLarge)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: Spacing.Button.height)
                        .background(viewModel.isValid ? Color.white : Color.white.opacity(0.3))
                        .foregroundColor(.black)
                        .cornerRadius(Spacing.Button.cornerRadius)
                    }
                    .disabled(!viewModel.isValid || viewModel.isConnecting)
                    .padding(.horizontal, Spacing.Page.horizontal)
                    .padding(.top, Spacing.md)

                    // Info text
                    Text("NaviPlayer connects to your Navidrome server using the Subsonic API.")
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl2)

                    Spacer(minLength: Spacing.xl3)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onSubmit {
            switch focusedField {
            case .url:
                focusedField = .username
            case .username:
                focusedField = .password
            case .password:
                Task { await viewModel.connect() }
            case .none:
                break
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // App icon placeholder
            ZStack {
                Circle()
                    .fill(Color.Background.elevated)
                    .frame(width: 80, height: 80)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.Accent.cyan)
            }

            Text("NaviPlayer")
                .font(.Navi.headlineMedium)
                .foregroundColor(Color.Text.primary)

            Text("Connect to your Navidrome server")
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)
        }
    }
}

// MARK: - Input Field Component
private struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.Navi.labelMedium)
                .foregroundColor(Color.Text.secondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .font(.Navi.bodyLarge)
            .foregroundColor(Color.Text.primary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.Background.elevated)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.Border.subtle, lineWidth: 1)
            )
        }
    }
}

// MARK: - Login ViewModel
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var serverURL: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isConnecting: Bool = false
    @Published var errorMessage: String?

    var isValid: Bool {
        !serverURL.isEmpty && !username.isEmpty && !password.isEmpty
    }

    func connect() async {
        guard isValid else { return }

        isConnecting = true
        errorMessage = nil

        defer { isConnecting = false }

        // Normalize URL
        var urlString = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid server URL"
            return
        }

        do {
            try await SubsonicClient.shared.configure(
                url: url,
                username: username,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview
#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif

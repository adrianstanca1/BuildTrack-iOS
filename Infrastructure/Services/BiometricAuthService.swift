import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - Biometric Auth Service

protocol BiometricAuthProtocol {
    var isAvailable: Bool { get }
    var biometricType: LABiometryType { get }
    func authenticate(reason: String) async throws -> Bool
    func evaluatePolicy(_ policy: LAPolicy, reason: String) async throws -> Bool
}

final class BiometricAuthService: BiometricAuthProtocol {
    private let context = LAContext()
    private var lastError: Error?
    
    var isAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometricType: LABiometryType {
        _ = isAvailable
        return context.biometryType
    }
    
    var biometricTypeDescription: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    func authenticate(reason: String) async throws -> Bool {
        return try await evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, reason: reason)
    }
    
    func evaluatePolicy(_ policy: LAPolicy, reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            lastError = nil
            return success
        } catch {
            lastError = error
            throw BiometricAuthError(from: error)
        }
    }
}

// MARK: - Biometric Auth Errors

enum BiometricAuthError: Error, LocalizedError {
    case notAvailable
    case notEnrolled
    case invalidContext
    case userCancelled
    case systemCancel
    case failed
    case lockout
    case unknown
    
    init(from error: Error) {
        let nsError = error as NSError
        switch nsError.code {
        case LAError.biometryNotAvailable.rawValue:
            self = .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            self = .notEnrolled
        case LAError.invalidContext.rawValue:
            self = .invalidContext
        case LAError.userCancel.rawValue:
            self = .userCancelled
        case LAError.systemCancel.rawValue:
            self = .systemCancel
        case LAError.authenticationFailed.rawValue:
            self = .failed
        case LAError.biometryLockout.rawValue:
            self = .lockout
        default:
            self = .unknown
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric credentials are enrolled"
        case .invalidContext:
            return "Invalid authentication context"
        case .userCancelled:
            return "Authentication was cancelled by user"
        case .systemCancel:
            return "Authentication was cancelled by system"
        case .failed:
            return "Biometric authentication failed"
        case .lockout:
            return "Biometric authentication is locked out"
        case .unknown:
            return "An unknown authentication error occurred"
        }
    }
}

// MARK: - ViewModel for Security Settings

@Observable
final class SecuritySettingsViewModel {
    private let biometricService = BiometricAuthService()
    private let userDefaults = UserDefaults.standard
    
    var isBiometricEnabled: Bool {
        get { userDefaults.bool(forKey: "biometric_auth_enabled") }
        set {
            userDefaults.set(newValue, forKey: "biometric_auth_enabled")
            if newValue {
                userDefaults.set(biometricService.biometricType.rawValue, forKey: "biometric_type")
            }
        }
    }
    
    var isBiometricAvailable: Bool {
        biometricService.isAvailable
    }
    
    var biometricTypeDescription: String {
        biometricService.biometricTypeDescription
    }
    
    func toggleBiometric() async -> Result<Bool, BiometricAuthError> {
        if isBiometricEnabled {
            // Turning off — no auth needed
            isBiometricEnabled = false
            return .success(false)
        } else {
            // Turning on — require biometric auth to enable
            do {
                let success = try await biometricService.authenticate(
                    reason: "Enable \(biometricTypeDescription) for BuildTrack"
                )
                if success {
                    isBiometricEnabled = true
                }
                return .success(success)
            } catch let error as BiometricAuthError {
                return .failure(error)
            } catch {
                return .failure(.unknown)
            }
        }
    }
    
    func authenticateAppLaunch() async -> Bool {
        guard isBiometricEnabled else { return true }
        guard isBiometricAvailable else {
            isBiometricEnabled = false
            return true
        }
        
        do {
            return try await biometricService.authenticate(
                reason: "Unlock BuildTrack"
            )
        } catch {
            return false
        }
    }
}

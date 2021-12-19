//
//  UserViewModel.swift
//  SwiftUI+Combine+MVVM-Lite
//
//  Created by Alexander Sobolev on 19.12.2021.
//

import Foundation
import Combine
import Navajo_Swift

class UserViewModel: ObservableObject {
   // input
    @Published var userName = ""
    @Published var passWord = ""
    @Published var passWordAgain = ""
    
   // output
    @Published var userNameMessage = ""
    @Published var passWordMessage = ""
    @Published var isValid = false

    private var cancellableSet: Set<AnyCancellable> = []
    
    private var isUsernameValidPublisher: AnyPublisher<Bool, Never> {
      $userName
        .debounce(for: 0.8, scheduler: RunLoop.main)
        .removeDuplicates()
        .map { input in
          return input.count >= 3
        }
        .eraseToAnyPublisher()
    }
    
    private var isPasswordEmptyPublisher: AnyPublisher<Bool, Never> {
      $passWord
        .debounce(for: 0.8, scheduler: RunLoop.main)
        .removeDuplicates()
        .map { password in
          return password == ""
        }
        .eraseToAnyPublisher()
    }

    private var arePasswordsEqualPublisher: AnyPublisher<Bool, Never> {
      Publishers.CombineLatest($passWord, $passWordAgain)
        .debounce(for: 0.2, scheduler: RunLoop.main)
        .map { password, passwordAgain in
          return password == passwordAgain
        }
        .eraseToAnyPublisher()
    }
    
    private var passwordStrengthPublisher: AnyPublisher<PasswordStrength, Never> {
      $passWord
        .debounce(for: 0.2, scheduler: RunLoop.main)
        .removeDuplicates()
        .map { input in
          return Navajo.strength(ofPassword: input)
        }
        .eraseToAnyPublisher()
    }
    
    private var isPasswordStrongEnoughPublisher: AnyPublisher<Bool, Never> {
      passwordStrengthPublisher
        .map { strength in
          print(Navajo.localizedString(forStrength: strength))
          switch strength {
          case .reasonable, .strong, .veryStrong:
            return true
          default:
            return false
          }
        }
        .eraseToAnyPublisher()
    }
    
    enum PasswordCheck {
      case valid
      case empty
      case noMatch
      case notStrongEnough
    }
    
    private var isPasswordValidPublisher: AnyPublisher<PasswordCheck, Never> {
      Publishers.CombineLatest3(isPasswordEmptyPublisher, arePasswordsEqualPublisher, isPasswordStrongEnoughPublisher)
        .map { passwordIsEmpty, passwordsAreEqual, passwordIsStrongEnough in
          if (passwordIsEmpty) {
            return .empty
          }
          else if (!passwordsAreEqual) {
            return .noMatch
          }
          else if (!passwordIsStrongEnough) {
            return .notStrongEnough
          }
          else {
            return .valid
          }
        }
        .eraseToAnyPublisher()
    }
    
    private var isFormValidPublisher: AnyPublisher<Bool, Never> {
      Publishers.CombineLatest(isUsernameValidPublisher, isPasswordValidPublisher)
        .map { userNameIsValid, passwordIsValid in
          return userNameIsValid && (passwordIsValid == .valid)
        }
      .eraseToAnyPublisher()
    }
    
    init() {
      isUsernameValidPublisher
        .receive(on: RunLoop.main)
        .map { valid in
          valid ? "" : "User name must at least have 3 characters"
        }
        .assign(to: \.userNameMessage, on: self)
        .store(in: &cancellableSet)
      
      isPasswordValidPublisher
        .receive(on: RunLoop.main)
        .map { passwordCheck in
          switch passwordCheck {
          case .empty:
            return "Password must not be empty"
          case .noMatch:
            return "Passwords don't match"
          case .notStrongEnough:
            return "Password not strong enough"
          default:
            return ""
          }
        }
        .assign(to: \.passWordMessage, on: self)
        .store(in: &cancellableSet)

      isFormValidPublisher
        .receive(on: RunLoop.main)
        .assign(to: \.isValid, on: self)
        .store(in: &cancellableSet)
    }

}


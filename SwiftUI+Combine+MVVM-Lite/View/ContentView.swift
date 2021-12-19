//
//  ContentView.swift
//  SwiftUI+Combine+MVVM-Lite
//
//  Created by Alexander Sobolev on 19.12.2021.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var userViewModel = UserViewModel()
    @State var presentAlert = false
    
    var body: some View {
      Form {
        Section(footer: Text(userViewModel.userNameMessage).foregroundColor(.red)) {
          TextField("Username", text: $userViewModel.userName)
            .autocapitalization(.none)
        }
        Section(footer: Text(userViewModel.passWordMessage).foregroundColor(.red)) {
          SecureField("Password", text: $userViewModel.passWord)
          SecureField("Password again", text: $userViewModel.passWordAgain)
        }
        Section {
          Button(action: { self.signUp() }) {
            Text("Sign up")
          }.disabled(!self.userViewModel.isValid)
        }
      }
      .sheet(isPresented: $presentAlert) {
        WelcomeView()
      }
    }
    
    func signUp() {
      self.presentAlert = true
    }
  }

  struct WelcomeView: View {
    var body: some View {
      Text("Welcome! Great to have you on board!")
    }
  }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

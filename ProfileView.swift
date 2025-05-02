//
//  ProfileView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("projectNumber") private var projectNumber = ""
    @AppStorage("phoneNumber") private var phoneNumber = ""
    @AppStorage("email") private var email = ""
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $userName)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section(header: Text("Project Information")) {
                TextField("Project Number", text: $projectNumber)
            }
        }
        .navigationTitle("Profile")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}

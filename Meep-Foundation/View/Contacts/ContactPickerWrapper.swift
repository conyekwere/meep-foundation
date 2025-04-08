//
//  ContactPickerWrapper.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/23/25.
//


import SwiftUI
import Contacts
import ContactsUI

struct ContactPickerWrapper: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedContact: CNContact?
    var onContactSelected: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = CNContactPickerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerWrapper
        
        init(_ parent: ContactPickerWrapper) {
            self.parent = parent
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.selectedContact = contact
            parent.onContactSelected(contact)
            parent.isPresented = false
        }
    }
}

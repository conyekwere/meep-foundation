//
//  DatePickerTransitSheet.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/17/25.
//
import SwiftUI

struct DatePickerTransitSheet: View {
    @Binding var startDate: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            DatePicker(
                "Select Time",
                selection: $startDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .padding()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.black)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                Button("Done") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .presentationDetents([.fraction(0.4)]) // Limits overlay size
    }
}

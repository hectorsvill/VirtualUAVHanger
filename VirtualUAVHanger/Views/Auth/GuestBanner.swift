//
//  GuestBanner.swift
//  VirtualUAVHanger
//
//  Persistent amber banner shown at the top of the app whenever the user
//  is browsing as a guest. Tapping "Sign In" opens the upgrade-flow sheet
//  so they can link a real account without losing their hangar data.
//

import SwiftUI

struct GuestBanner: View {
    let onSignInTapped: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.0))

            Text("Browsing as guest · Data is local only")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color(red: 0.5, green: 0.33, blue: 0.0))
                .lineLimit(1)

            Spacer()

            Button(action: onSignInTapped) {
                Text("Sign In")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.75, green: 0.5, blue: 0.0))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 1.0, green: 0.93, blue: 0.72))
        .overlay(alignment: .bottom) {
            Divider().opacity(0.4)
        }
    }
}

#Preview {
    VStack {
        GuestBanner { }
        Spacer()
    }
}

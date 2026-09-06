//
//  ContentView.swift
//  RideSelect
//

import SwiftUI

/// Root container: the clean home screen, swapped for the tab shell once a comparison starts.
struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            switch model.phase {
            case .home:
                HomeView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            case .comparing:
                AppShellView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .environment(model)
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: model.phase)
    }
}

#Preview {
    ContentView()
}

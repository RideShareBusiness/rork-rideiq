//
//  ScanningView.swift
//  RideSelect
//

import SwiftUI

/// Brief premium "checking providers" state shown while mock quotes are prepared.
struct ScanningView: View {
    @State private var activeIndex: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let providers = RideProvider.allCases

    var body: some View {
        VStack(spacing: 28) {
            ForEach(Array(providers.enumerated()), id: \.element.id) { index, provider in
                HStack(spacing: 16) {
                    ProviderMark(provider: provider, size: 26)
                        .opacity(index <= activeIndex ? 1 : 0.35)
                    Text(provider.displayName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(index <= activeIndex ? Palette.primaryText : Palette.tertiaryText)
                    Spacer(minLength: 0)
                    if index < activeIndex {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.gold)
                            .transition(.scale.combined(with: .opacity))
                    } else if index == activeIndex {
                        ProgressView()
                            .tint(Palette.gold)
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(
                    index == activeIndex ? Palette.surface : .clear,
                    in: .rect(cornerRadius: 16)
                )
            }

            Text("Checking live premium availability…")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .center)
        .task {
            guard !reduceMotion else { return }
            for index in providers.indices {
                try? await Task.sleep(for: .milliseconds(380))
                withAnimation(.snappy) { activeIndex = index }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Comparing premium rides")
    }
}

#Preview {
    ScanningView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas)
}

//
//  HomeView.swift
//  RideSelect
//

import SwiftUI

/// Root entry point: wordmark, promise, route inputs, and the compare action.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var searchTarget: PlaceSearchView.Target?
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.canvas.ignoresSafeArea()

            MapBackdropView()
                .frame(height: 360)
                .frame(maxWidth: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                wordmark
                    .padding(.top, 24)

                Text("Your best ride,\nright now.")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Palette.primaryText)
                    .lineSpacing(-2)
                    .padding(.top, 40)

                Text("Compare premium rides by price, pickup time, and arrival.")
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.secondaryText)
                    .padding(.top, 14)
                    .fixedSize(horizontal: false, vertical: true)

                routeCard
                    .padding(.top, 34)

                Button("Compare Rides") {
                    Task { await model.compareRides() }
                }
                .buttonStyle(IvoryButtonStyle())
                .padding(.top, 20)
                .disabled(!model.canCompare)
                .opacity(model.canCompare ? 1 : 0.45)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
        }
        .sheet(item: $searchTarget) { target in
            PlaceSearchView(target: target)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) { appeared = true }
        }
        .task {
            await model.bootstrapPickup()
        }
    }

    private var wordmark: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Palette.gold, lineWidth: 1.5)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "car.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Palette.gold)
                }
            Text("RideSelect")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(Palette.gold)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RideSelect")
    }

    private var routeCard: some View {
        VStack(spacing: 0) {
            Button {
                searchTarget = .pickup
            } label: {
                routeRow(
                    icon: "mappin.and.ellipse",
                    text: model.pickupTitle,
                    isPlaceholder: false,
                    isBusy: model.isPickupResolving
                )
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99))

            Divider()
                .overlay(Palette.hairline)
                .padding(.leading, 62)

            Button {
                searchTarget = .destination
            } label: {
                routeRow(
                    icon: "magnifyingglass",
                    text: model.hasChosenDestination ? model.route.destination.name : "Where to?",
                    isPlaceholder: !model.hasChosenDestination
                )
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99))
        }
        .panel()
    }

    private func routeRow(
        icon: String,
        text: String,
        isPlaceholder: Bool,
        isBusy: Bool = false
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Palette.gold)
                .frame(width: 26)
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isPlaceholder ? Palette.tertiaryText : Palette.primaryText)
                .lineLimit(1)
            Spacer(minLength: 0)
            if isBusy {
                ProgressView()
                    .controlSize(.small)
                    .tint(Palette.tertiaryText)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 66)
        .contentShape(.rect)
    }
}

#Preview {
    HomeView()
        .environment(AppModel())
}

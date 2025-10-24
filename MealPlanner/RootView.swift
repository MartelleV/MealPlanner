import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }

            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.accentColor)
        .glassContainer()
        .overlay(alignment: .top) {
            if let banner = store.banner {
                BannerView(banner: banner)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .task {
            await store.loadAll()
        }
    }
}

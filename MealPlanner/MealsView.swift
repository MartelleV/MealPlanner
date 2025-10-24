import SwiftUI
import PhotosUI

struct MealsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var showingAdd = false

    var filtered: [Meal] {
        if search.isEmpty { return store.meals }
        return store.meals.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    ContentUnavailableView("No meals yet", systemImage: "fork.knife.circle", description: Text("Tap + to add your first meal."))
                } else {
                    ForEach(filtered) { meal in
                        MealRow(meal: meal)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task { await store.deleteMeal(at: IndexSet(integer: store.meals.firstIndex(of: meal)!)) }
                                } label: { Label("Delete", systemImage: "trash") }
                                Button {
                                    Task {
                                        var updated = meal
                                        updated.isFavorite.toggle()
                                        await store.updateMeal(updated)
                                    }
                                } label: {
                                    Label("Favorite", systemImage: meal.isFavorite ? "heart.slash" : "heart")
                                }.tint(.pink)
                            }
                            .onTapGesture {
                                showingAdd = true
                                MealFormSheet.present(meal: meal, store: store)
                            }
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                        MealFormSheet.present(meal: nil, store: store)
                    } label: { Image(systemName: "plus") }
                }
            }
        }
    }
}

private struct MealRow: View {
    @EnvironmentObject private var store: AppStore
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            MealThumbnail(meal: meal)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.name).font(.headline)
                    if meal.isFavorite { Image(systemName: "heart.fill").foregroundStyle(.pink) }
                }
                Text("\(meal.calories) kcal • \(meal.course.rawValue.capitalized)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiaryLabel)
        }
        .contentShape(Rectangle())
    }
}

private struct MealThumbnail: View {
    @EnvironmentObject private var store: AppStore
    let meal: Meal
    var body: some View {
        if let file = meal.imageFilename {
            let url = store.imageURL(for: file)
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                fallback
            }
        } else {
            fallback
        }
    }
    private var fallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(.thinMaterial)
            Image(systemName: "photo")
        }
    }
}

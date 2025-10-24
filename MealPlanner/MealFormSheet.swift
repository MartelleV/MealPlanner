//
//  MealFormSheet.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//


import SwiftUI
import PhotosUI
import os

enum MealFormSheet {
    static func present(meal: Meal?, store: AppStore) {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        let host = UIHostingController(rootView: MealFormView(existing: meal).environmentObject(store))
        host.modalPresentationStyle = .formSheet
        window?.rootViewController?.present(host, animated: true)
    }
}

struct MealFormView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var existing: Meal?
    @State private var name = ""
    @State private var calories: Double = 400
    @State private var course: MealCourse = .lunch
    @State private var flavors: Set<Flavor> = []
    @State private var allergies: Set<Allergy> = []
    @State private var bestCookedWith = ""
    @State private var bestServedAs = ""
    @State private var isFavorite = false

    @State private var photo: PhotosPickerItem?
    @State private var pickedImageData: Data?

    let logger = Logger(subsystem: "com.example.mealplanner", category: "ui")

    init(existing: Meal?) {
        self.existing = existing
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Calories")
                        Spacer()
                        Text("\(Int(calories)) kcal").foregroundStyle(.secondary)
                    }
                    Slider(value: $calories, in: 50...1500, step: 10)
                    Picker("Course", selection: $course) {
                        ForEach(MealCourse.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Taste & allergies") {
                    FlowWrap(Flavor.self, selection: $flavors) { Text($0.rawValue.capitalized) }
                    FlowWrap(Allergy.self, selection: $allergies) { Text($0.rawValue.capitalized) }
                }

                Section("Tips") {
                    TextField("Best cooked with", text: $bestCookedWith)
                    TextField("Best served as", text: $bestServedAs)
                }

                Section("Photo") {
                    PhotosPicker(selection: $photo, matching: .images, photoLibrary: .shared()) {
                        HStack { Image(systemName: "photo"); Text("Select photo") }
                    }
                    .onChange(of: photo) { _, newValue in
                        guard let newValue else { return }
                        Task {
                            do {
                                if let data = try await newValue.loadTransferable(type: Data.self) {
                                    pickedImageData = data
                                }
                            } catch {
                                logger.error("Photo load failed: \(error.localizedDescription, privacy: .public)")
                            }
                        }
                    }
                    if let data = pickedImageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill().frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if let existing, let file = existing.imageFilename {
                        let url = store.imageURL(for: file)
                        if let ui = UIImage(contentsOfFile: url.path) {
                            Image(uiImage: ui).resizable().scaledToFill().frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Meal" : "Edit Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { Task { await save() } } }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let m = existing else { return }
        name = m.name
        calories = Double(m.calories)
        course = m.course
        flavors = Set(m.flavors)
        allergies = Set(m.allergies)
        bestCookedWith = m.bestCookedWith
        bestServedAs = m.bestServedAs
        isFavorite = m.isFavorite
    }

    private func save() async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var imageFilename: String? = existing?.imageFilename

        if let data = pickedImageData {
            imageFilename = await store.saveImageData(data)
        }

        let built = Meal(
            id: existing?.id ?? UUID(),
            name: name,
            calories: Int(calories),
            course: course,
            flavors: Array(flavors),
            allergies: Array(allergies),
            bestCookedWith: bestCookedWith,
            bestServedAs: bestServedAs,
            imageFilename: imageFilename,
            isFavorite: isFavorite
        )

        if existing != nil { await store.updateMeal(built) }
        else { await store.addMeal(built) }
        dismiss()
    }
}

// MARK: - FlowWrap (chip selector) + FlowRows layout

/// A simple chips selector for any CaseIterable + Identifiable + Hashable enum.
struct FlowWrap<T: CaseIterable & Identifiable & Hashable, Label: View>: View where T.AllCases: RandomAccessCollection {
    private let options: [T]
    @Binding var selection: Set<T>
    let label: (T) -> Label

    init(_ type: T.Type = T.self, selection: Binding<Set<T>>, @ViewBuilder label: @escaping (T) -> Label) {
        self.options = Array(T.allCases)
        self._selection = selection
        self.label = label
    }

    var body: some View {
        FlowRows(spacing: 8) {
            ForEach(options, id: \.id) { item in      // 👈 force the collection initializer
                let isOn = selection.contains(item)
                Button {
                    if isOn { selection.remove(item) } else { selection.insert(item) }
                } label: {
                    label(item)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {                       // 👈 closure bg = no ShapeStyle mismatch
                            Capsule().fill(isOn ? AnyShapeStyle(Color.accentColor.opacity(0.2)) : AnyShapeStyle(.thinMaterial))
                        }
                }
            }
        }
    }
}

/// Public `Layout`-based flow that wraps chips onto new lines (iOS 16+).
struct FlowRows: Layout {
    var spacing: CGFloat = 8

    init(spacing: CGFloat = 8) { self.spacing = spacing }

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {     // wrap
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        y += rowHeight
        return CGSize(width: proposal.width ?? x, height: y)
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {     // wrap
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                      proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

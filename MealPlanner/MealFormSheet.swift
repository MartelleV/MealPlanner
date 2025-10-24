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
                    FlowWrap(Flavor.allCases, selection: $flavors) { Text($0.rawValue.capitalized) }
                    FlowWrap(Allergy.allCases, selection: $allergies) { Text($0.rawValue.capitalized) }
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

// MARK: - FlowWrap (chip selector)

struct FlowWrap<T: Identifiable & Hashable, Label: View>: View where T: CaseIterable, T.AllCases: RandomAccessCollection {
    let all: T.AllCases = T.allCases
    @Binding var selection: Set<T>
    let label: (T) -> Label

    init(_ type: T.Type = T.self, selection: Binding<Set<T>>, @ViewBuilder label: @escaping (T) -> Label) {
        self._selection = selection
        self.label = label
    }

    var body: some View {
        WrapLayout(alignment: .leading, spacing: 8) {
            ForEach(all, id: \.self) { item in
                let isOn = selection.contains(item)
                Button {
                    if isOn { selection.remove(item) } else { selection.insert(item) }
                } label: {
                    label(item)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(isOn ? Color.accentColor.opacity(0.2) : .thinMaterial, in: Capsule())
                }
            }
        }
    }
}

struct WrapLayout<Content: View>: View {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        FlowLayout(spacing: spacing, content: content)
    }
}

struct FlowLayout<Content: View>: View {
    var spacing: CGFloat = 8
    let content: () -> Content
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    var body: some View {
        _VariadicView.Tree(FlowLayoutRoot(spacing: spacing), content: content)
    }

    struct FlowLayoutRoot: _VariadicView_MultiViewRoot {
        var spacing: CGFloat
        func body(children: _VariadicView.Children) -> some View {
            GeometryReader { proxy in
                var x: CGFloat = 0
                var y: CGFloat = 0
                ZStack(alignment: .topLeading) {
                    ForEach(children) { child in
                        child
                            .alignmentGuide(.leading) { _ in
                                if x + child.sizeThatFits(.unspecified).width > proxy.size.width {
                                    x = 0; y -= child.sizeThatFits(.unspecified).height + spacing
                                }
                                let result = x
                                x += child.sizeThatFits(.unspecified).width + spacing
                                return result
                            }
                            .alignmentGuide(.top) { _ in
                                let result = y
                                return result
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: -y + 44)
            }
        }
    }
}

//
//  MealFormSheet.swift
//  MealPlanner
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

    init(existing: Meal?) { self.existing = existing }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    // Photo
                    PhotoSection(photo: $photo, pickedImageData: $pickedImageData, existing: existing, course: course)
                    
                    // Basics
                    FormCard(title: "Basics") {
                        FormField(label: "Name") {
                            TextField("Meal name", text: $name)
                                .font(AppFont.body(16))
                        }
                        
                        ThinDivider()
                        
                        FormField(label: "Calories") {
                            HStack {
                                Slider(value: $calories, in: 50...1500, step: 10)
                                    .tint(.brandPrimary)
                                Text("\(Int(calories))")
                                    .font(AppFont.mono(16, weight: .semibold))
                                    .foregroundStyle(.textPrimary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                        }
                        
                        ThinDivider()
                        
                        FormField(label: "Course") {
                            HStack(spacing: Spacing.sm) {
                                ForEach(MealCourse.allCases) { c in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { course = c }
                                    } label: {
                                        Text(c.emoji)
                                            .font(.system(size: 22))
                                            .frame(width: 44, height: 44)
                                            .background {
                                                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                                    .fill(course == c ? c.accentColor.opacity(0.15) : .clear)
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                                            .stroke(course == c ? c.accentColor : Color.border, lineWidth: course == c ? 2 : 0.5)
                                                    }
                                            }
                                    }
                                    .buttonStyle(BouncyButtonStyle())
                                }
                            }
                        }
                        
                        ThinDivider()
                        
                        Toggle(isOn: $isFavorite) {
                            Text("Favorite")
                                .font(AppFont.body(15))
                                .foregroundStyle(.textPrimary)
                        }
                        .tint(.brandSecondary)
                        .padding(.vertical, Spacing.xs)
                    }
                    
                    // Taste
                    FormCard(title: "Taste & Allergies") {
                        FormField(label: "Flavors") {
                            FlowRows(spacing: Spacing.sm) {
                                ForEach(Flavor.allCases) { flavor in
                                    ChipButton(
                                        title: flavor.rawValue.capitalized,
                                        isSelected: flavors.contains(flavor),
                                        color: .brandAccent
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if flavors.contains(flavor) { flavors.remove(flavor) }
                                            else { flavors.insert(flavor) }
                                        }
                                    }
                                }
                            }
                        }
                        
                        ThinDivider()
                        
                        FormField(label: "Contains") {
                            FlowRows(spacing: Spacing.sm) {
                                ForEach(Allergy.allCases) { allergy in
                                    ChipButton(
                                        title: allergy.rawValue.capitalized,
                                        isSelected: allergies.contains(allergy),
                                        color: .brandSecondary
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if allergies.contains(allergy) { allergies.remove(allergy) }
                                            else { allergies.insert(allergy) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Tips
                    FormCard(title: "Tips") {
                        FormField(label: "Best cooked with") {
                            TextField("e.g., olive oil, garlic", text: $bestCookedWith)
                                .font(AppFont.body(15))
                        }
                        
                        ThinDivider()
                        
                        FormField(label: "Best served as") {
                            TextField("e.g., main course", text: $bestServedAs)
                                .font(AppFont.body(15))
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.surfaceBase)
            .navigationTitle(existing == nil ? "Add Meal" : "Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(AppFont.body(15))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .font(AppFont.body(15, weight: .semibold))
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let m = existing else { return }
        name = m.name; calories = Double(m.calories); course = m.course
        flavors = Set(m.flavors); allergies = Set(m.allergies)
        bestCookedWith = m.bestCookedWith; bestServedAs = m.bestServedAs; isFavorite = m.isFavorite
    }

    private func save() async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var imageFilename: String? = existing?.imageFilename
        if let data = pickedImageData { imageFilename = await store.saveImageData(data) }

        let built = Meal(
            id: existing?.id ?? UUID(), name: name, calories: Int(calories), course: course,
            flavors: Array(flavors), allergies: Array(allergies),
            bestCookedWith: bestCookedWith, bestServedAs: bestServedAs,
            imageFilename: imageFilename, isFavorite: isFavorite
        )

        if existing != nil { await store.updateMeal(built) }
        else { await store.addMeal(built) }
        dismiss()
    }
}

// MARK: - Components

private struct FormCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(AppFont.header(18))
                    .foregroundStyle(.textPrimary)
                Spacer()
            }
            .padding(Spacing.md)
            
            ThinDivider()
            
            VStack(spacing: 0) { content }
                .padding(Spacing.md)
        }
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                        .stroke(Color.border, lineWidth: 0.5)
                }
        }
    }
}

private struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(AppFont.caption(13, weight: .medium))
                .foregroundStyle(.textTertiary)
            content
        }
        .padding(.vertical, Spacing.xs)
    }
}

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.body(13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background {
                    Capsule()
                        .fill(isSelected ? color : .white)
                        .overlay {
                            if !isSelected { Capsule().stroke(Color.border, lineWidth: 0.5) }
                        }
                }
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

private struct PhotoSection: View {
    @EnvironmentObject private var store: AppStore
    @Binding var photo: PhotosPickerItem?
    @Binding var pickedImageData: Data?
    var existing: Meal?
    var course: MealCourse
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let data = pickedImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            } else if let existing, let file = existing.imageFilename,
                      let ui = UIImage(contentsOfFile: store.imageURL(for: file).path) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(course.accentColor.opacity(0.1))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: Spacing.sm) {
                            Text(course.emoji).font(.system(size: 40))
                            Text("Add photo").font(AppFont.body(14)).foregroundStyle(.textTertiary)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                            .stroke(Color.border, lineWidth: 0.5)
                    }
            }
            
            PhotosPicker(selection: $photo, matching: .images) {
                Image(systemName: "camera")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.brandPrimary))
            }
            .padding(Spacing.md)
            .onChange(of: photo) { _, newValue in
                guard let newValue else { return }
                Task { if let data = try? await newValue.loadTransferable(type: Data.self) { pickedImageData = data } }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowWrap<T: CaseIterable & Identifiable & Hashable, Label: View>: View where T.AllCases: RandomAccessCollection {
    private let options: [T]
    @Binding var selection: Set<T>
    let label: (T) -> Label

    init(_ type: T.Type = T.self, selection: Binding<Set<T>>, @ViewBuilder label: @escaping (T) -> Label) {
        self.options = Array(T.allCases); self._selection = selection; self.label = label
    }

    var body: some View {
        FlowRows(spacing: 8) {
            ForEach(options, id: \.id) { item in
                let isOn = selection.contains(item)
                Button {
                    if isOn { selection.remove(item) } else { selection.insert(item) }
                } label: {
                    label(item).padding(.horizontal, 12).padding(.vertical, 8)
                        .background { Capsule().fill(isOn ? AnyShapeStyle(Color.accentColor.opacity(0.2)) : AnyShapeStyle(.thinMaterial)) }
                }
            }
        }
    }
}

struct FlowRows: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
    }
}

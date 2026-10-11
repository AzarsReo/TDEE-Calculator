//
//  NutrientsView.swift
//  TDEEArch
//
//  Created by Azariah on 8/29/26.
//

import SwiftUI

private struct MacroPreset: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let protein: Double
    let carbs: Double
    let fat: Double
}

private struct Micro {
    let name: String
    let target: String
    let sources: String
    let color: Color
}

struct NutrientsView: View {
    @AppStorage("savedTDEE")    private var savedTDEE: Double = 0
    @AppStorage("latestWeight") private var latestWeight: Double = 0
    @State private var selectedPreset = 0
    @State private var expandedMicro: String?
    @State private var microSectionExpanded = false

    private let purple    = Color(red: 0.55, green: 0.18, blue: 0.85)
    private let darkGrey  = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let midGrey   = Color(red: 0.22, green: 0.22, blue: 0.25)
    private let lightGrey = Color(red: 0.65, green: 0.65, blue: 0.68)

    private let proteinColor = Color(red: 0.35, green: 0.65, blue: 1.00)
    private let carbColor    = Color(red: 0.95, green: 0.75, blue: 0.20)
    private let fatColor     = Color(red: 0.95, green: 0.45, blue: 0.30)

    private let presets: [MacroPreset] = [
        MacroPreset(
            name: "Protein-First Cut",
            detail: "Nearly half your calories from protein — maximizes muscle retention in a deficit. Fat stays moderate to protect hormones; carbs are the lever pulled down.",
            protein: 0.45, carbs: 0.25, fat: 0.30
        ),
        MacroPreset(
            name: "Muscle-Sparing Deficit",
            detail: "Slightly more carbs than a strict cut to fuel training sessions while still running a deficit. Good middle ground for lifters who can't drop carbs too low.",
            protein: 0.40, carbs: 0.30, fat: 0.30
        ),
        MacroPreset(
            name: "Body Recomposition",
            detail: "Protein stays high to build muscle; carbs and fat split evenly to fuel both training and recovery. Best used at or near maintenance calories.",
            protein: 0.35, carbs: 0.35, fat: 0.30
        ),
        MacroPreset(
            name: "Balanced Maintenance",
            detail: "A sustainable everyday split. No macro is dominant — suits most people maintaining weight or transitioning between phases.",
            protein: 0.30, carbs: 0.40, fat: 0.30
        ),
        MacroPreset(
            name: "Carb-Fueled Bulk",
            detail: "Carbohydrates drive training volume and glycogen recovery. Fat is trimmed to make room; protein remains sufficient for muscle protein synthesis.",
            protein: 0.25, carbs: 0.55, fat: 0.20
        ),
        MacroPreset(
            name: "Carb-Loaded Performance",
            detail: "Maximum carbohydrate availability for sustained aerobic output. Used by endurance athletes — runners, cyclists, triathletes — especially pre-race.",
            protein: 0.15, carbs: 0.65, fat: 0.20
        ),
        MacroPreset(
            name: "High Fat Low Carb",
            detail: "Fat is the dominant fuel source without going fully ketogenic. Suits people who feel better on lower carbs but want more dietary flexibility than strict keto.",
            protein: 0.30, carbs: 0.15, fat: 0.55
        ),
        MacroPreset(
            name: "Ketogenic / Fat-Adapted",
            detail: "Carbs are near-eliminated to drive ketosis. Fat provides 75% of calories; the body shifts from glucose to ketones as its primary fuel.",
            protein: 0.20, carbs: 0.05, fat: 0.75
        ),
        MacroPreset(
            name: "Mediterranean",
            detail: "Emphasizes healthy unsaturated fats (olive oil, nuts, fish) alongside moderate carbs. Lower protein than athletic presets; prioritizes diet quality over optimization.",
            protein: 0.20, carbs: 0.45, fat: 0.35
        ),
    ]

    private let micros: [Micro] = [
        Micro(name: "Fiber",       target: "25–38g",      sources: "Oats, beans, vegetables, whole grains",          color: Color(red: 0.35, green: 0.80, blue: 0.45)),
        Micro(name: "Vitamin D",   target: "600–800 IU",  sources: "Fatty fish, egg yolks, fortified milk, sunlight", color: Color(red: 0.95, green: 0.75, blue: 0.20)),
        Micro(name: "Calcium",     target: "1,000mg",     sources: "Dairy, leafy greens, fortified plant milks",      color: Color(red: 0.55, green: 0.75, blue: 0.95)),
        Micro(name: "Iron",        target: "8–18mg",      sources: "Red meat, lentils, spinach, fortified cereals",   color: Color(red: 0.90, green: 0.35, blue: 0.35)),
        Micro(name: "Potassium",   target: "3,500mg",     sources: "Bananas, potatoes, avocado, salmon",              color: Color(red: 0.95, green: 0.55, blue: 0.20)),
        Micro(name: "Magnesium",   target: "310–420mg",   sources: "Nuts, seeds, dark chocolate, whole grains",       color: Color(red: 0.65, green: 0.45, blue: 0.95)),
        Micro(name: "Vitamin C",   target: "65–90mg",     sources: "Citrus fruits, bell peppers, broccoli",           color: Color(red: 0.95, green: 0.45, blue: 0.20)),
        Micro(name: "Zinc",        target: "8–11mg",      sources: "Meat, shellfish, legumes, pumpkin seeds",         color: Color(red: 0.35, green: 0.65, blue: 0.65)),
        Micro(name: "Vitamin B12", target: "2.4mcg",      sources: "Meat, fish, eggs, dairy, fortified foods",        color: Color(red: 0.75, green: 0.35, blue: 0.85)),
        Micro(name: "Omega-3",     target: "1.1–1.6g",    sources: "Fatty fish, flaxseed, walnuts, chia seeds",       color: Color(red: 0.35, green: 0.65, blue: 1.00)),
    ]

    private var calories: Double { savedTDEE > 0 ? savedTDEE : 2000 }
    private var preset: MacroPreset { presets[selectedPreset] }

    private var proteinG: Int { Int((calories * preset.protein / 4).rounded()) }
    private var carbsG:   Int { Int((calories * preset.carbs   / 4).rounded()) }
    private var fatG:     Int { Int((calories * preset.fat     / 9).rounded()) }

    // g/lb tagline — uses TDEE + logged weight; falls back to % string if either is missing
    private func tagline(for p: MacroPreset) -> String {
        guard savedTDEE > 0, latestWeight > 0 else {
            return "\(Int(p.protein * 100))P · \(Int(p.carbs * 100))C · \(Int(p.fat * 100))F"
        }
        let pG = (savedTDEE * p.protein / 4) / latestWeight
        let cG = (savedTDEE * p.carbs   / 4) / latestWeight
        let fG = (savedTDEE * p.fat     / 9) / latestWeight
        return String(format: "%.2fg/lb P  ·  %.2fg/lb C  ·  %.2fg/lb F", pG, cG, fG)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    if savedTDEE > 0 { calorieBanner }
                    presetSection
                    macroBreakdownSection
                    microSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .topTrailing) { trademark }
    }

    private var trademark: some View {
        Text("@AzarArch")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color(red: 0.55, green: 0.18, blue: 0.85).opacity(0.7))
            .padding(.top, 56)
            .padding(.trailing, 20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Macro & Micro Targets")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Nutrient breakdown based on your TDEE")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(lightGrey)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calorie Banner

    private var calorieBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Based on your TDEE")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(lightGrey)
                Text("\(Int(savedTDEE.rounded())) kcal / day")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .foregroundColor(purple)
                .font(.system(size: 22))
        }
        .padding(16)
        .background(purple.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(purple.opacity(0.4), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Preset Picker

    private var presetSection: some View {
        VStack(spacing: 16) {
            sectionLabel("Diet Approach")
            cardView {
                VStack(spacing: 4) {
                    ForEach(presets.indices, id: \.self) { i in
                        let p = presets[i]
                        Button { selectedPreset = i } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(selectedPreset == i ? purple : midGrey, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    if selectedPreset == i {
                                        Circle().fill(purple).frame(width: 12, height: 12)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text(p.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(selectedPreset == i ? .white : lightGrey)
                                        Text(tagline(for: p))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(selectedPreset == i ? purple : Color(white: 0.35))
                                    }
                                    if selectedPreset == i {
                                        Text(p.detail)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(white: 0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.top, 2)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(selectedPreset == i ? purple.opacity(0.15) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Macro Breakdown

    private var macroBreakdownSection: some View {
        VStack(spacing: 16) {
            sectionLabel("Macro Breakdown")
            cardView {
                VStack(spacing: 16) {
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            Rectangle().fill(proteinColor)
                                .frame(width: geo.size.width * preset.protein)
                            Rectangle().fill(carbColor)
                                .frame(width: geo.size.width * preset.carbs)
                            Rectangle().fill(fatColor)
                        }
                        .frame(height: 10)
                        .clipShape(Capsule())
                    }
                    .frame(height: 10)

                    macroRow(label: "Protein",       grams: proteinG, pct: Int((preset.protein * 100).rounded()), cals: proteinG * 4, color: proteinColor)
                    Rectangle().fill(Color(white: 0.18)).frame(height: 1)
                    macroRow(label: "Carbohydrates", grams: carbsG,   pct: Int((preset.carbs   * 100).rounded()), cals: carbsG   * 4, color: carbColor)
                    Rectangle().fill(Color(white: 0.18)).frame(height: 1)
                    macroRow(label: "Fat",           grams: fatG,     pct: Int((preset.fat      * 100).rounded()), cals: fatG    * 9, color: fatColor)
                }
            }
        }
    }

    private func macroRow(label: String, grams: Int, pct: Int, cals: Int, color: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(grams)g")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("\(pct)%  ·  \(cals) kcal")
                    .font(.system(size: 11))
                    .foregroundColor(lightGrey)
            }
        }
    }

    // MARK: - Micronutrients

    private var microSection: some View {
        VStack(spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    microSectionExpanded.toggle()
                }
            } label: {
                HStack {
                    sectionLabel("Key Micronutrients")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(purple)
                        .rotationEffect(.degrees(microSectionExpanded ? 180 : 0))
                }
            }

            if microSectionExpanded {
                VStack(spacing: 10) {
                    ForEach(micros, id: \.name) { micro in
                        microRow(micro)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func microRow(_ micro: Micro) -> some View {
        let isExpanded = expandedMicro == micro.name
        return cardView {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedMicro = isExpanded ? nil : micro.name
                    }
                } label: {
                    HStack(spacing: 12) {
                        Capsule()
                            .fill(micro.color)
                            .frame(width: 3, height: 22)
                        Text(micro.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(micro.target)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(micro.color)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(lightGrey)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rich food sources")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(micro.color)
                            .kerning(0.8)
                        Text(micro.sources)
                            .font(.system(size: 12))
                            .foregroundColor(lightGrey)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 12)
                    .padding(.leading, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Shared Helpers

    @ViewBuilder
    private func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(darkGrey)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(purple)
            .kerning(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NutrientsView()
}

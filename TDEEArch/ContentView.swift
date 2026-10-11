//
//  ContentView.swift
//  TDEEArch
//
//  Created by Azariah on 8/29/26.
//

import SwiftUI

enum Sex: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum ActivityLevel: String, CaseIterable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case very = "Very Active"
    case super_ = "Super Active"

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light:     return 1.375
        case .moderate:  return 1.55
        case .very:      return 1.725
        case .super_:    return 1.9
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light:     return "Light exercise 1–3 days/wk"
        case .moderate:  return "Moderate exercise 3–5 days/wk"
        case .very:      return "Hard exercise 6–7 days/wk"
        case .super_:    return "Very hard exercise / physical job"
        }
    }

    var detail: String {
        switch self {
        case .sedentary:
            return "Desk job, minimal walking. You exercise rarely or not at all outside of daily errands."
        case .light:
            return "A few gym sessions or walks per week. Think casual cardio, yoga, or recreational sports 1–3 days."
        case .moderate:
            return "Consistent training 3–5 days/wk — gym lifts, runs, cycling, or classes at moderate intensity."
        case .very:
            return "Daily intense training: heavy lifting, competitive sports, or two-a-days most of the week."
        case .super_:
            return "Athlete-level output or a physically demanding job (construction, farming) combined with regular training."
        }
    }
}

struct ContentView: View {
    @State private var age: String = ""
    @State private var weightLbs: String = ""
    @State private var heightFt: String = ""
    @State private var heightIn: String = ""
    @State private var sex: Sex = .male
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var tdee: Double? = nil
    @State private var bmr: Double? = nil
    @AppStorage("savedTDEE") private var savedTDEE: Double = 0
    @FocusState private var focusedField: Field?

    enum Field { case age, weight, heightFt, heightIn }

    private let purple = Color(red: 0.55, green: 0.18, blue: 0.85)
    private let darkGrey = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let midGrey = Color(red: 0.22, green: 0.22, blue: 0.25)
    private let lightGrey = Color(red: 0.65, green: 0.65, blue: 0.68)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    metricsSection
                    activitySection
                    calculateButton
                    if let tdee, let bmr {
                        resultsSection(tdee: tdee, bmr: bmr)
                    }
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
            Text("TDEE Calculator")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Total Daily Energy Expenditure")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(lightGrey)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(spacing: 16) {
            sectionLabel("Your Metrics")

            // Sex picker
            cardView {
                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Sex")
                    HStack(spacing: 0) {
                        ForEach(Sex.allCases, id: \.self) { option in
                            Button {
                                sex = option
                            } label: {
                                Text(option.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(sex == option ? purple : Color.clear)
                                    .foregroundColor(sex == option ? .white : lightGrey)
                            }
                        }
                    }
                    .background(midGrey)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Age
            cardView {
                metricRow(label: "Age", unit: "yrs", text: $age, field: .age)
            }

            // Weight
            cardView {
                metricRow(label: "Weight", unit: "lbs", text: $weightLbs, field: .weight)
            }

            // Height
            cardView {
                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Height")
                    HStack(spacing: 12) {
                        numericInput(placeholder: "ft", text: $heightFt, field: .heightFt)
                        Text("ft")
                            .foregroundColor(lightGrey)
                            .font(.system(size: 14))
                        numericInput(placeholder: "in", text: $heightIn, field: .heightIn)
                        Text("in")
                            .foregroundColor(lightGrey)
                            .font(.system(size: 14))
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(spacing: 16) {
            sectionLabel("Activity Level")
            cardView {
                VStack(spacing: 4) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Button {
                            activityLevel = level
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(activityLevel == level ? purple : midGrey, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    if activityLevel == level {
                                        Circle()
                                            .fill(purple)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(level.rawValue)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(activityLevel == level ? .white : lightGrey)
                                    Text(level.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(activityLevel == level ? lightGrey : Color(white: 0.4))
                                    if activityLevel == level {
                                        Text(level.detail)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(white: 0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.top, 4)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(activityLevel == level ? purple.opacity(0.15) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Calculate Button

    private var calculateButton: some View {
        Button {
            calculate()
            focusedField = nil
        } label: {
            Text("Calculate TDEE")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [purple, purple.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Results

    private func resultsSection(tdee: Double, bmr: Double) -> some View {
        VStack(spacing: 16) {
            sectionLabel("Your Results")

            // TDEE hero
            cardView {
                VStack(spacing: 6) {
                    Text("TDEE")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(lightGrey)
                    Text("\(Int(tdee.rounded()))")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(purple)
                    Text("calories / day")
                        .font(.system(size: 13))
                        .foregroundColor(lightGrey)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Goal breakdown
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                goalCard(label: "Extreme Cut", deficit: "-1000", calories: tdee - 1000, color: Color(red: 0.95, green: 0.25, blue: 0.25))
                goalCard(label: "Intensive Cut",    deficit: "-750",  calories: tdee - 750,  color: Color(red: 0.95, green: 0.55, blue: 0.20))
                goalCard(label: "Moderate Cut",         deficit: "-500",  calories: tdee - 500,  color: Color(red: 0.95, green: 0.75, blue: 0.20))
                goalCard(label: "Maingain",    deficit: "+100",  calories: tdee + 100,  color: Color(red: 0.35, green: 0.80, blue: 0.65))
                goalCard(label: "Maintain",    deficit: "±0",    calories: tdee,        color: purple)
                goalCard(label: "Bulk",        deficit: "+500",  calories: tdee + 500,  color: Color(red: 0.25, green: 0.75, blue: 0.45))
            }

            // BMR detail
            cardView {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Basal Metabolic Rate")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(lightGrey)
                        Text("Calories burned at complete rest")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.45))
                    }
                    Spacer()
                    Text("\(Int(bmr.rounded())) kcal")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Goal Card

    private func goalCard(label: String, deficit: String, calories: Double, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
            Text("\(Int(calories.rounded()))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("\(deficit) kcal")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(darkGrey)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func metricRow(label: String, unit: String, text: Binding<String>, field: Field) -> some View {
        HStack {
            fieldLabel(label)
            Spacer()
            numericInput(placeholder: "0", text: text, field: field)
            Text(unit)
                .foregroundColor(lightGrey)
                .font(.system(size: 14))
                .frame(width: 28, alignment: .leading)
        }
    }

    private func numericInput(placeholder: String, text: Binding<String>, field: Field) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .focused($focusedField, equals: field)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 64)
            .padding(.vertical, 8)
            .background(midGrey)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(darkGrey)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(purple)
            .kerning(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Calculation (Mifflin-St Jeor)

    private func calculate() {
        guard
            let ageVal = Double(age), ageVal > 0,
            let weightVal = Double(weightLbs), weightVal > 0,
            let ft = Double(heightFt), ft >= 0,
            let inches = Double(heightIn), inches >= 0
        else { return }

        let weightKg = weightVal * 0.453592
        let heightCm = (ft * 12 + inches) * 2.54

        let bmrVal: Double
        switch sex {
        case .male:
            bmrVal = (10 * weightKg) + (6.25 * heightCm) - (5 * ageVal) + 5
        case .female:
            bmrVal = (10 * weightKg) + (6.25 * heightCm) - (5 * ageVal) - 161
        }

        bmr = bmrVal
        let tdeeVal = bmrVal * activityLevel.multiplier
        tdee = tdeeVal
        savedTDEE = tdeeVal
    }
}

#Preview {
    ContentView()
}

//
//  WeightTrackerView.swift
//  TDEEArch
//
//  Created by Azariah on 8/29/26.
//

import SwiftUI
import Charts

struct WeightEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let weight: Double

    init(date: Date, weight: Double) {
        self.id = UUID()
        self.date = date
        self.weight = weight
    }
}

struct WeightTrackerView: View {
    @AppStorage("savedTDEE")    private var savedTDEE: Double = 0
    @AppStorage("latestWeight") private var latestWeight: Double = 0
    @State private var entries: [WeightEntry] = []
    @State private var weightInput: String = ""
    @FocusState private var inputFocused: Bool

    private let purple    = Color(red: 0.55, green: 0.18, blue: 0.85)
    private let darkGrey  = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let midGrey   = Color(red: 0.22, green: 0.22, blue: 0.25)
    private let lightGrey = Color(red: 0.65, green: 0.65, blue: 0.68)
    private let green     = Color(red: 0.35, green: 0.80, blue: 0.45)
    private let orange    = Color(red: 0.95, green: 0.75, blue: 0.20)
    private let red       = Color(red: 0.95, green: 0.45, blue: 0.30)

    private var todayLogged: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.contains { Calendar.current.startOfDay(for: $0.date) == today }
    }

    // Cap display at most recent 30 entries
    private var displayEntries: [WeightEntry] { Array(entries.suffix(30)) }

    private var chartRange: ClosedRange<Double> {
        guard let lo = displayEntries.map(\.weight).min(),
              let hi = displayEntries.map(\.weight).max() else { return 140...200 }
        let pad = max(2.0, (hi - lo) * 0.25)
        return (lo - pad)...(hi + pad)
    }

    // Linear regression trend over displayed entries
    private var trendData: [(date: Date, weight: Double)] {
        guard displayEntries.count >= 3 else { return [] }
        let n  = Double(displayEntries.count)
        let xs = (0..<displayEntries.count).map { Double($0) }
        let ys = displayEntries.map(\.weight)
        let sumX  = xs.reduce(0, +)
        let sumY  = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return [] }
        let slope     = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n
        return displayEntries.enumerated().map { i, e in
            (date: e.date, weight: slope * Double(i) + intercept)
        }
    }

    // Weekly progress using past 7 days of entries
    private var weeklyProgress: (change: Double, days: Int, dailyBalance: Double)? {
        guard entries.count >= 2 else { return nil }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let week = entries.filter { $0.date >= cutoff }
        guard week.count >= 2,
              let first = week.first, let last = week.last else { return nil }
        let days = max(1, Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 1)
        let change = last.weight - first.weight
        let dailyBalance = (change * 3500) / Double(days)
        return (change: change, days: days, dailyBalance: dailyBalance)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    logSection
                    if displayEntries.count >= 2 {
                        graphSection
                    } else {
                        pendingCard
                    }
                    if let p = weeklyProgress {
                        weeklySection(p)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .topTrailing) { trademark }
        .onAppear(perform: loadEntries)
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
            Text("Weight Tracker")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Log your weight every morning")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(lightGrey)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Log Section

    private var logSection: some View {
        VStack(spacing: 16) {
            sectionLabel(todayLogged ? "Today" : "Log Today")
            cardView {
                if todayLogged, let last = entries.last {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Logged this morning")
                                .font(.system(size: 12))
                                .foregroundColor(lightGrey)
                            Text(String(format: "%.1f lbs", last.weight))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(green)
                            .font(.system(size: 30))
                    }
                } else {
                    HStack(spacing: 12) {
                        TextField("0.0", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .focused($inputFocused)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 90)
                            .padding(.vertical, 10)
                            .background(midGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text("lbs")
                            .foregroundColor(lightGrey)
                            .font(.system(size: 15))
                        Spacer()
                        Button(action: logWeight) {
                            Text("Log")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(weightInput.isEmpty ? purple.opacity(0.4) : purple)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(weightInput.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Pending Card

    private var pendingCard: some View {
        cardView {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(purple)
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Keep logging daily")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Your chart appears after 2 entries. Weekly progress unlocks after 7 days of data.")
                        .font(.system(size: 12))
                        .foregroundColor(lightGrey)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Graph

    private var graphSection: some View {
        VStack(spacing: 16) {
            sectionLabel("Weight Over Time")
            cardView {
                VStack(spacing: 12) {
                    Chart {
                        // Shaded area under the line
                        ForEach(displayEntries) { entry in
                            AreaMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.weight)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [purple.opacity(0.3), purple.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        // Actual weight line + points
                        ForEach(displayEntries) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.weight)
                            )
                            .foregroundStyle(purple)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.weight)
                            )
                            .foregroundStyle(purple)
                            .symbolSize(35)
                        }

                        // Dashed trend line
                        ForEach(trendData, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Trend", point.weight)
                            )
                            .foregroundStyle(Color.white.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        }
                    }
                    .chartYScale(domain: chartRange)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: max(1, displayEntries.count / 5))) { _ in
                            AxisGridLine().foregroundStyle(Color(white: 0.15))
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(lightGrey)
                                .font(.system(size: 10))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(Color(white: 0.15))
                            AxisValueLabel()
                                .foregroundStyle(lightGrey)
                                .font(.system(size: 11))
                        }
                    }
                    .frame(height: 210)

                    // Legend
                    HStack(spacing: 20) {
                        legendDot(color: purple, label: "Weight")
                        legendDash(color: Color.white.opacity(0.5), label: "Trend")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Rectangle().fill(color).frame(width: 20, height: 2.5)
            Text(label).font(.system(size: 11)).foregroundColor(lightGrey)
        }
    }

    private func legendDash(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(color).frame(width: 5, height: 1.5)
                }
            }.frame(width: 20)
            Text(label).font(.system(size: 11)).foregroundColor(lightGrey)
        }
    }

    // MARK: - Weekly Progress

    private func weeklySection(_ p: (change: Double, days: Int, dailyBalance: Double)) -> some View {
        VStack(spacing: 16) {
            sectionLabel("Weekly Progress")
            cardView {
                VStack(spacing: 14) {

                    // Change + estimated daily balance
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("7-Day Change")
                                .font(.system(size: 12))
                                .foregroundColor(lightGrey)
                            Text(String(format: "%+.1f lbs", p.change))
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(p.change <= 0 ? green : red)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Est. daily balance")
                                .font(.system(size: 11))
                                .foregroundColor(lightGrey)
                            Text(String(format: "%+.0f kcal", p.dailyBalance))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(p.dailyBalance <= 0 ? green : red)
                            Text("vs maintenance")
                                .font(.system(size: 10))
                                .foregroundColor(Color(white: 0.38))
                        }
                    }

                    Rectangle().fill(Color(white: 0.18)).frame(height: 1)

                    // Maintenance vs estimated intake
                    if savedTDEE > 0 {
                        HStack {
                            infoCell(label: "Maintenance", value: String(format: "%.0f kcal", savedTDEE))
                            Spacer()
                            infoCell(label: "Est. Avg Intake", value: String(format: "%.0f kcal", max(0, savedTDEE + p.dailyBalance)), align: .trailing)
                        }
                        Rectangle().fill(Color(white: 0.18)).frame(height: 1)
                    }

                    // Status badge
                    statusBadge(change: p.change)
                }
            }
        }
    }

    private func infoCell(label: String, value: String, align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(lightGrey)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private func statusBadge(change: Double) -> some View {
        let weeklyRate = abs(change)
        let (icon, message, color): (String, String, Color) = {
            switch (change, weeklyRate) {
            case _ where abs(change) < 0.1:
                return ("equal.circle.fill", "Weight is stable — you're at maintenance.", purple)
            case _ where change < 0 && weeklyRate <= 2.0:
                return ("arrow.down.circle.fill", "Healthy loss rate. You're on track.", green)
            case _ where change < 0 && weeklyRate > 2.0:
                return ("exclamationmark.triangle.fill", "Losing over 2 lbs/wk — consider eating a bit more to protect muscle.", orange)
            case _ where change > 0 && weeklyRate <= 1.0:
                return ("arrow.up.circle.fill", "Gradual gain — on track for a lean bulk.", Color(red: 0.35, green: 0.65, blue: 1.0))
            default:
                return ("exclamationmark.triangle.fill", "Gaining over 1 lb/wk — consider trimming daily calories.", orange)
            }
        }()

        return HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Persistence

    private func logWeight() {
        guard let weight = Double(weightInput), weight > 0 else { return }
        entries.append(WeightEntry(date: Date(), weight: weight))
        entries.sort { $0.date < $1.date }
        saveEntries()
        latestWeight = weight
        weightInput = ""
        inputFocused = false
    }

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: "weightEntries")
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: "weightEntries"),
              let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.date < $1.date }
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
    WeightTrackerView()
}

//
//  ContentView.swift
//  HealthBoxTest
//
//  Created by Ben Gottlieb on 12/25/25.
//

import Suite
import HealthBox

struct ContentView: View {
	@State var data: ExportedHealthKitData?
	@State var isLoading = false
	@State private var startDate = Date.now.addingTimeInterval(.day * -7).midnight
	@State private var endDate = Date.now
	@State private var selectedMetric = HealthMetric.common[0]
	var path: URL { URL.document(named: "exported-\(selectedMetric.name) \(startDate.formatted(date: .abbreviated, time: .omitted))-\(endDate.formatted(date: .abbreviated, time: .omitted)).json") }

	var body: some View {
		VStack {
			if let data {
				Text(data.description)
			}
			
			if isLoading { ProgressView() }
			
			DatePicker("Start", selection: $startDate, displayedComponents: .date)
			DatePicker("End", selection: $endDate, displayedComponents: .date)
			LabeledContent("Metric") {
				Picker("Metric", selection: $selectedMetric) {
					ForEach(HealthMetric.common) { metric in
						Text(metric.name).tag(metric)
					}
				}
			}

			Button("Fetch") {
				isLoading = true
				Task {
					do {
						data = try await HealthDataFetcher.instance.fetch(selectedMetric, start: startDate, end: endDate)
						try data?.saveJSON(to: path, using: .iso8601Encoder)
						print("Fetched \(data?.data.count, default: "--") values for \(selectedMetric.name)")
					} catch {
						print("Failed health import: \(error)")
					}
					isLoading = false
				}
			}
			
			if data != nil {
				ShareLink(item: path)
			}
		}
		.padding()
		.task {
			HealthMetric.setMetricsOfInterest(HealthMetric.common)
//			await HealthBox.instance.setupHealthKitAccess(requiredMetrics: [.stepCount, .heartRate])
			try! await HealthBox.instance.requestAuthorization()
		}
	}
}

#Preview {
	ContentView()
}

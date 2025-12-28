//
//  ContentView.swift
//  HealthBoxTest
//
//  Created by Ben Gottlieb on 12/25/25.
//

import SwiftUI
import HealthBox

struct ContentView: View {
	@State var data: ExportedHealthKitData?
	@State var isLoading = false
	
	var body: some View {
		VStack {
			if let data {
				Text(data.description)
			}
			
			if isLoading { ProgressView() }
			
			Button("Health") {
				isLoading = true
				Task {
					do {
						data = try await HealthHistoryImporter.instance.nextImport(for: .sleep)
					} catch {
						print("Failed health import: \(error)")
					}
					isLoading = false
				}
			}
		}
		.padding()
		.task {
			HealthMetric.setMetricsOfInterest([.stepCount, .heartRate, .sleep])
//			await HealthBox.instance.setupHealthKitAccess(requiredMetrics: [.stepCount, .heartRate])
			try! await HealthBox.instance.requestAuthorization()
		}
	}
}

#Preview {
	ContentView()
}

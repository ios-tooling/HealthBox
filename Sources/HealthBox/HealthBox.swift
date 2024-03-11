//
//  HealthBox.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/5/24.
//

import Foundation
import HealthKit
import SwiftUI
import Suite

public actor HealthBox: ObservableObject {
	public static let instance = HealthBox()
	
	public let healthStore = HKHealthStore()

	public struct Notifications {
		public static let didAuthorize = Notification.Name("HealthBox.didAuthorize")
	}
	
	enum HealthBoxError: Error, LocalizedError { case noMetricsSpecified }

	public nonisolated var isAuthorized: Bool { isAuthorizedValue.value }
	public var isCheckingAuthorization = false
	@AppStorage("requested_healthmetrics_signature") var requestedHealthMetricsSignature = ""
	
	private let isAuthorizedValue: CurrentValueSubject<Bool, Never> = .init(false)
	
	public func setup() async {
		await NotificationCenter.default.addObserver(self, selector: #selector(willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		
		await checkForAuthorization()
	}
	
	@objc nonisolated func willMoveToForeground() {
		if !isAuthorized { Task { await checkForAuthorization() }}
	}
	
	func checkForAuthorization() async {
		let wasAuthorized = isAuthorized
		
		var availableMetrics: [HealthMetric] = []
		if self.isCheckingAuthorization { return }
		self.isCheckingAuthorization = true
		self.objectWillChange.sendOnMain()
		
		let start = Date.now.addingTimeInterval(-1)
		let end = Date.now
		
		for metric in HealthMetric.required {
			do {
				let _ = try await HealthDataFetcher.instance.fetch(metric, start: start, end: end, limit: 1)
				availableMetrics.append(metric)
			} catch {
			}
		}
		
		self.isCheckingAuthorization = false
		self.isAuthorizedValue.value = availableMetrics.count == HealthMetric.required.count
		if !wasAuthorized, self.isAuthorized { HealthBox.Notifications.didAuthorize.notify() }
		self.objectWillChange.sendOnMain()
	}
	
	public var hasRequestedAccess: Bool {
		requestedHealthMetricsSignature == HealthMetric.ofInterest.signature
	}
	
	public func requestAuthorization() async throws {
		if HealthMetric.ofInterest.isEmpty { throw HealthBoxError.noMetricsSpecified }
		
		requestedHealthMetricsSignature = HealthMetric.ofInterest.signature
		let readTypes: [HKSampleType] = HealthMetric.ofInterest.compactMap { $0.sampleType }
		return try await withCheckedThrowingContinuation { continuation in
			healthStore.requestAuthorization(toShare: [], read: Set(readTypes)) { success, error in
				if let err = error {
					continuation.resume(throwing: err)
				} else {
					Task {
						await self.checkForAuthorization()
						continuation.resume()
					}
				}
			}
		}
	}
}

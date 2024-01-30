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

public class HealthKitInterface: ObservableObject {
	public static let instance = HealthKitInterface()
	
	public let healthStore = HKHealthStore()

	public struct Notifications {
		public static let didAuthorize = Notification.Name("HealthKitInterface.didAuthorize")
	}
	
	public var isAuthorized = false
	public var isCheckingAuthorization = false
	@AppStorage("requested_healthmetrics_signature") var requestedHealthMetricsSignature = ""
	
	public func setup(authorizationCheckCompleted: (() -> Void)? = nil) {
		NotificationCenter.default.addObserver(self, selector: #selector(willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		
		checkForAuthorization(authorizationCheckCompleted: authorizationCheckCompleted)
	}
	
	@objc func willMoveToForeground() {
		if !isAuthorized { checkForAuthorization() }
	}
	
	func checkForAuthorization(authorizationCheckCompleted: (() -> Void)? = nil) {
		let wasAuthorized = isAuthorized
		
		Task.detached {
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
			self.isAuthorized = availableMetrics.count == HealthMetric.required.count
			if !wasAuthorized, self.isAuthorized { HealthKitInterface.Notifications.didAuthorize.notify() }
			self.objectWillChange.sendOnMain()
			authorizationCheckCompleted?()
		}
	}
	
	public var hasRequestedAccess: Bool {
		requestedHealthMetricsSignature == HealthMetric.ofInterest.signature
	}
	
	public func requestAuthorization() async throws {
		requestedHealthMetricsSignature = HealthMetric.ofInterest.signature
		let readTypes: [HKSampleType] = HealthMetric.ofInterest.compactMap { $0.sampleType }
		return try await withCheckedThrowingContinuation { continuation in
			healthStore.requestAuthorization(toShare: [], read: Set(readTypes)) { success, error in
				if let err = error {
					continuation.resume(throwing: err)
				} else {
					self.checkForAuthorization()
					continuation.resume()
				}
			}
		}
	}
}

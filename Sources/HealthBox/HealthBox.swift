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
	public nonisolated var isCheckingAuthorization: Bool { isCheckingAuthorizationSubject.value }
	
	let isCheckingAuthorizationSubject: CurrentValueSubject<Bool, Never> = .init(false)
	let requestedHealthMetricsSignature: CurrentValueSubject<String?, Never> = .init(nil)
	
	private let isAuthorizedValue: CurrentValueSubject<Bool, Never> = .init(false)
	
	public func setup() async {
		await NotificationCenter.default.addObserver(self, selector: #selector(willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		
		await checkForAuthorization()
	}
	
	init() {
		requestedHealthMetricsSignature.value = UserDefaults.standard.string(forKey: "requested_healthmetrics_signature")
	}
	
	@objc nonisolated func willMoveToForeground() {
		if !isAuthorized { Task { await checkForAuthorization() }}
	}
	
	func checkForAuthorization() async {
		let wasAuthorized = isAuthorized
		
		var availableMetrics: [HealthMetric] = []
		if self.isCheckingAuthorization { return }
		self.isCheckingAuthorizationSubject.value = true
		self.objectWillChange.sendOnMain()
		
		let start = Date.now.addingTimeInterval(-1)
		let end = Date.now
		
		for metric in HealthMetric.required.value {
			do {
				let _ = try await HealthDataFetcher.instance.fetch(metric, start: start, end: end, limit: 1)
				availableMetrics.append(metric)
			} catch {
			}
		}
		
		self.isCheckingAuthorizationSubject.value = false
		self.isAuthorizedValue.value = availableMetrics.count == HealthMetric.required.value.count
		if !wasAuthorized, self.isAuthorized { HealthBox.Notifications.didAuthorize.notify() }
		self.objectWillChange.sendOnMain()
	}
	
	public nonisolated var hasRequestedAccess: Bool {
		requestedHealthMetricsSignature.value == HealthMetric.ofInterest.value.signature
	}
	
	public func requestAuthorization() async throws {
		if HealthMetric.ofInterest.value.isEmpty { throw HealthBoxError.noMetricsSpecified }
		
		requestedHealthMetricsSignature.value = HealthMetric.ofInterest.value.signature
		UserDefaults.standard.set(HealthMetric.ofInterest.value.signature, forKey: "requested_healthmetrics_signature")
		let readTypes: [HKSampleType] = HealthMetric.ofInterest.value.compactMap { $0.sampleType }
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

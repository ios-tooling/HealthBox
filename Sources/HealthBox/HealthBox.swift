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
	public nonisolated var isSettingUp: Bool { isSettingUpValue.value }
	public nonisolated var isCheckingAuthorization: Bool { isCheckingAuthorizationSubject.value }
	
	let isCheckingAuthorizationSubject: CurrentValueSubject<Bool, Never> = .init(false)
	
	private let isAuthorizedValue: CurrentValueSubject<Bool, Never> = .init(false)
	private let isSettingUpValue: CurrentValueSubject<Bool, Never> = .init(true)

	public func setupHealthKitAccess(requiredMetrics: [HealthMetric]) async {
		NotificationCenter.default.addObserver(self, selector: #selector(willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		HealthMetric.requiredStore.value = requiredMetrics
		
		await checkForAuthorization()
	}
	
	nonisolated func checkAuthorizationStatus() {
		Task {
			if (try? await self.hasRequestedAccess) == true {
				isAuthorizedValue.value = true
				isSettingUpValue.value = false
			} else {
				isAuthorizedValue.value = false
				isSettingUpValue.value = true
			}
		}
	}
	
	@objc nonisolated func willMoveToForeground() {
		if !isAuthorized { Task { await checkForAuthorization() }}
	}
	
	func checkForAuthorization() async {
		if self.isCheckingAuthorization || HealthMetric.required.isEmpty { return }

		let wasAuthorized = isAuthorized
		
		var availableMetrics: [HealthMetric] = []
		self.isCheckingAuthorizationSubject.value = true
		self.objectWillChange.sendOnMain()
		
		let start = Date.now.addingTimeInterval(-.day * 7)		// just look back a week to check for HealthKit data
		let end = Date.now
		
		for metric in HealthMetric.required {
			do {
				let found = try await HealthDataFetcher.instance.fetch(metric, start: start, end: end, limit: 1)
				if !found.isEmpty { availableMetrics.append(metric) }
			} catch {
				print("Failed to check metrics for \(metric.name)")
			}
		}
		
		self.isCheckingAuthorizationSubject.value = false
		self.isAuthorizedValue.value = availableMetrics.count == HealthMetric.required.count
		if !wasAuthorized, self.isAuthorized {
			await MainActor.run { HealthBox.Notifications.didAuthorize.notify() }
		}
		isSettingUpValue.value = false
		await MainActor.run { self.objectWillChange.sendOnMain() }
	}
	
	public func detectedMetrics(from list: [HealthMetric]) async -> [HealthMetric] {
		let start = Date.now.addingTimeInterval(-.day * 7)		// just look back a week to check for HealthKit data
		let end = Date.now
		var found: [HealthMetric] = []
		
		for metric in list {
			do {
				let results = try await HealthDataFetcher.instance.fetch(metric, start: start, end: end, limit: 1)
				if !results.isEmpty { found.append(metric) }
			} catch { }
		}
		return found
	}
	
	public nonisolated var hasRequestedAccess: Bool {
		get async throws {
			if HealthMetric.ofInterest.isEmpty {
				print("Please set your HealthMetric.ofInterest before checking for access.")
				return false
			}
			let readTypes: [HKSampleType] = HealthMetric.ofInterest.compactMap { $0.sampleType }

			let status = try await healthStore.statusForAuthorizationRequest(toShare: [], read: Set(readTypes))
			
			return status == .unnecessary
		}
	}
	
	public func requestAuthorization() async throws {
		if HealthMetric.ofInterest.isEmpty { throw HealthBoxError.noMetricsSpecified }
		
		let readTypes: [HKSampleType] = HealthMetric.ofInterest.compactMap { $0.sampleType }
		return try await withCheckedThrowingContinuation { continuation in
			healthStore.requestAuthorization(toShare: [], read: Set(readTypes)) { success, error in
				if let err = error {
					continuation.resume(throwing: err)
				} else {
					UserDefaults.standard.set(HealthMetric.ofInterest.signature, forKey: "requested_healthmetrics_signature")

					Task {
						await self.checkForAuthorization()
						continuation.resume()
					}
				}
			}
		}
	}
}

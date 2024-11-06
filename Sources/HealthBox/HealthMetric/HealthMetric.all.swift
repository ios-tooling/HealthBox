//
//  HealthMetric.all.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/17/24.
//

import Foundation
import HealthKit
import Combine

extension HealthMetric {
	static let ofInterestStore: CurrentValueSubject<[HealthMetric], Never> = .init([])
	static let requiredStore: CurrentValueSubject<[HealthMetric], Never> = .init([])
	
	static nonisolated var ofInterest: [HealthMetric] { ofInterestStore.value }
	static nonisolated var required: [HealthMetric] { requiredStore.value }
	
	public static func setMetricsOfInterest(_ metrics: [HealthMetric]) {
		ofInterestStore.value = metrics
		HealthBox.instance.checkAuthorizationStatus()
	}
}

public extension HealthMetric {

	static let all: CurrentValueSubject<[HealthMetric], Never> = .init([])
	
	internal static func register(_ metric: HealthMetric) {
		if !all.value.contains(metric) { all.value.append(metric) }
	}
	
	static let heartRate = HealthMetric(identifier: .heartRate, units: .count().unitDivided(by: .second()), cumulative: false)
	static let activeEnergyBurned = HealthMetric(identifier: .activeEnergyBurned, units: .kilocalorie(), cumulative: true)
	static let stepCount = HealthMetric(identifier: .stepCount, units: .count(), cumulative: true)
	
	static let appleExerciseTime = HealthMetric(identifier: .appleExerciseTime, units: .minute(), cumulative: true)
	static let appleMoveTime = HealthMetric(identifier: .appleMoveTime, units: .minute(), cumulative: true)
	static let appleStandTime = HealthMetric(identifier: .appleStandTime, units: .minute(), cumulative: true)
	
	@available(iOS 17.0, *)
	static let timeInDaylight = HealthMetric(identifier: .timeInDaylight, units: .minute(), cumulative: true)

	static let heartRateVariability = HealthMetric(identifier: .heartRateVariabilitySDNN, units: .secondUnit(with: .milli), cumulative: false)
	static let sleep = HealthMetric(identifier: .sleepAnalysis)

	static let distanceWalkingRunning = HealthMetric(identifier: .distanceWalkingRunning, units: .meter(), cumulative: true)
	static let distanceSwimming = HealthMetric(identifier: .distanceSwimming, units: .meter(), cumulative: true)
	static let distanceCycling = HealthMetric(identifier: .distanceCycling, units: .meter(), cumulative: true)
	static let distanceWheelchair = HealthMetric(identifier: .distanceWheelchair, units: .meter(), cumulative: true)
	static let restingHeartRate = HealthMetric(identifier: .restingHeartRate, units: .count().unitDivided(by: .second()), cumulative: false)
	static let walkingHeartRateAverage = HealthMetric(identifier: .walkingHeartRateAverage, units: .count().unitDivided(by: .second()), cumulative: false)

	static let common: [HealthMetric] = [
		.activeEnergyBurned,
		.stepCount,
		.heartRate,
		
		.appleExerciseTime,
		.appleMoveTime,
		.appleStandTime,
		
		.distanceWalkingRunning,
		.distanceSwimming,
		.distanceCycling,
		.distanceWheelchair,
		.restingHeartRate,
		.walkingHeartRateAverage,

		.sleep,
	]

}

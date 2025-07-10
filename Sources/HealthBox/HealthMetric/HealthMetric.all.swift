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
	
	static let heartRate = HealthMetric(identifier: .heartRate, units: .count().unitDivided(by: .second()), cumulative: false, symbol: "heartRate")
	static let activeEnergyBurned = HealthMetric(identifier: .activeEnergyBurned, units: .kilocalorie(), cumulative: true, symbol: "activeEnergyBurned")
	static let stepCount = HealthMetric(identifier: .stepCount, units: .count(), cumulative: true, symbol: "stepCount")
	
	static let appleExerciseTime = HealthMetric(identifier: .appleExerciseTime, units: .minute(), cumulative: true, symbol: "appleExerciseTime")
	static let appleMoveTime = HealthMetric(identifier: .appleMoveTime, units: .minute(), cumulative: true, symbol: "appleMoveTime")
	static let appleStandTime = HealthMetric(identifier: .appleStandTime, units: .minute(), cumulative: true, symbol: "appleStandTime")
	
	@available(iOS 17.0, *)
	static let timeInDaylight = HealthMetric(identifier: .timeInDaylight, units: .minute(), cumulative: true, symbol: "timeInDaylight")

	static let heartRateVariability = HealthMetric(identifier: .heartRateVariabilitySDNN, units: .secondUnit(with: .milli), cumulative: false, symbol: "heartRateVariabilitySDNN")
	static let sleep = HealthMetric(identifier: .sleepAnalysis, symbol: "sleepAnalysis")

	static let distanceWalkingRunning = HealthMetric(identifier: .distanceWalkingRunning, units: .meter(), cumulative: true, symbol: "distanceWalkingRunning")
	static let distanceSwimming = HealthMetric(identifier: .distanceSwimming, units: .meter(), cumulative: true, symbol: "distanceSwimming")
	static let distanceCycling = HealthMetric(identifier: .distanceCycling, units: .meter(), cumulative: true, symbol: "distanceCycling")
	static let distanceWheelchair = HealthMetric(identifier: .distanceWheelchair, units: .meter(), cumulative: true, symbol: "distanceWheelchair")
	static let restingHeartRate = HealthMetric(identifier: .restingHeartRate, units: .count().unitDivided(by: .second()), cumulative: false, symbol: "restingHeartRate")
	static let walkingHeartRateAverage = HealthMetric(identifier: .walkingHeartRateAverage, units: .count().unitDivided(by: .second()), cumulative: false, symbol: "walkingHeartRateAverage")

	static let bodyMass = HealthMetric(identifier: .bodyMass, units: .gram(), cumulative: false, symbol: "bodyMass")
	static let bodyMassIndex = HealthMetric(identifier: .bodyMassIndex, units: .count(), cumulative: false, symbol: "bodyMassIndex")
	static let leanBodyMass = HealthMetric(identifier: .bodyMass, units: .gram(), cumulative: false, symbol: "leanBodyMass")
	static let bloodGlucose = HealthMetric(identifier: .bloodGlucose, units: .gram().unitDivided(by: .liter()), cumulative: false, symbol: "bloodGlucose")

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

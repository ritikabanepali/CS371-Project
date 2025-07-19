//
//  HealthKitManager.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/19/25.
//

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization (completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let readTypes: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKitManager: Authorization failed: \(error.localizedDescription)")
                    completion(false)
                } else if success {
                    print("HealthKitManager: Authorization granted.")
                    completion(true)
                } else {
                    print("HealthKitManager: Authorization denied by user.")
                    completion(false)
                }
            }
        }
    }
    
    func getStepCount(forDateRange startDate: Date, endDate: Date, completion: @escaping (Int) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKitManager: Error fetching step count: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                let sumQuantity = result?.sumQuantity()
                let totalSteps = Int(sumQuantity?.doubleValue(for: .count()) ?? 0)
                completion(totalSteps)
            }
        }
        healthStore.execute(query)
    }
}

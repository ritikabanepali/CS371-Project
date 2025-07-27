//
//  HealthKitManager.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/19/25.
//
//  guide: https://bennett4.medium.com/creating-an-ios-app-to-display-the-number-of-steps-taken-today-1060635e05ae

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization (completion: @escaping (Bool) -> Void) {
        //type of data being read from healthstore
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let readTypes: Set<HKObjectType> = [stepType]
        
        //request user to allow healthstore usage for step count reading
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
            DispatchQueue.main.async {
                if error != nil {
                    print("Healthkit Authorization failed")
                    completion(false)
                } else if success {
                    print("Healthkit Authorization success")
                    completion(true)
                } else {
                    print("Healthkit Authorization denied")
                    completion(false)
                }
            }
        }
    }
    
    func getStepCount(forDateRange startDate: Date, endDate: Date, completion: @escaping (Int) -> Void) {
        //step count set up
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        //predicate created for choosing dates and filtering and query accesses data
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            DispatchQueue.main.async {
                if error != nil {
                    print("HealthKitManager error retrieving data")
                    completion(0)
                    return
                }
                
                //get steps and cast double value to an int
                let sumQuantity = result?.sumQuantity()
                let totalSteps = Int(sumQuantity?.doubleValue(for: .count()) ?? 0)
                completion(totalSteps)
            }
        }
        healthStore.execute(query)
    }
}

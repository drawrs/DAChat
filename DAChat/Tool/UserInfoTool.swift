//
//  UserInfoTool.swift
//  DAChat
//
//  Created by Rizal Hilman on 29/10/25.
//

import FoundationModels
import HealthKit

@MainActor
final class UserInfoTool: Tool {
    let name = "getUserInfo"
    let description = "Returns the user's biological sex, date of birth, blood type, and wheelchair status as available from HealthKit."

    enum Error: Swift.Error, LocalizedError {
        case healthDataNotAvailable
        case unauthorized

        var errorDescription: String? {
            switch self {
            case .healthDataNotAvailable:
                "Health data is not available on this device"
            case .unauthorized:
                "Unauthorized to access HealthKit data"
            }
        }
    }

    @Generable
    struct Arguments {}

    private let healthStore = HKHealthStore()
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.characteristicType(forIdentifier: .bloodType)!,
        HKObjectType.characteristicType(forIdentifier: .wheelchairUse)!
    ]

    func call(arguments: Arguments) async throws -> GeneratedContent {
        #if os(iOS)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw Error.healthDataNotAvailable
        }

        let granted: Bool = try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
        guard granted else { throw Error.unauthorized }

        return try GeneratedContent(properties: [
            "gender": gender(),
            "dateOfBirth": dateOfBirth(),
            "bloodType": bloodType(),
            "wheelchairUse": wheelchairUse()
        ])
        #else
        return GeneratedContent(properties: [:])
        #endif
    }

    // MARK: - Private

    private func dateOfBirth() throws -> String {
        let components = try healthStore.dateOfBirthComponents()
        guard let year = components.year, let month = components.month, let day = components.day else { return "Not Set" }
        return "\(year)-\(month)-\(day)"
    }

    private func gender() throws -> String {
        switch try healthStore.biologicalSex().biologicalSex {
        case .notSet: "Not Set"
        case .female: "Female"
        case .male: "Male"
        case .other: "Other"
        @unknown default: "Unknown"
        }
    }

    private func bloodType() throws -> String {
        switch try healthStore.bloodType().bloodType {
        case .notSet: "Not Set"
        case .aPositive: "A+"
        case .aNegative: "A-"
        case .bPositive: "B+"
        case .bNegative: "B-"
        case .abPositive: "AB+"
        case .abNegative: "AB-"
        case .oPositive: "O+"
        case .oNegative: "O-"
        @unknown default: "Unknown"
        }
    }

    private func wheelchairUse() throws -> String {
        switch try healthStore.wheelchairUse().wheelchairUse {
        case .notSet: "Not Set"
        case .yes: "Yes"
        case .no: "No"
        @unknown default: "Unknown"
        }
    }
}

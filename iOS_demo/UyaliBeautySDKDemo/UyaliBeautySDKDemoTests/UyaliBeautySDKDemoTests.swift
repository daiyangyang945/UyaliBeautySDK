//
//  UyaliBeautySDKDemoTests.swift
//  UyaliBeautySDKDemoTests
//
//  Created by S weet on 2023/1/27.
//

import XCTest
@testable import UyaliBeautySDKDemo
import UyaliBeautySDK

final class UyaliBeautySDKDemoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testPublicDemoLicenseMatrix() throws {
        let licenseDirectory = URL(fileURLWithPath: "/Users/dyy/Desktop/mac/uyaliBeauty/test_license")
        let files = try FileManager.default.contentsOfDirectory(
            at: licenseDirectory,
            includingPropertiesForKeys: nil
        )
            .filter { $0.pathExtension == "uyali" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        XCTAssertFalse(files.isEmpty, "No license files found in test_license.")

        var rows: [String] = []
        var failures: [String] = []
        for file in files {
            let name = file.deletingPathExtension().lastPathComponent
            let expectedStatus = expectedStatusFromLicenseName(name)
            let expectedModules = expectedStatus == .valid ? expectedModulesFromLicenseName(name) : []
            let engine = UyaliBeautyEngine()
            let result = engine.loadLicense(at: file)
            let granted = grantedModules(engine)
            let trialSeconds = Int(engine.licenseTrialSecondsRemaining)

            rows.append(
                "\(name): status=\(statusName(result.status)) granted=\(granted.joined(separator: ",")) trial=\(trialSeconds)"
            )

            validateCase(name: name,
                         expectedStatus: expectedStatus,
                         expectedModules: expectedModules,
                         result: result,
                         granted: granted,
                         trialSeconds: trialSeconds,
                         failures: &failures)
        }

        let report = rows.joined(separator: "\n")
        print("UYALI_PUBLIC_IOS_LICENSE_MATRIX_BEGIN\n\(report)\nUYALI_PUBLIC_IOS_LICENSE_MATRIX_END")
        if !failures.isEmpty {
            XCTFail("Public iOS demo license matrix failed:\n\(failures.joined(separator: "\n"))\n\nReport:\n\(report)")
        }
    }

    private func expectedStatusFromLicenseName(_ name: String) -> UyaliBeautyLicenseStatus {
        guard name.hasPrefix("ios_") else {
            return .platformUnsupported
        }
        return name.contains("error_id") ? .appMismatch : .valid
    }

    private func expectedModulesFromLicenseName(_ name: String) -> Set<String> {
        var modules: Set<String> = []
        for module in ["beauty", "reshape", "body", "makeup"] where name.contains(module) {
            modules.insert(module)
        }
        return modules
    }

    private func grantedModules(_ engine: UyaliBeautyEngine) -> [String] {
        [
            ("beauty", UyaliBeautyFeature.beauty),
            ("reshape", UyaliBeautyFeature.reshape),
            ("body", UyaliBeautyFeature.body),
            ("makeup", UyaliBeautyFeature.makeup),
        ].compactMap { name, feature in
            engine.canUseFeature(feature) ? name : nil
        }
    }

    private func validateCase(name: String,
                              expectedStatus: UyaliBeautyLicenseStatus,
                              expectedModules: Set<String>,
                              result: UyaliBeautyLicenseResult,
                              granted: [String],
                              trialSeconds: Int,
                              failures: inout [String]) {
        if result.status != expectedStatus {
            failures.append("\(name) status expected \(statusName(expectedStatus)), got \(statusName(result.status))")
        }
        if Set(granted) != expectedModules {
            failures.append("\(name) modules expected \(expectedModules.sorted()), got \(granted)")
        }
        if trialSeconds != 0 {
            failures.append("\(name) should not expose trial seconds after loading a license, got \(trialSeconds)")
        }
    }

    private func statusName(_ status: UyaliBeautyLicenseStatus) -> String {
        switch status {
        case .free:
            return "FREE"
        case .valid:
            return "VALID"
        case .invalidFormat:
            return "INVALID_FORMAT"
        case .invalidSignature:
            return "INVALID_SIGNATURE"
        case .unsupportedAlgorithm:
            return "UNSUPPORTED_ALGORITHM"
        case .unsupportedKey:
            return "UNSUPPORTED_KEY"
        case .platformUnsupported:
            return "PLATFORM_UNSUPPORTED"
        case .appMismatch:
            return "APP_MISMATCH"
        case .expired:
            return "EXPIRED"
        case .notYetValid:
            return "NOT_YET_VALID"
        case .timeRollback:
            return "TIME_ROLLBACK"
        case .sdkVersionUnsupported:
            return "SDK_VERSION_UNSUPPORTED"
        @unknown default:
            return "UNKNOWN"
        }
    }

}

//
//  ToggleTests.swift
//  ToggleTests
//
//  Created by Maciek Grzybowski on 28.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
@testable import Toggle

private final class MockToggleStorage: ToggleStorage {

    private let readValue: Bool
    private let readShouldFail: Bool
    private let saveShouldFail: Bool

    init(readValue: Bool, readShouldFail: Bool = false, saveShouldFail: Bool = false) {
        self.readValue = readValue
        self.readShouldFail = readShouldFail
        self.saveShouldFail = saveShouldFail
    }

    func read() -> Observable<Bool> {
        let readShouldFail = self.readShouldFail
        let readValue = self.readValue

        return Observable
            .just(())
            .delay(0.1, scheduler: MainScheduler.instance)
            .map {
                if readShouldFail {
                    throw MockError.mockError
                } else {
                    return readValue
                }
            }
    }

    func save(value: Bool) -> Observable<Void> {
        let saveShouldFail = self.saveShouldFail

        return Observable
            .just(())
            .delay(0.1, scheduler: MainScheduler.instance)
            .map {
                if saveShouldFail {
                    throw MockError.mockError
                } else {
                    return ()
                }
        }
    }
}

private enum MockError: Error {
    case mockError
}

class ToggleTests: XCTestCase {

    // MARK: - Testing `value` output

    func test_givenStorageThatSucceedsOnRead_whenSubscriptionToValueIsMade_itEmitsInitialValue() {
        let mockStorage = MockToggleStorage(readValue: true, readShouldFail: false)
        let toggle = Toggle(storage: mockStorage)
        let expectation = self.expectation(description: "will emit value")
        let (value, _) = toggle.manage(change: .never())

        _ = value
            .drive(onNext: { value in
                XCTAssertEqual(value, ToggleValue.initial(true))
                expectation.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_givenStorageThatFailsOnRead_whenSubscriptionToValueIsMade_itEmitsUnknownValue() {
        let mockStorage = MockToggleStorage(readValue: true, readShouldFail: true)
        let toggle = Toggle(storage: mockStorage)
        let expectation = self.expectation(description: "will emit value")
        let (value, _) = toggle.manage(change: .never())

        _ = value
            .drive(onNext: { value in
                XCTAssertEqual(value, ToggleValue.unknown(MockError.mockError))
                expectation.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_givenStorageThatSucceedsOnSave_whenChangingToggleValue_itEmitsUpdatedValue() {
        let mockStorage = MockToggleStorage(readValue: true, saveShouldFail: false)
        let simulatedValueSubject = PublishSubject<Bool>() // simulated user input
        let toggle = Toggle(storage: mockStorage)
        let initialValueExpectation = self.expectation(description: "will emit initial value")
        let updatedValueExpectation = self.expectation(description: "will emit 2 updated values")
        updatedValueExpectation.expectedFulfillmentCount = 2
        let (value, _) = toggle.manage(change: simulatedValueSubject.asObservable())

        var recordedValues: [ToggleValue] = []

        _ = value
            .drive(onNext: { value in
                recordedValues.append(value)
                if value.isInitial { initialValueExpectation.fulfill() }
                if value.isUpdated { updatedValueExpectation.fulfill() }
            })

        wait(for: [initialValueExpectation], timeout: 1) // wait for receiving initial value

        simulatedValueSubject.onNext(false) // then simulate user switching toggle off
        simulatedValueSubject.onNext(true) // then simulate user switching toggle on

        wait(for: [updatedValueExpectation], timeout: 1)

        XCTAssertEqual(recordedValues, [ToggleValue.initial(true), ToggleValue.updated(false), ToggleValue.updated(true)])
    }

    func test_givenStorageThatFailsOnSave_whenChangingToggleValue_itEmitsFallbackValue() {
        let mockStorage = MockToggleStorage(readValue: true, saveShouldFail: true)
        let simulatedValueSubject = PublishSubject<Bool>() // simulated user input
        let toggle = Toggle(storage: mockStorage)
        let initialValueExpectation = self.expectation(description: "will emit initial value")
        let fallbackValueExpectation = self.expectation(description: "will emit 2 fallback values")
        fallbackValueExpectation.expectedFulfillmentCount = 2
        let (value, _) = toggle.manage(change: simulatedValueSubject.asObservable())

        var recordedValues: [ToggleValue] = []

        _ = value
            .drive(onNext: { value in
                recordedValues.append(value)
                if value.isInitial { initialValueExpectation.fulfill() }
                if value.isFallback { fallbackValueExpectation.fulfill() }
            })

        wait(for: [initialValueExpectation], timeout: 1) // wait for receiving initial value

        simulatedValueSubject.onNext(false) // simulate user switching toggle off
        simulatedValueSubject.onNext(true) // simulate user switching toggle off

        wait(for: [fallbackValueExpectation], timeout: 1)

        XCTAssertEqual(recordedValues, [ToggleValue.initial(true), ToggleValue.fallback(true), ToggleValue.fallback(false)])
    }

    // MARK: - Testing `isBusy` output

    func test_givenStorageThatSucceedsOnRead_whenExpectingInitialValue_itIsBusyWhileWaiting() {
        let mockStorage = MockToggleStorage(readValue: true, readShouldFail: false)
        let toggle = Toggle(storage: mockStorage)
        let initialValueExpectation = self.expectation(description: "will emit initial value")
        let isBusyExpectation = self.expectation(description: "will emit isBusy 2 times")
        isBusyExpectation.expectedFulfillmentCount = 2
        let (value, isBusy) = toggle.manage(change: .never())

        _ = value
            .drive(onNext: { value in
                initialValueExpectation.fulfill()
            })

        var recordedIsBusy: [Bool] = []

        _ = isBusy
            .drive(onNext: { isBusy in
                recordedIsBusy.append(isBusy)
                isBusyExpectation.fulfill()
            })

        XCTAssertEqual(recordedIsBusy, [true])

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(recordedIsBusy, [true, false])
    }

    func test_givenStorageThatFailsOnRead_whenExpectingInitialValue_itIsBusyWhileWaiting() {
        let mockStorage = MockToggleStorage(readValue: true, readShouldFail: true)
        let toggle = Toggle(storage: mockStorage)
        let initialValueExpectation = self.expectation(description: "will emit initial value")
        let isBusyExpectation = self.expectation(description: "will emit isBusy 2 times")
        isBusyExpectation.expectedFulfillmentCount = 2
        let (value, isBusy) = toggle.manage(change: .never())

        _ = value
            .drive(onNext: { value in
                initialValueExpectation.fulfill()
            })

        var recordedIsBusy: [Bool] = []

        _ = isBusy
            .drive(onNext: { isBusy in
                recordedIsBusy.append(isBusy)
                isBusyExpectation.fulfill()
            })

        XCTAssertEqual(recordedIsBusy, [true])

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(recordedIsBusy, [true, false])
    }

    func test_givenStorageThatSucceedsOnSave_whenExpectingUpdatedValue_itIsBusyWhileWaiting() {
        let mockStorage = MockToggleStorage(readValue: true, saveShouldFail: false)
        let simulatedValueSubject = PublishSubject<Bool>() // simulated user input
        let toggle = Toggle(storage: mockStorage)
        let initialValueExpectation = self.expectation(description: "will emit initial value")
        let updatedValueExpectation = self.expectation(description: "will emit updated value")
        let isBusyExpectation = self.expectation(description: "will emit isBusy 4 times")
        isBusyExpectation.expectedFulfillmentCount = 4
        let (value, isBusy) = toggle.manage(change: simulatedValueSubject.asObservable())

        _ = value
            .drive(onNext: { value in
                if value.isInitial { initialValueExpectation.fulfill() }
                if value.isUpdated { updatedValueExpectation.fulfill() }
            })

        var recordedIsBusy: [Bool] = []

        _ = isBusy
            .drive(onNext: { isBusy in
                recordedIsBusy.append(isBusy)
                isBusyExpectation.fulfill()
            })

        wait(for: [initialValueExpectation], timeout: 1)

        simulatedValueSubject.onNext(false) // simulate user switching toggle off

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(recordedIsBusy, [true, false, true, false])
    }

    func test_givenStorageThatFailsOnSave_whenExpectingFallbackValue_itIsBusyWhileWaiting() {
        let mockStorage = MockToggleStorage(readValue: true, saveShouldFail: true)
        let simulatedValueSubject = PublishSubject<Bool>() // simulated user input
        let toggle = Toggle(storage: mockStorage)
        let initialValueExpectation = self.expectation(description: "will emit initial value")
        let updatedValueExpectation = self.expectation(description: "will emit updated value")
        let isBusyExpectation = self.expectation(description: "will emit isBusy 4 times")
        isBusyExpectation.expectedFulfillmentCount = 4
        let (value, isBusy) = toggle.manage(change: simulatedValueSubject.asObservable())

        _ = value
            .drive(onNext: { value in
                if value.isInitial { initialValueExpectation.fulfill() }
                if value.isFallback { updatedValueExpectation.fulfill() }
            })

        var recordedIsBusy: [Bool] = []

        _ = isBusy
            .drive(onNext: { isBusy in
                recordedIsBusy.append(isBusy)
                isBusyExpectation.fulfill()
            })

        wait(for: [initialValueExpectation], timeout: 1)

        simulatedValueSubject.onNext(false) // simulate user switching toggle off

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(recordedIsBusy, [true, false, true, false])
    }
}

// MARK: - Convenience

extension ToggleValue: Equatable {
    public static func ==(lhs: ToggleValue, rhs: ToggleValue) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}

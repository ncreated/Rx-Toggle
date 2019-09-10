//
//  NetworkToggleStorage.swift
//  Toggle
//
//  Created by Maciek Grzybowski on 28.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import RxSwift

enum NetworkToggleStorageError: Error {
    case savingError
}

/// `SettingStorage` that stores setting value in memory.
final class NetworkToggleStorage: ToggleStorage {

    // MARK: - Properties

    private var value: Bool

    // MARK: - Initializers

    init(value: Bool) {
        self.value = value
    }

    // MARK: - Public

    func read() -> Observable<Bool> {
        return Observable.just(value)
            .delay(.seconds(3), scheduler: MainScheduler.instance)
    }

    func save(value: Bool) -> Observable<Void> {
        let simulateError = shouldFail()

        return Observable.just(())
            .delay(.seconds(3), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                if simulateError {
                    return Observable.error(NetworkToggleStorageError.savingError)
                } else {
                    self?.value = value
                    return Observable.just(())
                }
            }
    }

    // MARK: - Private

    private var count = 0

    private func shouldFail() -> Bool {
        count += 1
        return count % 3 == 0 // fail every 3 saves
    }

}

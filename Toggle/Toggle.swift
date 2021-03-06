//
//  Toggle.swift
//  Toggle
//
//  Created by Maciek Grzybowski on 28.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import RxSwift
import RxCocoa

final class Toggle {

    // MARK: - Properties

    private let storage: ToggleStorage

    // MARK: - Initializer

    init(storage: ToggleStorage) {
        self.storage = storage
    }

    // MARK: - Public

    func manage(change: Observable<Bool>) -> (value: Driver<ToggleValue>, isBusy: Driver<Bool>) {
        let storage = self.storage
        let isBusySubject = PublishSubject<Bool>()

        let isBusy = isBusySubject
            .asDriver(onErrorJustReturn: false)
            .startWith(true)

        let initialValue = storage
            .read()
            .map { ToggleValue.initial($0) }
            .catchError { Observable.just( ToggleValue.unknown($0) ) }
            .do(onNext: { _ in isBusySubject.onNext(false) })

        let valueAfterSaving = change
            .do(onNext: { _ in isBusySubject.onNext(true) })
            .flatMap { valueToSave -> Observable<ToggleValue> in
                storage
                    .save(value: valueToSave)
                    .map { ToggleValue.updated(valueToSave) }
                    .catchErrorJustReturn(ToggleValue.fallback(!valueToSave))
            }
            .do(onNext: { _ in isBusySubject.onNext(false) })

        let value = Observable.merge(initialValue, valueAfterSaving)
            .asDriver(onErrorRecover: { Driver.just(ToggleValue.unknown($0)) })

        return (value: value, isBusy: isBusy)
    }
}

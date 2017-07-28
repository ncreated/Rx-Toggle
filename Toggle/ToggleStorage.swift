//
//  ToggleStorage.swift
//  Toggle
//
//  Created by Maciek Grzybowski on 28.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import RxSwift

/// Type managing storage for single toggle value.
protocol ToggleStorage {

    /// Reads value.
    /// Emits value on success or stream error on failure.
    func read() -> Observable<Bool>

    /// Saves value.
    /// Emits `Void` on success or stream error on failure.
    func save(value: Bool) -> Observable<Void>
}

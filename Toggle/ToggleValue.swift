//
//  ToggleValue.swift
//  Toggle
//
//  Created by Maciek Grzybowski on 28.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import Foundation

enum ToggleValue {

    /// Initial value read from storage
    case initial(Bool)

    /// Updated value after successfully saving in storage
    case updated(Bool)

    /// Fallback value after unsuccessfully saving in storage
    case fallback(Bool)

    /// Unknown if failed reading the initial value
    case unknown(Error)
}

extension ToggleValue {
    var value: Bool? {
        switch self {
        case .initial(let value), .updated(let value), .fallback(let value):
            return value
        case .unknown:
            return nil
        }
    }

    var error: Error? {
        switch self {
        case .initial, .updated, .fallback:
            return nil
        case .unknown(let error):
            return error
        }
    }

    var isInitial: Bool {
        switch self {
        case .initial:
            return true
        default:
            return false
        }
    }

    var isUpdated: Bool {
        switch self {
        case .updated:
            return true
        default:
            return false
        }
    }

    var isFallback: Bool {
        switch self {
        case .fallback:
            return true
        default:
            return false
        }
    }
}

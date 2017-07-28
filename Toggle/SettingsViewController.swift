//
//  SettingsViewController.swift
//  Toggle
//
//  Created by Maciek Grzybowski on 28.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingSwitch1: UISwitch!
    @IBOutlet weak var settingSwitch2: UISwitch!
    @IBOutlet weak var settingSwitch3: UISwitch!
    @IBOutlet weak var settingSwitch4: UISwitch!
    @IBOutlet weak var settingSwitch5: UISwitch!
    @IBOutlet weak var settingSwitch6: UISwitch!

    private let disposeBag = DisposeBag()

    private let toggle1 = Toggle(storage: NetworkToggleStorage(value: false))
    private let toggle2 = Toggle(storage: NetworkToggleStorage(value: true))
    private let toggle3 = Toggle(storage: NetworkToggleStorage(value: false))
    private let toggle4 = Toggle(storage: NetworkToggleStorage(value: true))
    private let toggle5 = Toggle(storage: NetworkToggleStorage(value: false))
    private let toggle6 = Toggle(storage: NetworkToggleStorage(value: true))

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp(settingSwitch: settingSwitch1, with: toggle1)
        setUp(settingSwitch: settingSwitch2, with: toggle2)
        setUp(settingSwitch: settingSwitch3, with: toggle3)
        setUp(settingSwitch: settingSwitch4, with: toggle4)
        setUp(settingSwitch: settingSwitch5, with: toggle5)
        setUp(settingSwitch: settingSwitch6, with: toggle6)
    }

    private func setUp(settingSwitch: UISwitch, with toggle: Toggle) {
        let (value, isBusy) = toggle.manage(change: settingSwitch.rx.isOn.changed.asObservable())

        let initialValue = value
            .filter { $0.isInitial }
            .map { $0.value }
            .flatMap { $0.map(Driver.just) ?? Driver.empty() } // .unwrap() if using `RxSwiftExt`

        let fallbackValue = value
            .filter { $0.isFallback }
            .map { $0.value }
            .flatMap { $0.map(Driver.just) ?? Driver.empty() } // .unwrap() if using `RxSwiftExt`

        let switchValue = Driver.merge(initialValue, fallbackValue)

        switchValue
            .drive(settingSwitch.rx.isOn)
            .disposed(by: disposeBag)

        let isSwitchDisabled = isBusy
            .map { !$0 }

        isSwitchDisabled
            .drive(settingSwitch.rx.isEnabled)
            .disposed(by: disposeBag)

        let shouldPlayShakeAnimation = fallbackValue
            .map { _ in () }

        shouldPlayShakeAnimation
            .drive(onNext: { _ in
                settingSwitch.shake()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Helpers

extension UISwitch {
    func shake() {
        transform = CGAffineTransform(translationX: 15, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
}

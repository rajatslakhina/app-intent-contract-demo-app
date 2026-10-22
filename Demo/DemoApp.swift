import SwiftUI
import IntentContracts
import IntentContractsUI

/// Intent Contract Gate demo.
///
/// The app owns the contract (`NotesContract`: the published v1.0.0 surface,
/// the recorded Shortcuts and agent plans, eight proposed releases). The
/// library computes every verdict in `ContractLab`; `ContractLabView` only
/// renders it. The first proposal, a rename that forgot its alias, is
/// selected on launch so the headline failure is visible immediately.
@main
struct DemoApp: App {
    private let lab: ContractLab = NotesContract.lab

    var body: some Scene {
        WindowGroup {
            ContractLabView(lab: lab, initialSelection: 0)
        }
    }
}

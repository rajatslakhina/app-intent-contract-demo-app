import IntentContracts

/// The demo app's published intent surface (v1.0.0), the Shortcuts and agent
/// plans recorded against it, and eight proposed releases for the gate.
///
/// The app owns this configuration; the library's `ContractLabView` only
/// renders what `ContractLab` computes from it. `OpenNote`, `CreateNote`,
/// `Note` and `NoteColor` are the real App Intents types in NotesIntents.swift;
/// the other intents are modelled in the contract only.
///
/// Kept identical to the package's test fixtures, so the verdicts shown here
/// are the ones `GateTests.testVerdictTable` asserts.
enum NotesContract {
    static let v090 = SemanticVersion(0, 9, 0)
    static let v100 = SemanticVersion(1, 0, 0)
    static let v110 = SemanticVersion(1, 1, 0)
    static let v200 = SemanticVersion(2, 0, 0)

    static let note = EntitySchema(String(describing: Note.self), idFormat: .integer, properties: [
        PropertySchema("title", .string),
        PropertySchema("tags", .list(.string))
    ])
    static let folder = EntitySchema("Folder", idFormat: .uuid, properties: [PropertySchema("name", .string)])
    static let color = EnumSchema(String(describing: NoteColor.self), cases: ["yellow", "blue", "green"])

    static let openNote = IntentSchema(String(describing: OpenNote.self), title: "Open Note", parameters: [ParameterSchema("note", .entity("Note"))])
    static let createNote = IntentSchema(String(describing: CreateNote.self), title: "Create Note", parameters: [
        ParameterSchema("title", .string),
        ParameterSchema("body", .string, optional: true),
        ParameterSchema("color", .enumeration("NoteColor"), hasDefault: true)
    ], result: .entity("Note"))
    static let findNotes = IntentSchema("FindNotes", title: "Find Notes", parameters: [
        ParameterSchema("query", .string),
        ParameterSchema("limit", .integer, optional: true)
    ], result: .list(.entity("Note")))
    static let summarize = IntentSchema("SummarizeNote", title: "Summarize Note", parameters: [ParameterSchema("note", .entity("Note"))], result: .string)
    static let archive = IntentSchema("ArchiveNote", title: "Archive Note", parameters: [ParameterSchema("note", .entity("Note"))],
                                      deprecation: Deprecation(since: v090, removalNotBefore: v200))
    static let shareText = IntentSchema("ShareText", title: "Share Text", parameters: [ParameterSchema("text", .string)])

    static let baseline = IntentSurface(
        version: v100,
        intents: [openNote, createNote, findNotes, summarize, archive, shareText],
        entities: [note, folder],
        enums: [color],
        aliases: [IntentAlias(from: "ShowNote", to: "OpenNote", since: v100)]
    )

    // MARK: Recorded plans

    static let openNote42 = AgentPlan(name: "Open note 42", origin: "Siri Shortcut", recordedAgainst: v100, steps: [
        .init(IntentInvocation("OpenNote", arguments: ["note": .entity(type: "Note", id: "42")]))
    ])
    static let legacyShowNote = AgentPlan(name: "Show note 7", origin: "Shortcut saved on 0.9", recordedAgainst: v090, steps: [
        .init(IntentInvocation("ShowNote", arguments: ["note": .entity(type: "Note", id: "7")]))
    ])
    static let summariseAndShare = AgentPlan(name: "Capture, summarise, share", origin: "Agent plan", recordedAgainst: v100, steps: [
        .init(IntentInvocation("CreateNote", arguments: ["title": .string("Standup")])),
        .init(IntentInvocation("SummarizeNote"), bindings: ["note": 0]),
        .init(IntentInvocation("ShareText"), bindings: ["text": 1])
    ])
    static let archiveOld = AgentPlan(name: "Archive note 3", origin: "Shortcut saved on 0.9", recordedAgainst: v090, steps: [
        .init(IntentInvocation("ArchiveNote", arguments: ["note": .entity(type: "Note", id: "3")]))
    ])
    static let quickCapture = AgentPlan(name: "Quick capture", origin: "Agent plan", recordedAgainst: v100, steps: [
        .init(IntentInvocation("CreateNote", arguments: ["title": .string("Idea"), "color": .enumCase("yellow")]))
    ])

    static let plans = [openNote42, legacyShowNote, summariseAndShare, archiveOld, quickCapture]

    // MARK: Helpers for building proposals

    static func surface(_ version: SemanticVersion, _ edit: (inout IntentSurface) -> Void) -> IntentSurface {
        var copy = baseline
        copy.version = version
        edit(&copy)
        return copy
    }

    static func replaceIntent(_ id: String, in surface: inout IntentSurface, with replacement: IntentSchema?) {
        guard let index = surface.intents.firstIndex(where: { $0.identifier == id }) else { return }
        if let replacement {
            surface.intents[index] = replacement
        } else {
            surface.intents.remove(at: index)
        }
    }

    static let legacyNoteIDs = ["3", "7", "42", "108"]
    static let liveNoteIDs: Set<String> = ["note-3", "note-7", "note-42", "note-108"]
    static let inboxFolder = "6F9619FF-8B86-D011-B42D-00C04FC964FF"

    // MARK: Proposed releases

    static let openDocument = IntentSchema("OpenDocument", title: "Open Note", parameters: [ParameterSchema("note", .entity("Note"))])

    static let renameForgotAlias = ContractProposal(
        title: "Rename, alias forgotten",
        summary: "OpenNote becomes OpenDocument; nobody adds an alias.",
        surface: NotesContract.surface(NotesContract.v110) { NotesContract.replaceIntent("OpenNote", in: &$0, with: openDocument) })

    static let renameWithAlias = ContractProposal(
        title: "Rename with alias",
        summary: "Same rename, plus an alias row OpenNote → OpenDocument.",
        surface: NotesContract.surface(NotesContract.v110) { s in
            NotesContract.replaceIntent("OpenNote", in: &s, with: openDocument)
            s.aliases.append(IntentAlias(from: "OpenNote", to: "OpenDocument", since: NotesContract.v110))
        })

    static func namespacedIDs(_ version: SemanticVersion) -> IntentSurface {
        NotesContract.surface(version) { $0.entities[0].idFormat = .prefixed("note-") }
    }

    static let namespacedWithShim = ContractProposal(
        title: "Namespaced IDs + shim",
        summary: "Note IDs move from 42 to note-42 in 2.0.0, with an audited ID shim.",
        surface: namespacedIDs(NotesContract.v200),
        migration: MigrationPlan(idShims: [PrefixingShim(entity: "Note", prefix: "note-")],
                                 legacyIDSamples: ["Note": NotesContract.legacyNoteIDs],
                                 liveIDSamples: ["Note": NotesContract.liveNoteIDs]))

    static let namespacedNoShim = ContractProposal(
        title: "Namespaced IDs, no shim",
        summary: "The same 2.0.0 ID change, shipped without a shim.",
        surface: namespacedIDs(NotesContract.v200))

    static func requireFolder(_ version: SemanticVersion) -> IntentSurface {
        NotesContract.surface(version) { s in
            var create = NotesContract.createNote
            create.parameters.append(ParameterSchema("folder", .entity("Folder")))
            NotesContract.replaceIntent("CreateNote", in: &s, with: create)
        }
    }

    static let requiredFolderMinor = ContractProposal(
        title: "Required folder as 1.1",
        summary: "CreateNote gains a required folder parameter in a minor release.",
        surface: requireFolder(NotesContract.v110))

    static let requiredFolderBackfilled = ContractProposal(
        title: "Required folder + backfill",
        summary: "Same parameter in 2.0.0; old callers get the Inbox folder.",
        surface: requireFolder(NotesContract.v200),
        migration: MigrationPlan(backfills: [ArgumentBackfill(intent: "CreateNote", parameter: "folder", value: .entity(type: "Folder", id: NotesContract.inboxFolder))]))

    static let removeArchiveOnSchedule = ContractProposal(
        title: "Remove ArchiveNote on schedule",
        summary: "ArchiveNote was deprecated in 0.9 with removal allowed from 2.0.0.",
        surface: NotesContract.surface(NotesContract.v200) { NotesContract.replaceIntent("ArchiveNote", in: &$0, with: nil) })

    static let summaryBecomesEntity = ContractProposal(
        title: "Summary becomes an entity",
        summary: "SummarizeNote returns a Note instead of text, in a minor release.",
        surface: NotesContract.surface(NotesContract.v110) { s in
            var summarize = NotesContract.summarize
            summarize.result = .entity("Note")
            NotesContract.replaceIntent("SummarizeNote", in: &s, with: summarize)
        })

    static let all = [renameForgotAlias, renameWithAlias, namespacedWithShim, namespacedNoShim,
                      requiredFolderMinor, requiredFolderBackfilled, removeArchiveOnSchedule, summaryBecomesEntity]

    static let lab = ContractLab(baseline: baseline, proposals: all, plans: plans)
}

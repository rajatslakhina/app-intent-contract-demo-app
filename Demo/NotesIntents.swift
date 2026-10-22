import AppIntents

// Real App Intents for the demo's notes domain. Their type names are the
// stable identifiers Shortcuts and Siri persist, which is why the contract in
// NotesContract.swift derives its identifiers from these types instead of
// retyping the strings.
//
// Static requirements are computed properties on purpose: they hold no global
// state, so they are concurrency-safe in Swift 6 language mode.

enum NoteColor: String, AppEnum {
    case yellow, blue, green

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Note Color" }
    static var caseDisplayRepresentations: [NoteColor: DisplayRepresentation] {
        [.yellow: "Yellow", .blue: "Blue", .green: "Green"]
    }
}

struct Note: AppEntity {
    let id: String

    // Published properties: exactly the `title` and `tags` the contract declares.
    @Property(title: "Title")
    var title: String

    @Property(title: "Tags")
    var tags: [String]

    init(id: String, title: String, tags: [String] = []) {
        self.id = id
        self.title = title
        self.tags = tags
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Note" }
    static var defaultQuery: NoteQuery { NoteQuery() }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
}

struct NoteQuery: EntityQuery {
    /// v1.0 identifiers are integers, exactly as the published contract says.
    static var sample: [Note] {
        [Note(id: "3", title: "Groceries"), Note(id: "7", title: "Standup"),
         Note(id: "42", title: "Release checklist"), Note(id: "108", title: "Ideas")]
    }

    func entities(for identifiers: [Note.ID]) async throws -> [Note] {
        Self.sample.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [Note] { Self.sample }
}

struct OpenNote: AppIntent {
    static var title: LocalizedStringResource { "Open Note" }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Note")
    var note: Note

    func perform() async throws -> some IntentResult { .result() }
}

struct CreateNote: AppIntent {
    static var title: LocalizedStringResource { "Create Note" }

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Body")
    var body: String?

    @Parameter(title: "Color", default: .yellow)
    var color: NoteColor

    func perform() async throws -> some IntentResult & ReturnsValue<Note> {
        .result(value: Note(id: "109", title: title))
    }
}

import DesignSystem
import SwiftUI

struct NotesView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: NotesViewModel

    init(repository: any NoteRepository, titleSuggester: any NoteTitleSuggesting) {
        // Evaluated on every init but kept only once: keep this initializer free of side effects.
        _viewModel = State(initialValue: NotesViewModel(repository: repository, titleSuggester: titleSuggester))
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            List {
                Section {
                    ForEach(viewModel.notes) { note in
                        NavigationLink(value: note.id) {
                            NoteRow(note: note)
                        }
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                Task { await viewModel.delete(note) }
                            }
                            Button(note.isPinned ? "Unpin" : "Pin", systemImage: "pin") {
                                Task { await viewModel.togglePin(note) }
                            }
                        }
                    }
                } header: {
                    if !viewModel.notes.isEmpty {
                        Text("\(viewModel.stats.total) notes, \(viewModel.stats.pinned) pinned")
                    }
                }
            }
            .overlay {
                if !viewModel.hasLoaded {
                    ProgressView()
                } else if viewModel.notes.isEmpty {
                    ContentUnavailableView("No Notes", systemImage: "note.text", description: Text("Tap + to add one."))
                }
            }
            .navigationTitle("Notes")
            .navigationDestination(for: Note.ID.self) { id in
                NoteDetailView(note: viewModel.notes.first { $0.id == id })
            }
            .toolbar {
                Button("Add Note", systemImage: "plus") { router.isAddingNote = true }
            }
            .sheet(isPresented: $router.isAddingNote) {
                NoteEditorView(
                    onSave: { title, body in await viewModel.add(title: title, body: body) },
                    suggestTitle: { body in await viewModel.suggestTitle(for: body) }
                )
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.observe() }
    }
}

private struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: Space.s) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(2)
                if note.isPinned {
                    StatusBadge("Pinned", systemImage: "pin.fill")
                }
            }
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, Space.xs)
    }
}

private struct NoteDetailView: View {
    let note: Note?

    var body: some View {
        if let note {
            ScrollView {
                Text(note.body.isEmpty ? String(localized: "No content") : note.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Space.l)
            }
            .navigationTitle(note.title)
        } else {
            ContentUnavailableView("Note Not Found", systemImage: "questionmark.folder")
        }
    }
}

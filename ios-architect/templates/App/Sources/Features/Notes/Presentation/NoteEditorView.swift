import SwiftUI

struct NoteEditorView: View {
    /// Returns a user-facing error message, or nil on success. Errors show here because an alert
    /// attached to the presenting view cannot appear while this sheet is up.
    let onSave: (String, String) async -> String?
    let suggestTitle: (String) async -> String

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Body", text: $bodyText, axis: .vertical)
                        .lineLimit(4...)
                }
                if !bodyText.isEmpty {
                    Button("Suggest Title", systemImage: "sparkles") {
                        Task {
                            isWorking = true
                            title = await suggestTitle(bodyText)
                            isWorking = false
                        }
                    }
                    .disabled(isWorking)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isWorking = true
                            errorMessage = await onSave(title, bodyText)
                            isWorking = false
                            if errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(isWorking)
                }
            }
        }
    }
}

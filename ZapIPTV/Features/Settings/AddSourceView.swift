import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum SourceTypeTab: String, CaseIterable, Identifiable {
    case m3u, xtream, local
    var id: String { rawValue }
    var titleKey: String { "source.type.\(rawValue)" }
}

struct AddSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager

    @State private var selectedType: SourceTypeTab = .m3u
    @State private var name = ""
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false

    var canAdd: Bool {
        !name.isEmpty && !url.isEmpty &&
        (selectedType != .xtream || (!username.isEmpty && !password.isEmpty))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.t("add.title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ZapColor.textPrimary)
                    Text(loc.t("add.subtitle"))
                        .font(.system(size: 13))
                        .foregroundColor(ZapColor.textTertiary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(ZapColor.textSecondary)
                        .padding(8)
                        .background(ZapColor.surface2, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider().background(ZapColor.border)

            HStack(spacing: 0) {
                ForEach(SourceTypeTab.allCases) { tab in
                    Button(action: { selectedType = tab }) {
                        Text(loc.t(tab.titleKey))
                            .font(.system(size: 13, weight: selectedType == tab ? .semibold : .regular))
                            .foregroundColor(selectedType == tab ? ZapColor.textPrimary : ZapColor.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedType == tab
                                ? LinearGradient(colors: [ZapColor.accentStart.opacity(0.3), ZapColor.accentEnd.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(ZapColor.surface2)
            .cornerRadius(10)
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 14) {
                    FormField(label: loc.t("add.name"), placeholder: loc.t("add.name.ph"), text: $name)

                    switch selectedType {
                    case .m3u:
                        FormField(label: loc.t("add.m3u"), placeholder: "https://example.com/playlist.m3u", text: $url)
                    case .xtream:
                        FormField(label: loc.t("add.server"), placeholder: "http://server.com:8080", text: $url)
                        FormField(label: loc.t("add.user"), placeholder: loc.t("add.user"), text: $username)
                        FormField(label: loc.t("add.pass"), placeholder: loc.t("add.pass"), text: $password, isSecure: true)
                    case .local:
                        HStack {
                            Text(loc.t("add.local"))
                                .font(.system(size: 13))
                                .foregroundColor(ZapColor.textSecondary)
                            Spacer()
                            Button(loc.t("add.browse")) { browseFile() }
                                .buttonStyle(.plain)
                                .foregroundColor(ZapColor.accentStart)
                        }
                        .padding(.horizontal, 24)
                        if !url.isEmpty {
                            Text(url)
                                .font(.system(size: 11))
                                .foregroundColor(ZapColor.textTertiary)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.vertical, 16)
            }

            Divider().background(ZapColor.border)

            HStack {
                Button(loc.t("add.cancel")) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(ZapColor.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ZapColor.surface2)
                    .cornerRadius(8)

                Spacer()

                Button(action: addSource) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView().scaleEffect(0.7).tint(.white)
                        }
                        Text(isLoading ? loc.t("add.adding") : loc.t("add.ok"))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        canAdd
                        ? LinearGradient(colors: [ZapColor.accentStart, ZapColor.accentEnd], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!canAdd || isLoading)
            }
            .padding(24)
        }
        .frame(width: 480)
        .background(ZapColor.bg)
    }

    private func addSource() {
        isLoading = true
        let sourceType: PlaylistSource.SourceType
        switch selectedType {
        case .m3u: sourceType = .m3u
        case .xtream: sourceType = .xtream
        case .local: sourceType = .local
        }

        let source = PlaylistSource(
            name: name,
            type: sourceType,
            url: url,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password
        )
        sourceManager.addSource(source)
        dismiss()
    }

    private func browseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "m3u")!, UTType(filenameExtension: "m3u8")!]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let fileURL = panel.url {
            url = fileURL.path
            if name.isEmpty { name = fileURL.deletingPathExtension().lastPathComponent }
        }
    }
}

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ZapColor.textTertiary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .foregroundColor(ZapColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(ZapColor.surface2)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ZapColor.border, lineWidth: 1))
        }
        .padding(.horizontal, 24)
    }
}

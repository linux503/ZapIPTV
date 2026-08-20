import SwiftUI

struct PlayerSheetView: View {
    let url: URL
    let title: String
    @ObservedObject var engine: PlayerEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            VideoPlayerView(engine: engine, onClose: { dismiss() })
        }
        .frame(minWidth: 800, minHeight: 450)
        .onAppear { engine.load(url: url) }
        .onDisappear { engine.stop() }
    }
}

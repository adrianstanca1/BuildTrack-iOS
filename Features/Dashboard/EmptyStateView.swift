import SwiftUI
struct EmptyStateView: View { let icon: String; let title: String; let message: String; var body: some View { VStack { Image(systemName: icon).font(.largeTitle); Text(title).font(.headline); Text(message).font(.caption).foregroundStyle(.secondary) }.padding() } }

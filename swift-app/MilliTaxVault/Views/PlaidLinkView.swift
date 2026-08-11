import SwiftUI

struct PlaidLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status: Status = .idle

    enum Status: Equatable { case idle, loading, linked, failed(String) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(MilliPalette.accent.opacity(0.15)).frame(width: 96, height: 96)
                    Image(systemName: "building.columns.fill").font(.system(size: 40)).foregroundStyle(MilliPalette.accent)
                }.padding(.top, 40)

                Text("Connect your bank").font(.title2.weight(.bold)).foregroundStyle(MilliPalette.textPrimary)
                Text("Milli uses Plaid to securely link your accounts. Your credentials are never stored on our servers.")
                    .font(.footnote).foregroundStyle(MilliPalette.textSecondary).multilineTextAlignment(.center).padding(.horizontal)

                statusView
                Spacer()

                Button { Task { await connect() } } label: {
                    HStack {
                        if status == .loading { ProgressView().tint(.black) }
                        Text("Continue with Plaid").font(.headline)
                    }.frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(MilliPalette.accent)).foregroundStyle(.black)
                }.disabled(status == .loading).padding()
            }
            .background(MilliPalette.background.ignoresSafeArea())
            .navigationTitle("Connected Banks").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    @ViewBuilder private var statusView: some View {
        switch status {
        case .linked:
            Label("Bank linked", systemImage: "checkmark.seal.fill").foregroundStyle(MilliPalette.positive)
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill").foregroundStyle(MilliPalette.negative).font(.footnote)
        default:
            EmptyView()
        }
    }

    private func connect() async {
        status = .loading
        do {
            // 1) Ask the backend for a Plaid Link token.
            let token = try await PlaidService.shared.createLinkToken()
            _ = token
            // 2) In production, present the Plaid Link SDK with this token and
            //    receive a public token from the completion handler.
            let publicToken = "public-sandbox-placeholder"
            // 3) Exchange the public token server-side for a stored access token.
            let ok = try await PlaidService.shared.exchange(publicToken: publicToken)
            status = ok ? .linked : .failed("Could not link account")
        } catch {
            status = .failed((error as? LocalizedError)?.errorDescription ?? "Something went wrong")
        }
    }
}

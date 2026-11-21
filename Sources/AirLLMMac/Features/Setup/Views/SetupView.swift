import SwiftUI

/// The first-launch installer page. It also doubles as the "You're all set" page.
struct SetupView: View {
    @Environment(AppState.self) private var state
    @State private var showLog = false

    var body: some View {
        let setup = state.setup
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 26) {
                    header(finished: setup.finished)
                    checklist(setup.steps)
                    if let failure = setup.failure {
                        Text(failure)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)
                    }
                    DisclosureGroup(isExpanded: $showLog) {
                        LogView(lines: setup.log).frame(height: 170)
                    } label: {
                        Text("Details").font(.callout).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            Divider()
            SetupFooter()
        }
        .frame(minWidth: 620, minHeight: 600)
    }

    private func header(finished: Bool) -> some View {
        VStack(spacing: 10) {
            AirLLMLogo(height: 96)
            Text(finished ? "You're all set" : "Set up AirLLM")
                .font(.title2.weight(.semibold))
            Text(finished
                 ? "AirLLM, PyTorch and MLX are installed on this Mac."
                 : "Everything installs locally, in this app's own folder. Nothing touches your system Python.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 36)
    }

    private func checklist(_ steps: [SetupStep]) -> some View {
        VStack(spacing: 0) {
            ForEach(steps) { step in
                SetupStepRow(step: step)
                if step.id != steps.last?.id { Divider().padding(.leading, 44) }
            }
        }
        .padding(.vertical, 6)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Progress bar plus the one button that moves setup forward.
private struct SetupFooter: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let setup = state.setup
        HStack(spacing: 12) {
            if setup.isRunning || setup.progress > 0 {
                ProgressView(value: setup.progress).frame(maxWidth: 200)
                Text("\(Int(setup.progress * 100))%")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if setup.needsCommandLineTools {
                Button("Install Tools") { setup.installCommandLineTools() }
            }
            if setup.finished {
                Button("Start Chatting") { state.finishSetup() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button(buttonTitle(setup)) { setup.run(settings: state.settings) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(setup.isRunning)
            }
        }
        .padding(16)
    }

    private func buttonTitle(_ setup: SetupRunner) -> String {
        if setup.isRunning { return "Installing…" }
        return setup.failure != nil ? "Retry" : "Install"
    }
}

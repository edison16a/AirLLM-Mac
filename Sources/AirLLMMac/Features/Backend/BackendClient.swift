import Foundation

/// HTTP calls to the local server. Stateless, so the controller owns all app state.
struct BackendClient {
    var baseURL: URL

    func health() async -> BackendHealth? {
        var request = URLRequest(url: baseURL.appendingPathComponent("health"))
        request.timeoutInterval = 2
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(BackendHealth.self, from: data)
    }

    /// Returns a message for the user when the server refuses the load.
    func load(_ body: [String: Any]) async -> String? {
        do {
            let (data, response) = try await post("load", body)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return code < 300 ? nil : Self.errorMessage(data) ?? "Loading failed (\(code))."
        } catch {
            return error.localizedDescription
        }
    }

    func unload() async { _ = try? await post("unload", [:]) }
    func stop() async { _ = try? await post("stop", [:]) }

    /// Streams a reply. Cancelling the consuming task closes the connection, and the
    /// server treats a closed connection as Stop.
    func chat(_ payload: [String: Any]) -> AsyncThrowingStream<ChatEvent, Error> {
        let url = baseURL.appendingPathComponent("chat")
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = try Self.jsonRequest(url, payload)
                    request.timeoutInterval = 6 * 60 * 60  // a huge model can take minutes per token
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    guard code == 200 else {
                        var data = Data()
                        for try await b in bytes { data.append(b) }
                        continuation.yield(.error(Self.errorMessage(data) ?? "Request failed (\(code))."))
                        continuation.finish()
                        return
                    }
                    let started = Date()
                    for try await line in bytes.lines {
                        if let event = ChatEventParser.parse(line, startedAt: started) { continuation.yield(event) }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func post(_ path: String, _ body: [String: Any]) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: Self.jsonRequest(baseURL.appendingPathComponent(path), body))
    }

    private static func jsonRequest(_ url: URL, _ body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func errorMessage(_ data: Data) -> String? {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
    }
}

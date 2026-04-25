import Foundation

protocol iCloudAvailabilityServiceProtocol: Sendable {
    func currentToken() -> AnyHashable?
    var identityChanges: AsyncStream<Void> { get }
}

final class SystemICloudAvailabilityService: iCloudAvailabilityServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    private var observer: NSObjectProtocol?

    var identityChanges: AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock {
                continuations[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.continuations[id] = nil
                }
            }
        }
    }

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .NSUbiquityIdentityDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.yieldIdentityChange()
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        lock.withLock {
            continuations.values.forEach { $0.finish() }
            continuations.removeAll()
        }
    }

    func currentToken() -> AnyHashable? {
        guard let token = FileManager.default.ubiquityIdentityToken else { return nil }
        return AnyHashable(String(describing: token))
    }

    private func yieldIdentityChange() {
        let current = lock.withLock {
            Array(continuations.values)
        }
        current.forEach { $0.yield(()) }
    }
}

final class FakeICloudAvailabilityService: iCloudAvailabilityServiceProtocol, @unchecked Sendable {
    var token: AnyHashable?
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    var identityChanges: AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock {
                continuations[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.continuations[id] = nil
                }
            }
        }
    }

    init(initialToken: AnyHashable? = nil) {
        token = initialToken
    }

    func currentToken() -> AnyHashable? {
        token
    }

    func triggerIdentityChange() {
        let current = lock.withLock {
            Array(continuations.values)
        }
        current.forEach { $0.yield(()) }
    }
}

import XCTest
@testable import MilliTaxVault

final class TreasuryExecutionTests: XCTestCase {

    private final class FakeProvider: TreasuryProviderPort, @unchecked Sendable {
        enum Behavior { case succeed; case transportError }

        var behavior: Behavior = .succeed
        var delayNanoseconds: UInt64 = 0

        private let lock = NSLock()
        private var _initiateCallCount = 0

        var initiateCallCount: Int {
            lock.lock(); defer { lock.unlock() }
            return _initiateCallCount
        }

        func initiateAllocation(reference: String, amountCents: Int64) async throws -> String {
            lock.lock()
            _initiateCallCount += 1
            lock.unlock()

            if delayNanoseconds > 0 {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }

            switch behavior {
            case .succeed:
                return "stripe_\(reference)"
            case .transportError:
                throw URLError(.notConnectedToInternet)
            }
        }

        func fetchState(reference: String) async throws -> TreasuryMovementState {
            .processing
        }
    }

    func testDetectionIsIdempotent() async {
        let service = TreasuryExecutionService(provider: FakeProvider())
        let a = await service.recordDetection(reference: "pmt_1", amountCents: 4_311)
        let b = await service.recordDetection(reference: "pmt_1", amountCents: 4_311)
        XCTAssertEqual(a, b)
    }

    func testHappyPathDetectedProcessingAllocated() async throws {
        let service = TreasuryExecutionService(provider: FakeProvider())
        _ = await service.recordDetection(reference: "pmt_1", amountCents: 4_311)
        let processing = try await service.executeAllocation(reference: "pmt_1")
        XCTAssertEqual(processing.state, .processing)
        let allocated = try await service.applyProviderState(reference: "pmt_1", state: .allocated)
        XCTAssertEqual(allocated.state, .allocated)
    }

    func testConcurrentAllocationRetriesInitiateProviderOnlyOnce() async throws {
        let provider = FakeProvider()
        provider.delayNanoseconds = 100_000_000
        let service = TreasuryExecutionService(provider: provider)
        _ = await service.recordDetection(reference: "pmt_1", amountCents: 4_311)

        async let first = service.executeAllocation(reference: "pmt_1")
        async let retry = service.executeAllocation(reference: "pmt_1")

        let firstResult = try await first
        let retryResult = try await retry

        XCTAssertEqual(firstResult.state, .processing)
        XCTAssertEqual(retryResult.state, .processing)
        XCTAssertEqual(provider.initiateCallCount, 1, "concurrent retries must not duplicate money movement")
    }

    func testRepeatedAuthoritativeProviderStateIsIdempotent() async throws {
        let service = TreasuryExecutionService(provider: FakeProvider())
        _ = await service.recordDetection(reference: "pmt_1", amountCents: 100)
        let firstProcessing = try await service.executeAllocation(reference: "pmt_1")
        let repeatedProcessing = try await service.applyProviderState(reference: "pmt_1", state: .processing)

        XCTAssertEqual(repeatedProcessing, firstProcessing)

        let allocated = try await service.applyProviderState(reference: "pmt_1", state: .allocated)
        let repeatedAllocated = try await service.applyProviderState(reference: "pmt_1", state: .allocated)
        XCTAssertEqual(repeatedAllocated, allocated)
    }

    func testTransportFailureIsUnavailableNotFailed() async throws {
        let provider = FakeProvider()
        provider.behavior = .transportError
        let service = TreasuryExecutionService(provider: provider)
        _ = await service.recordDetection(reference: "pmt_1", amountCents: 100)
        do {
            _ = try await service.executeAllocation(reference: "pmt_1")
            XCTFail("should throw")
        } catch let error as TreasuryExecutionError {
            guard case .providerUnavailable = error else {
                return XCTFail("wrong error")
            }
        }
        let record = await service.currentState(reference: "pmt_1")
        XCTAssertEqual(record?.state, .unavailable, "transport failure resolves to UNAVAILABLE, not FAILED")
    }

    func testIllegalTransitionRejected() async throws {
        let service = TreasuryExecutionService(provider: FakeProvider())
        _ = await service.recordDetection(reference: "pmt_1", amountCents: 100)
        do {
            _ = try await service.applyProviderState(reference: "pmt_1", state: .reversed)
            XCTFail("should throw")
        } catch let error as TreasuryExecutionError {
            XCTAssertEqual(error, .invalidTransition(from: .detected, to: .reversed))
        }
        let record = await service.currentState(reference: "pmt_1")
        XCTAssertEqual(record?.state, .detected, "state untouched on invalid transition")
    }

    func testUnknownMovementRejected() async {
        let service = TreasuryExecutionService(provider: FakeProvider())
        do {
            _ = try await service.executeAllocation(reference: "ghost")
            XCTFail("should throw")
        } catch let error as TreasuryExecutionError {
            XCTAssertEqual(error, .unknownMovement("ghost"))
        } catch {
            XCTFail("wrong error type")
        }
    }

    func testStateMachineMatrix() {
        XCTAssertTrue(TreasuryStateMachine.canTransition(.detected, to: .processing))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.processing, to: .allocated))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.allocated, to: .reversed))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.processing, to: .returned))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.failed, to: .actionRequired))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.actionRequired, to: .processing))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.allocated, to: .unavailable))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.detected, to: .allocated))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.detected, to: .reversed))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.failed, to: .allocated))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.reversed, to: .processing))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.allocated, to: .detected))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.processing, to: .processing),
                       "self transitions remain illegal at state-machine level; service handles duplicate delivery as no-op")
    }
}

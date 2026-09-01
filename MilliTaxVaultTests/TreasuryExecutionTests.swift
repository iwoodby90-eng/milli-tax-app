import XCTest
@testable import MilliTaxVault

final class TreasuryExecutionTests: XCTestCase {

    /// Deterministic fake provider. Never simulates success — only replays
    /// what the test explicitly configures, exactly like a real adapter.
    private final class FakeProvider: TreasuryProviderPort, @unchecked Sendable {
        enum Behavior { case succeed; case transportError }
        var behavior: Behavior = .succeed
        func initiateAllocation(reference: String, amountCents: Int64) async throws -> String {
            switch behavior {
            case .succeed: return "stripe_\(reference)"
            case .transportError: throw URLError(.notConnectedToInternet)
            }
        }
        func fetchState(reference: String) async throws -> TreasuryMovementState { .processing }
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

    func testTransportFailureIsUnavailableNotFailed() async throws {
        let provider = FakeProvider()
        provider.behavior = .transportError
        let service = TreasuryExecutionService(provider: provider)
        _ = await service.recordDetection(reference: "pmt_1", amountCents: 100)
        do {
            _ = try await service.executeAllocation(reference: "pmt_1")
            XCTFail("should throw")
        } catch let error as TreasuryExecutionError {
            guard case .providerUnavailable = error else { return XCTFail("wrong error") }
        }
        let record = await service.currentState(reference: "pmt_1")
        XCTAssertEqual(record?.state, .unavailable, "never started → UNAVAILABLE, not FAILED")
    }

    func testIllegalTransitionRejected() async throws {
        let service = TreasuryExecutionService(provider: FakeProvider())
        _ = await service.recordDetection(reference: "pmt_1", amountCents: 100)
        // DETECTED → REVERSED is illegal (nothing was ever allocated)
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
        // v2.1 legal transitions
        XCTAssertTrue(TreasuryStateMachine.canTransition(.detected, to: .processing))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.processing, to: .allocated))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.allocated, to: .reversed))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.processing, to: .returned))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.failed, to: .actionRequired))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.actionRequired, to: .processing))
        XCTAssertTrue(TreasuryStateMachine.canTransition(.allocated, to: .unavailable))
        // Illegal ones
        XCTAssertFalse(TreasuryStateMachine.canTransition(.detected, to: .allocated))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.detected, to: .reversed))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.failed, to: .allocated))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.reversed, to: .processing))
        XCTAssertFalse(TreasuryStateMachine.canTransition(.allocated, to: .detected))
    }
}

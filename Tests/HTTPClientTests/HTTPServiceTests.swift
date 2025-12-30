import HTTPClient
import Foundation
import Testing

@Suite("HTTPService Tests")
struct HTTPServiceTests {
    @Test func `Error on bad input`() async {
        let client = MockClient()
        let service = HTTPService(client: client) {
            $0.mock.shouldFailEncoding = true
        }
        do {
            _ = try await service.mock(with: UUID())
            Issue.record("Expected .badInput error")
        } catch let error as HTTPEndpointCallError {
            guard case .badInput(let underlyingError) = error,
                  underlyingError is EncodingError else {
                Issue.record("Expected .badInput(EncodingError), got \(error)")
                return
            }
        } catch {
            Issue.record("Expected HTTPEndpointCallError, got \(error)")
        }
    }

    @Test func `Error on rejected request`() async {
        let client = MockClient()
        client.shouldRejectRequest = true
        let service = HTTPService(client: client)
        do {
            _ = try await service.mock(with: UUID())
            Issue.record("Expected .rejectedRequest error")
        } catch let error as HTTPEndpointCallError {
            guard case .rejectedRequest(let underlyingError) = error,
                  underlyingError is RejectedRequestError else {
                Issue.record("Expected .rejectedRequest(RejectedRequestError), got \(error)")
                return
            }
        } catch {
            Issue.record("Expected HTTPEndpointCallError, got \(error)")
        }
    }

    @Test func `Error on network failure`() async {
        let client = MockClient()
        let expectedError = URLError(.cannotConnectToHost)
        client.urlError = expectedError
        let service = HTTPService(client: client)
        do {
            _ = try await service.mock(with: UUID())
            Issue.record("Expected .networkFailure error")
        } catch let error as HTTPEndpointCallError {
            guard case .networkFailure(underlyingError: expectedError) = error else {
                Issue.record("Expected .networkFailure(URLError), got \(error)")
                return
            }
        } catch {
            Issue.record("Expected HTTPEndpointCallError, got \(error)")
        }
    }

    @Test func `Error on HTTP failure`() async {
        let client = MockClient()
        let response = HTTPResponse(status: .unauthorized, body: .plain(UUID().uuidString))
        client.response = response
        let service = HTTPService(client: client)
        do {
            _ = try await service.mock(with: UUID())
            Issue.record("Expected .httpError")
        } catch let error as HTTPEndpointCallError {
            guard case .httpError(response: response) = error else {
                Issue.record("Expected .httpError(HTTPResponse), got \(error)")
                return
            }
        } catch {
            Issue.record("Expected HTTPEndpointCallError, got \(error)")
        }
    }

    @Test func `Error parsing response`() async {
        let client = MockClient()
        let service = HTTPService(client: client) {
            $0.mock.shouldFailDecoding = true
        }
        do {
            _ = try await service.mock(with: UUID())
            Issue.record("Expected .badResponse error")
        } catch let error as HTTPEndpointCallError {
            guard case .badResponse(let underlyingError) = error,
                  underlyingError is DecodingError else {
                Issue.record("Expected .badResponse(DecodingError), got \(error)")
                return
            }
        } catch {
            Issue.record("Expected HTTPEndpointCallError, got \(error)")
        }
    }

    @Test func Succeeding() async throws {
        let client = MockClient()
        let expected = UUID()
        let service = HTTPService(client: client) {
            $0.mock.output = expected
        }
        let actual = try await service.mock(with: UUID())
        #expect(actual == expected)
    }

    @Test func `Succeeding with no input`() async throws {
        let client = MockClient()
        let expected = UUID()
        let service = HTTPService(client: client) {
            $0.noInputMock.output = expected
        }
        let actual = try await service.noInputMock
        #expect(actual == expected)
    }
}

private final class MockClient: HTTPClient, @unchecked Sendable {
    var shouldRejectRequest = false
    var urlError: URLError?
    var response = HTTPResponse.ok(with: .empty)

    func perform(_ request: HTTPRequest) async throws -> HTTPResponse {
        if shouldRejectRequest {
            throw HTTPRequestPerformingError.rejectedRequest(underlyingError: RejectedRequestError())
        }
        if let error = urlError {
            throw HTTPRequestPerformingError.networkFailure(underlyingError: error)
        }

        return response
    }
}

extension HTTPService where Endpoints == MockEndpoints {
    fileprivate convenience init(client: HTTPClient, configure: (inout MockEndpoints) -> Void = { _ in }) {
        var endpoints = MockEndpoints()
        configure(&endpoints)
        self.init(client: client, endpoints: endpoints)
    }
}

private struct MockEndpoints {
    var mock = MockEndpoint()
    var noInputMock = NoInputMockEndpoint()
}

private struct MockEndpoint: HTTPEndpoint {
    var shouldFailEncoding = false
    var shouldFailDecoding = false
    var output = UUID()
    func request(for input: UUID) throws -> HTTPRequest {
        if shouldFailEncoding {
            throw EncodingError()
        } else {
            return .get("")
        }
    }

    func parse(_ response: HTTPResponse) throws -> UUID {
        if shouldFailDecoding {
            throw DecodingError()
        } else {
            return output
        }
    }
}

private struct NoInputMockEndpoint: HTTPEndpoint {
    var output = UUID()
    func request(for input: Void) throws -> HTTPRequest {
        .get("")
    }

    func parse(_ response: HTTPResponse) throws -> UUID {
        output
    }
}

private struct EncodingError: Error {}
private struct RejectedRequestError: Error {}
private struct DecodingError: Error {}

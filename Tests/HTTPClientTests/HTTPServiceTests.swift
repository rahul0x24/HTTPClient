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
        let result = await service.mock(with: UUID())
        guard case .failure(.badInput(let underlyingError)) = result,
              underlyingError is EncodingError else {
            Issue.record("Expected .failure(.badInput(EncodingError)), got \(result)")
            return
        }
    }

    @Test func `Error on rejected request`() async {
        let client = MockClient()
        client.shouldRejectRequest = true
        let service = HTTPService(client: client)
        let result = await service.mock(with: UUID())
        guard case .failure(.rejectedRequest(let underlyingError)) = result,
              underlyingError is RejectedRequestError else {
            Issue.record("Expected .failure(.rejectedRequest(RejectedRequestError)), got \(result)")
            return
        }
    }

    @Test func `Error on network failure`() async {
        let client = MockClient()
        let error = URLError(.cannotConnectToHost)
        client.urlError = error
        let service = HTTPService(client: client)
        let result = await service.mock(with: UUID())
        guard case .failure(.networkFailure(underlyingError: error)) = result else {
            Issue.record("Expected .failure(.networkFailure(URLError)), got \(result)")
            return
        }
    }

    @Test func `Error on HTTP failure`() async {
        let client = MockClient()
        let response = HTTPResponse(status: .unauthorized, body: .plain(UUID().uuidString))
        client.response = response
        let service = HTTPService(client: client)
        let result = await service.mock(with: UUID())
        guard case .failure(.httpError(response: response)) = result else {
            Issue.record("Expected .failure(.httpError(HTTPResponse)), got \(result)")
            return
        }
    }

    @Test func `Error parsing response`() async {
        let client = MockClient()
        let service = HTTPService(client: client) {
            $0.mock.shouldFailDecoding = true
        }
        let result = await service.mock(with: UUID())
        guard case .failure(.badResponse(let underlyingError)) = result,
              underlyingError is DecodingError else {
            Issue.record("Expected .failure(.badResponse(DecodingError)), got \(result)")
            return
        }
    }

    @Test func Succeeding() async throws {
        let client = MockClient()
        let expected = UUID()
        let service = HTTPService(client: client) {
            $0.mock.output = expected
        }
        let result = await service.mock(with: UUID())
        let actual = try result.get()
        #expect(actual == expected)
    }

    @Test func `Succeeding with no input`() async throws {
        let client = MockClient()
        let expected = UUID()
        let service = HTTPService(client: client) {
            $0.noInputMock.output = expected
        }
        let result = await service.noInputMock
        let actual = try result.get()
        #expect(actual == expected)
    }
}

private final class MockClient: HTTPClient, @unchecked Sendable {
    var shouldRejectRequest = false
    var urlError: URLError?
    var response = HTTPResponse.ok(with: .empty)

    func perform(_ request: HTTPRequest) async -> Result<HTTPResponse, HTTPRequestPerformingError> {
        if shouldRejectRequest {
            return .failure(.rejectedRequest(underlyingError: RejectedRequestError()))
        }
        if let error = urlError {
            return .failure(.networkFailure(underlyingError: error))
        }

        return .success(response)
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

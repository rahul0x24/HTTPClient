import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPClient
import Testing

@Suite("URLSessionHTTPClient Tests")
struct URLSessionHTTPClientTests {
    @Test func `Client uses the injected URLSession`() async throws {
        let remote = HTTPRemote(host: "example.com", path: "")
        let data = UUID().uuidString.data(using: .utf8)!
        let session = MockURLSession(
            data: data,
            response: HTTPURLResponse(url: try! remote.url(for: .get(""), scheme: .https), statusCode: 200, httpVersion: nil, headerFields: nil)!,
        )
        let client = URLSessionHTTPClient(remote: remote, session: session)

        let request = HTTPRequest.get("")
        let response = try await client.perform(request)
        #expect(response.body.content == data)
    }

    @Test func `Client handles non-HTTP response gracefully`() async throws {
        let remote = HTTPRemote(host: "example.com", path: "")
        // Create a non-HTTPURLResponse (e.g., file:// URL response)
        let fileURL = URL(fileURLWithPath: "/tmp/test")
        let nonHTTPResponse = URLResponse(url: fileURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let session = MockURLSession(
            data: Data(),
            response: nonHTTPResponse,
        )
        let client = URLSessionHTTPClient(remote: remote, session: session)

        let request = HTTPRequest.get("")
        do {
            _ = try await client.perform(request)
            Issue.record("Expected error to be thrown")
        } catch let error as HTTPRequestPerformingError {
            guard case .networkFailure(let urlError) = error,
                  urlError.code == .badServerResponse else {
                Issue.record("Expected .networkFailure(.badServerResponse), got \(error)")
                return
            }
        } catch {
            Issue.record("Expected HTTPRequestPerformingError, got \(error)")
        }
    }

    @Test func `Client converts non-URLError to URLError`() async throws {
        struct CustomError: Error {}

        let remote = HTTPRemote(host: "example.com", path: "")
        let session = MockURLSessionWithError(error: CustomError())
        let client = URLSessionHTTPClient(remote: remote, session: session)

        let request = HTTPRequest.get("")
        do {
            _ = try await client.perform(request)
            Issue.record("Expected error to be thrown")
        } catch let error as HTTPRequestPerformingError {
            guard case .networkFailure(let urlError) = error,
                  urlError.code == .unknown else {
                Issue.record("Expected .networkFailure(.unknown), got \(error)")
                return
            }
        } catch {
            Issue.record("Expected HTTPRequestPerformingError, got \(error)")
        }
    }

    @Test func `Client calls interceptor on success`() async throws {
        let remote = HTTPRemote(host: "example.com", path: "")
        let data = Data()
        let session = MockURLSession(
            data: data,
            response: HTTPURLResponse(url: try! remote.url(for: .get(""), scheme: .https), statusCode: 200, httpVersion: nil, headerFields: nil)!,
        )
        let interceptor = MockInterceptor()
        let client = URLSessionHTTPClient(remote: remote, session: session, interceptor: interceptor)

        let request = HTTPRequest.get("")
        _ = try? await client.perform(request)

        #expect(interceptor.willPerformCalled)
        #expect(interceptor.didSucceedCalled)
        #expect(!interceptor.didFailCalled)
        #expect(interceptor.lastResponse != nil)
    }

    @Test func `Client calls interceptor on failure`() async throws {
        let remote = HTTPRemote(host: "example.com", path: "")
        let session = MockURLSessionWithError(error: URLError(.notConnectedToInternet))
        let interceptor = MockInterceptor()
        let client = URLSessionHTTPClient(remote: remote, session: session, interceptor: interceptor)

        let request = HTTPRequest.get("")
        _ = try? await client.perform(request)

        #expect(interceptor.willPerformCalled)
        #expect(!interceptor.didSucceedCalled)
        #expect(interceptor.didFailCalled)
        #expect(interceptor.lastError != nil)
    }

    @Test func `Client handles various HTTP status codes`() async throws {
        let remote = HTTPRemote(host: "example.com", path: "")
        let statusCodes = [100, 200, 201, 301, 302, 400, 404, 500, 503]

        for statusCode in statusCodes {
            let session = MockURLSession(
                data: Data(),
                response: HTTPURLResponse(url: try! remote.url(for: .get(""), scheme: .https), statusCode: statusCode, httpVersion: nil, headerFields: nil)!,
            )
            let client = URLSessionHTTPClient(remote: remote, session: session)

            let request = HTTPRequest.get("")
            let response = try await client.perform(request)
            #expect(response.status.code == statusCode)
        }
    }
}

// MARK: - Test Helpers

private struct MockURLSession: URLSessionProtocol {
    var data: Data
    var response: URLResponse

    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        (data, response)
    }
}

private struct MockURLSessionWithError: URLSessionProtocol {
    var error: Error

    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        throw error
    }
}

private final class MockInterceptor: RequestInterceptor, @unchecked Sendable {
    var willPerformCalled = false
    var didSucceedCalled = false
    var didFailCalled = false
    var lastResponse: HTTPResponse?
    var lastError: HTTPRequestPerformingError?

    func willPerform(_ request: HTTPRequest) {
        willPerformCalled = true
    }

    func didSucceed(_ request: HTTPRequest, response: HTTPResponse) {
        didSucceedCalled = true
        lastResponse = response
    }

    func didFail(_ request: HTTPRequest, error: HTTPRequestPerformingError) {
        didFailCalled = true
        lastError = error
    }
}

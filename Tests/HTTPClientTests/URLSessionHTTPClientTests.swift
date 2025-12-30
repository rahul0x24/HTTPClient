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
            response: HTTPURLResponse(url: try! remote.url(for: .get(""), scheme: .https), statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
        let client = URLSessionHTTPClient(remote: remote, session: session)

        let request = HTTPRequest.get("")
        let response = try await client.perform(request).get()
        #expect(response.body.content == data)
    }

}

// MARK: - Test Helpers

private struct MockURLSession: URLSessionProtocol {

    var data: Data
    var response: HTTPURLResponse

    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        (data, response)
    }

}

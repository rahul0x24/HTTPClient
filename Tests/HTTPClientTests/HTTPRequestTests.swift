import Foundation
import Testing
@testable import HTTPClient

@Suite("HTTPRequest Tests")
struct HTTPRequestTests {
    @Test func `Can create request with empty path`() {
        _ = HTTPRequest(method: .get, path: "", body: nil)
    }

    @Test func `Can create request if path starts with slash`() {
        _ = HTTPRequest(method: .get, path: "/somewhere", body: nil)
    }

    @Test func `Can create request if path is just slash`() {
        _ = HTTPRequest(method: .get, path: "/", body: nil)
    }

#if os(macOS)
    @Test func `Cannot create request if path does not start with slash`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRequest(method: .get, path: "somewhere", body: nil)
        }
    }

    @Test func `Cannot create request with Content-Type header`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRequest(method: .get, path: "", body: nil, headerFields: [.contentType: "a"])
        }
    }

    @Test func `Cannot create request with Content-Length header`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRequest(method: .get, path: "", body: nil, headerFields: [.contentLength: "a"])
        }
    }

    @Test func `Cannot create POST request without body`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRequest(method: .post, path: "", body: nil)
        }
    }

    @Test func `Cannot create GET request with body`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRequest(method: .get, path: "", body: .empty())
        }
    }
#endif
}

// MARK: - Test Helpers

private extension HTTPRequest.Body {
    static func empty() -> HTTPRequest.Body {
        .plain("")
    }
}

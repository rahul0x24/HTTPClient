import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import HTTPClient
import HTTPTypes
import Testing

@Suite("HTTPRemote Tests")
struct HTTPRemoteTests {
    // MARK: - Creating Remotes

    @Test func `Can create remote with empty path`() {
        _ = HTTPRemote(host: "example.com", path: "")
    }

    @Test func `Can create remote if path starts with slash`() {
        _ = HTTPRemote(host: "example.com", path: "/somewhere")
    }

    @Test func `Can create remote if path is just slash`() {
        _ = HTTPRemote(host: "example.com", path: "/")
    }

#if os(macOS)
    @Test func `Cannot create remote if path does not start with slash`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRemote(host: "example.com", path: "somewhere")
        }
    }

    @Test func `Cannot pre-set Content-Length header`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRemote(host: "example.com", path: "/somewhere", headerFields: [.contentLength: "a"])
        }
    }

    @Test func `Cannot pre-set Content-Type header`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRemote(host: "example.com", path: "/somewhere", headerFields: [.contentType: "a"])
        }
    }

    @Test func `Cannot pre-set Content-Type header with different case`() async {
        await #expect(processExitsWith: .failure) {
            _ = HTTPRemote(host: "example.com", path: "/somewhere", headerFields: [.contentType: "a"])
        }
    }
#endif

    // MARK: - Creating Requests

    @Test func `Creating request without body`() throws {
        let remote = HTTPRemote(
            host: "example.com",
            path: "/service/v1",
            port: 9000,
            user: "user",
            password: "password",
            headerFields: [HTTPField.Name("client_id")!: "1"]
        )

        let request = HTTPRequest(
            method: .delete,
            path: "/destination",
            body: nil,
            fragment: "subpage",
            queryParameters: ["query": "value"],
            headerFields: [HTTPField.Name("state")!: "1234"]
        )

        let actual = try remote.urlRequest(from: request)
        let components = mutating(URLComponents()) {
            $0.scheme = "https"
            $0.host = "example.com"
            $0.path = "/service/v1/destination"
            $0.fragment = "subpage"
            $0.port = 9000
            $0.user = "user"
            $0.password = "password"
            $0.queryItems = [
                URLQueryItem(name: "query", value: "value"),
            ]
        }
        let expected = mutating(URLRequest(url: components.url!)) {
            $0.httpMethod = "DELETE"
            $0.addValue("1", forHTTPHeaderField: "client_id")
            $0.addValue("1234", forHTTPHeaderField: "state")
        }
        #expect(actual == expected)
    }

    @Test func `Creating request with all parts set`() throws {
        let remote = HTTPRemote(
            host: "example.com",
            path: "/service/v1",
            port: 9000,
            user: "user",
            password: "password",
            queryParameters: ["remote-query": "remote-value"],
            headerFields: [HTTPField.Name("client_id")!: "1"]
        )

        let request = HTTPRequest.post(
            "/destination",
            body: .plain("body"),
            fragment: "subpage",
            queryParameters: ["query": "value"],
            headerFields: [HTTPField.Name("state")!: "1234"]
        )

        let actual = try remote.urlRequest(from: request)
        let components = mutating(URLComponents()) {
            $0.scheme = "https"
            $0.host = "example.com"
            $0.path = "/service/v1/destination"
            $0.fragment = "subpage"
            $0.port = 9000
            $0.user = "user"
            $0.password = "password"
            $0.queryItems = [
                URLQueryItem(name: "remote-query", value: "remote-value"),
                URLQueryItem(name: "query", value: "value"),
            ]
        }
        let expected = mutating(URLRequest(url: components.url!)) {
            $0.httpMethod = "POST"
            $0.addValue("1", forHTTPHeaderField: "client_id")
            $0.addValue("1234", forHTTPHeaderField: "state")
            $0.addValue("text/plain", forHTTPHeaderField: "content-type")
            $0.addValue("4", forHTTPHeaderField: "content-length")
            $0.httpBody = "body".data(using: .utf8)
        }
        #expect(actual == expected)
    }

    @Test func `No query item marker is set if there is none`() throws {
        let remote = HTTPRemote(
            host: "example.com",
            path: ""
        )

        let request = HTTPRequest.get("/path")

        let actual = try remote.urlRequest(from: request)
        let expected = URLRequest(url: URL(string: "https://example.com/path")!)
        #expect(actual == expected)
    }

    @Test func `Default query parameter merge policy disallows overrides (case insensitive)`() {
        let remote = HTTPRemote(
            host: "example.com",
            path: "",
            queryParameters: ["Query": "true"]
        )

        let request = HTTPRequest.get("/path", queryParameters: ["query": "false"])

        #expect(throws: Error.self) {
            try remote.urlRequest(from: request)
        }
    }

    @Test func `Updating query parameter merge policy works`() throws {
        var remote = HTTPRemote(
            host: "example.com",
            path: "",
            queryParameters: ["Query": "true"]
        )

        remote.queryParametersMergePolicy = .custom { remoteParameters, _ in remoteParameters }

        let request = HTTPRequest.get("/path", queryParameters: ["query": "false"])

        let urlRequest = try remote.urlRequest(from: request)
        #expect(urlRequest.url?.query == "Query=true")
    }

    @Test func `Default header merge policy disallows overrides`() {
        let headerName = HTTPField.Name("verbose")!
        let remote = HTTPRemote(
            host: "example.com",
            path: "",
            headerFields: [headerName: "true"]
        )

        let request = HTTPRequest.get("/path", headerFields: [headerName: "false"])

        #expect(throws: Error.self) {
            try remote.urlRequest(from: request)
        }
    }

    @Test func `Updating header merge policy works`() throws {
        let headerName = HTTPField.Name("verbose")!
        var remote = HTTPRemote(
            host: "example.com",
            path: "",
            headerFields: [headerName: "true"]
        )

        remote.headersMergePolicy = .custom { remoteHeaders, _ in remoteHeaders }

        let request = HTTPRequest.get("/path", headerFields: [headerName: "false"])

        let urlRequest = try remote.urlRequest(from: request)
        #expect(urlRequest.allHTTPHeaderFields?.count == 1)
        #expect(urlRequest.value(forHTTPHeaderField: headerName.canonicalName) == "true")
    }

}

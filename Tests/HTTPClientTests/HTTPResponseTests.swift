import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPClient
import Testing
import HTTPTypes

@Suite("HTTPResponse Tests")
struct HTTPResponseTests {

    @Test func `Creating from HTTPURLResponse`() {
        let url = URL(string: "https://example.com")!
        let urlResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "content-type": "text/plain",
                "Accept": "value",
            ]
        )!
        let body = "body".data(using: .utf8)!
        let actual = HTTPResponse(httpUrlResponse: urlResponse, bodyContent: body)
        let expected = HTTPResponse(
            status: .ok,
            body: HTTPResponse.Body(content: body, type: "text/plain"),
            headerFields: [
                HTTPField.Name.accept: "value",
            ]
        )
        #expect(actual == expected)
    }

    @Test func `Creating from HTTPURLResponse with mixed case Content-Type`() {
        let url = URL(string: "https://example.com")!
        let urlResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "Content-Type": "text/plain",
                "accept": "value",
            ]
        )!
        let body = "body".data(using: .utf8)!
        let actual = HTTPResponse(httpUrlResponse: urlResponse, bodyContent: body)
        let expected = HTTPResponse(
            status: .ok,
            body: HTTPResponse.Body(content: body, type: "text/plain"),
            headerFields: [
                HTTPField.Name.accept: "value",
            ]
        )
        #expect(actual == expected)
    }

    @Test func `Creating from HTTPURLResponse without Content-Type`() {
        let url = URL(string: "https://example.com")!
        let urlResponse = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: [
                "Accept": "value",
            ]
        )!
        let body = "body".data(using: .utf8)!
        let actual = HTTPResponse(httpUrlResponse: urlResponse, bodyContent: body)
        let expected = HTTPResponse(
            status: .notFound,
            body: HTTPResponse.Body(content: body, type: nil),
            headerFields: [
                HTTPField.Name.accept: "value",
            ]
        )
        #expect(actual == expected)
    }

}

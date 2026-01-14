import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A protocol for intercepting and observing HTTP requests and responses.
///
/// Implement this protocol to add logging, metrics, tracing, or other observability features to your HTTP client.
///
/// Example:
/// ```swift
/// struct LoggingInterceptor: RequestInterceptor {
///     func willPerform(_ request: URLRequest) {
///         print("→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
///     }
///
///     func didSucceed(_ request: URLRequest, data: Data, response: HTTPURLResponse) {
///         print("← \(response.statusCode)")
///     }
///
///     func didFail(_ request: URLRequest, error: Error) {
///         print("✗ \(error)")
///     }
/// }
/// ```
public protocol RequestInterceptor: Sendable {
    /// Called immediately before a request is performed.
    ///
    /// Use this method to log outgoing requests, start timing metrics, or initialize tracing spans.
    ///
    /// - Parameter request: The URLRequest about to be performed
    func willPerform(_ request: URLRequest)

    /// Called immediately after a request succeeds.
    ///
    /// Use this method to log successful responses, record metrics, or finalize tracing spans.
    ///
    /// - Parameters:
    ///   - request: The URLRequest that was performed
    ///   - data: The response body data
    ///   - response: The HTTP response received
    func didSucceed(_ request: URLRequest, data: Data, response: HTTPURLResponse)

    /// Called immediately after a request fails.
    ///
    /// Use this method to log errors, record failure metrics, or finalize tracing spans.
    ///
    /// - Parameters:
    ///   - request: The URLRequest that was performed
    ///   - error: The error that occurred
    func didFail(_ request: URLRequest, error: Error)
}

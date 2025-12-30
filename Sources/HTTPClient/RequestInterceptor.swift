import Foundation

/// A protocol for intercepting and observing HTTP requests and responses.
///
/// Implement this protocol to add logging, metrics, tracing, or other observability features to your HTTP client.
///
/// Example:
/// ```swift
/// struct LoggingInterceptor: RequestInterceptor {
///     func willPerform(_ request: HTTPRequest) {
///         print("→ \(request.method.rawValue) \(request.path)")
///     }
///
///     func didSucceed(_ request: HTTPRequest, response: HTTPResponse) {
///         print("← \(response.status)")
///     }
///
///     func didFail(_ request: HTTPRequest, error: HTTPRequestPerformingError) {
///         print("✗ \(error)")
///     }
/// }
/// ```
public protocol RequestInterceptor: Sendable {
    /// Called immediately before a request is performed.
    ///
    /// Use this method to log outgoing requests, start timing metrics, or initialize tracing spans.
    ///
    /// - Parameter request: The request about to be performed
    func willPerform(_ request: HTTPRequest)

    /// Called immediately after a request succeeds.
    ///
    /// Use this method to log successful responses, record metrics, or finalize tracing spans.
    ///
    /// - Parameters:
    ///   - request: The request that was performed
    ///   - response: The HTTP response received
    func didSucceed(_ request: HTTPRequest, response: HTTPResponse)

    /// Called immediately after a request fails.
    ///
    /// Use this method to log errors, record failure metrics, or finalize tracing spans.
    ///
    /// - Parameters:
    ///   - request: The request that was performed
    ///   - error: The error that occurred
    func didFail(_ request: HTTPRequest, error: HTTPRequestPerformingError)
}

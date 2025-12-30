import Foundation

/// Provides an asynchronous API for making network request calls against a specific remote.
///
/// Each instance of `HTTPClient` is configured to talk to a specific remote (e.g. on a certain remote host and path, and has the necessary auth credentials).
/// The `HTTPClient` may perform app-specific behaviours. For example, it may perform additional security checks, or collect metrics around network failures.
///
/// Normally, how the client performs a request is opaque to the caller. However, specific implementations in an app may define additional behaviour.
public protocol HTTPClient: Sendable {
    /// Performs the `request` and returns the response.
    ///
    /// There are two different reasons the operation may fail:
    /// * The `HTTPClient` itself may reject the request. For example, as a security measure, it may disallow any requests that override the auth token.
    ///   In these cases, the client will throw ``HTTPRequestPerformingError/rejectedRequest(underlyingError:)``.
    /// * The `HTTPClient` attempts to perform the request, but it fails for other reasons. For example, the network connect might time out, or the response may fail integrity checks done by the client.
    ///   In these cases, the client will throw ``HTTPRequestPerformingError/networkFailure(underlyingError:)``.
    ///
    /// Note that receiving an HTTP response with an error code (e.g. 500) does not normally cause a failure.
    /// Consumers of this API should check for any HTTP failures and process the response accordingly.
    ///
    /// - Parameter request: The request to perform
    /// - Returns: The HTTP response
    /// - Throws: ``HTTPRequestPerformingError`` if the request fails
    func perform(_ request: HTTPRequest) async throws -> HTTPResponse
}

extension HTTPClient {
    /// Fetches data from the endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to call
    ///   - input: The input data for the endpoint
    /// - Returns: The parsed output from the endpoint
    /// - Throws: ``HTTPEndpointCallError`` if the request fails
    func fetch<E: HTTPEndpoint>(_ endpoint: E, with input: E.Input) async throws -> E.Output {
        let request: HTTPRequest
        do {
            request = try endpoint.request(for: input)
        } catch {
            throw HTTPEndpointCallError.badInput(underlyingError: error)
        }

        let response: HTTPResponse
        do {
            response = try await perform(request)
        } catch let error as HTTPRequestPerformingError {
            throw HTTPEndpointCallError(error: error)
        }

        guard response.status.kind == .successful else {
            throw HTTPEndpointCallError.httpError(response: response)
        }

        do {
            return try endpoint.parse(response)
        } catch {
            throw HTTPEndpointCallError.badResponse(underlyingError: error)
        }
    }
}

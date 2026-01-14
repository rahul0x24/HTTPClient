import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A concrete implementation of `HTTPClient` that uses `URLSession` to make the HTTP calls.
public final class URLSessionHTTPClient: HTTPClient, Sendable {
    private let remote: URLRequestProviding
    private let session: URLSessionProtocol
    private let interceptor: (any RequestInterceptor)?

    /// Creates a new HTTP client for the specified `remote`. The client will use `session` to perform network calls.
    ///
    /// When performing a request.
    /// * If `remote` throws an error when creating a `URLRequest`, the client forwards the error as ``HTTPRequestPerformingError/rejectedRequest(underlyingError:)``.
    /// * Any error returned by `session` is forwarded as ``HTTPRequestPerformingError/networkFailure(underlyingError:)``.
    ///
    /// - Parameters:
    ///   - remote: The specification for a remote service.
    ///   - session: The underlying session that the client should use.
    ///   - interceptor: Optional interceptor for observing requests and responses.
    public init(remote: URLRequestProviding, session: URLSessionProtocol = URLSession.shared, interceptor: (any RequestInterceptor)? = nil) {
        self.remote = remote
        self.session = session
        self.interceptor = interceptor
    }

    public func perform(_ request: HTTPRequest) async throws -> HTTPResponse {
        do {
            let urlRequest: URLRequest
            do {
                urlRequest = try remote.urlRequest(from: request)
            } catch {
                throw HTTPRequestPerformingError.rejectedRequest(underlyingError: error)
            }

            // Notify interceptor that request is about to be performed
            interceptor?.willPerform(urlRequest)

            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await session.data(for: urlRequest, delegate: nil)
            } catch {
                throw HTTPRequestPerformingError.fromUntypedNetworkError(error)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPRequestPerformingError.networkFailure(underlyingError: URLError(.badServerResponse))
            }

            let httpResponseObj = HTTPResponse(httpUrlResponse: httpResponse, bodyContent: data)

            // Notify interceptor of success before returning
            interceptor?.didSucceed(urlRequest, data: data, response: httpResponse)

            return httpResponseObj
        } catch let error as HTTPRequestPerformingError {
            // Notify interceptor of failure (we need the URLRequest here, so we try to create it again)
            if let urlRequest = try? remote.urlRequest(from: request) {
                interceptor?.didFail(urlRequest, error: error)
            }
            throw error
        }
    }
}

extension HTTPRequestPerformingError {
    /// Create an `HTTPRequestError` from the networking error provided.
    ///
    /// URLSession typically returns `URLError` instances, but the API is untyped.
    /// For any non-URLError, we wrap it as an unknown URLError to maintain consistency.
    fileprivate static func fromUntypedNetworkError(_ error: Error) -> HTTPRequestPerformingError {
        if let error = error as? URLError {
            return .networkFailure(underlyingError: error)
        } else {
            return .networkFailure(underlyingError: URLError(.unknown))
        }
    }
}

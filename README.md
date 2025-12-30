# HTTPClient

A modern, type-safe HTTP networking library for Swift that leverages protocol-oriented design and the power of Swift's type system.

## Features

- **Type-Safe Endpoints** - Define endpoints with compile-time type safety using generics
- **Protocol-Oriented** - Highly testable and flexible architecture
- **Modern Swift** - Swift 6 compatible with async/await and Sendable
- **Async/Await Error Handling** - Clean, intuitive error handling with Swift's native async/await
- **Service-Level Configuration** - Centralize host, auth, headers, and query parameters
- **Ergonomic API** - Dynamic member lookup for clean, intuitive endpoint calls
- **Cross-Platform** - Supports macOS, iOS, tvOS, watchOS, and Linux

## Requirements

- Swift 6.2+
- macOS 10.13+, iOS 12+, tvOS 12+, watchOS 4+, or Linux

## Installation

### Swift Package Manager

Add HTTPClient to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rahul0x24/HTTPClient.git", from: "0.1.0")
]
```

## Quick Start

```swift
import HTTPClient
import HTTPTypes

// 1. Define your endpoint
struct GetUser: HTTPEndpoint {
    typealias Input = Int  // User ID
    typealias Output = User

    func request(for userId: Int) throws -> HTTPRequest {
        try .get(path: "/users/\(userId)")
    }

    func parse(_ response: HTTPResponse) throws -> User {
        let decoder = JSONDecoder()
        return try decoder.decode(User.self, from: response.body.content)
    }
}

// 2. Configure your service
let remote = HTTPRemote(
    host: "api.example.com",
    path: "/v1",
    headerFields: HTTPFields([
        .authorization: "Bearer YOUR_TOKEN"
    ])
)

let client = URLSessionHTTPClient(remote: remote)
let service = HTTPService(client: client)

// 3. Make requests
do {
    let user = try await service.GetUser(with: 123)
    print("User: \(user.name)")
} catch {
    print("Error: \(error)")
}
```

## Usage

### Defining Endpoints

Endpoints conform to the `HTTPEndpoint` protocol:

```swift
struct CreatePost: HTTPEndpoint {
    struct Input {
        let title: String
        let content: String
    }

    typealias Output = Post

    func request(for input: Input) throws -> HTTPRequest {
        let body = try HTTPRequest.Body.json(input)
        return try .post(path: "/posts", body: body)
    }

    func parse(_ response: HTTPResponse) throws -> Post {
        try JSONDecoder().decode(Post.self, from: response.body.content)
    }
}
```

### Endpoints Without Input

For endpoints that don't need input, use `Void`:

```swift
struct ListPosts: HTTPEndpoint {
    typealias Input = Void
    typealias Output = [Post]

    func request(for input: Void) throws -> HTTPRequest {
        try .get(path: "/posts")
    }

    func parse(_ response: HTTPResponse) throws -> [Post] {
        try JSONDecoder().decode([Post].self, from: response.body.content)
    }
}

// Call without arguments
let posts = try await service.ListPosts
```

### Service Configuration

Configure service-level settings with `HTTPRemote`:

```swift
let remote = HTTPRemote(
    host: "api.example.com",
    path: "/api/v1",
    port: 443,
    queryParameters: ["client_id": "your_client_id"],
    headerFields: HTTPFields([
        .authorization: "Bearer TOKEN",
        .userAgent: "MyApp/1.0"
    ])
)
```

### Request Configuration

Configure request-specific settings:

```swift
func request(for input: Input) throws -> HTTPRequest {
    let body = try HTTPRequest.Body.json(input)
    return try .post(
        path: "/posts",
        body: body,
        queryParameters: ["include": "author"],
        headerFields: HTTPFields([.accept: "application/json"])
    )
}
```

### Error Handling

HTTPClient uses Swift's native async/await error handling with comprehensive error types:

```swift
do {
    let post = try await service.CreatePost(with: input)
    print("Created: \(post.id)")
} catch let error as HTTPEndpointCallError {
    switch error {
    case .badInput(let err):
        // Failed to encode input
        print("Input encoding failed: \(err)")

    case .rejectedRequest(let err):
        // Request was rejected (invalid configuration)
        print("Request rejected: \(err)")

    case .networkFailure(let err):
        // Network error (no connection, timeout, etc.)
        print("Network error: \(err)")

    case .httpError(let response):
        // HTTP error status (4xx, 5xx)
        print("HTTP \(response.status): \(response.body)")

    case .badResponse(let err):
        // Failed to parse response
        print("Response parsing failed: \(err)")
    }
} catch {
    print("Unexpected error: \(error)")
}

### Custom HTTP Methods

HTTPClient supports all standard HTTP methods:

```swift
try .get(path: "/resource")
try .post(path: "/resource", body: body)
try .put(path: "/resource", body: body)
try .patch(path: "/resource", body: body)
try .delete(path: "/resource")
try .options(path: "/resource")
try .head(path: "/resource")
```

### Observability with Request Interceptors

Add logging, metrics, or tracing by implementing the `RequestInterceptor` protocol:

```swift
struct LoggingInterceptor: RequestInterceptor {
    func willPerform(_ request: HTTPRequest) {
        print("→ \(request.method.rawValue) \(request.path)")
    }

    func didSucceed(_ request: HTTPRequest, response: HTTPResponse) {
        print("← \(response.status)")
    }

    func didFail(_ request: HTTPRequest, error: HTTPRequestPerformingError) {
        print("✗ \(error)")
    }
}

// Use the interceptor
let client = URLSessionHTTPClient(
    remote: remote,
    interceptor: LoggingInterceptor()
)
```

Interceptors are useful for:
- **Logging** - Log all requests and responses for debugging
- **Metrics** - Track request duration, success/failure rates
- **Tracing** - Integrate with distributed tracing systems
- **Debugging** - Inspect requests in development environments

### Testing

Mock your endpoints and clients for testing:

```swift
struct MockClient: HTTPClient {
    var response: HTTPResponse

    func perform(_ request: HTTPRequest) async throws -> HTTPResponse {
        response
    }
}

func testEndpoint() async throws {
    let mockResponse = HTTPResponse(/* ... */)
    let client = MockClient(response: mockResponse)
    let service = HTTPService(client: client)

    let user = try await service.GetUser(with: 123)
    // Assert on user
}
```

## Architecture

HTTPClient uses a layered architecture:

- **HTTPClient Protocol** - Core contract for making HTTP requests
- **HTTPEndpoint Protocol** - Type-safe endpoint definitions
- **HTTPService** - High-level API with dynamic member lookup
- **HTTPRemote** - Service-level configuration
- **URLSessionHTTPClient** - Concrete URLSession-based implementation

## License

See [LICENSE](LICENSE) for details.

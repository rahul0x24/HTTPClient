import Foundation
import HTTPClient
import Testing

@Suite("URLScheme Tests")
struct URLSchemeTests {

    @Test func `Equality is case insensitive`() {
        #expect(URLScheme("SCHEME") == URLScheme("scheme"))
    }

}

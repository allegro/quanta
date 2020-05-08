#if os(Linux)

import XCTest
import SwiftTestReporter
@testable import QuantaTests


_ = TestObserver()

XCTMain([
    // AppTests
    testCase(HomeControllerTests.allTests),
    testCase(OptimizeControllerTests.allTests),
    testCase(PerformanceTests.allTests),
])

#endif

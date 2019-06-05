//
//  SvrfSDKTests.swift
//  SvrfSDKTests
//
//  Created by Andrei Evstratenko on 05/11/2018.
//  Copyright © 2018 Svrf, Inc. All rights reserved.
//

import XCTest

@testable import SvrfSDK

private var token: String?

class SvrfSDKTests: XCTestCase {

    private let correctApiKey = "f6de923045ee225bbaa237c973228e5a"
    private let incorrectApiKey = "incorrectApiKey"
    private let requestTimeOut: Double = 30
    private let singleSearchQuery = "S"

    override func setUp() {
        super.setUp()

        SvrfAPIManager.authenticate(with: correctApiKey, onSuccess: { authenticationResponse in

            guard let token = authenticationResponse.token else { return }
            SvrfAPIManager.setToken(token)
        }) { _ in
        }
    }

    // MARK: - private functions
    private func authenticate(withApiKey apiKey: String,
                              success: @escaping (_ response: SvrfAuthenticationResponse) -> Void,
                              failure: @escaping (_ error: Error?) -> Void) {

        SvrfAPIManager.authenticate(with: apiKey, onSuccess: { authenticationResponse in
            success(authenticationResponse)
        }, onFailure: { error in
            failure(error)
        })
    }

    private func search(query: String,
                        options: SvrfOptions?,
                        success: @escaping (_ response: SvrfSearchResponse) -> Void,
                        failure: @escaping (_ error: Error?) -> Void) {

        _ = SvrfAPIManager.search(query: query, options: options, onSuccess: { searchResponse in
            success(searchResponse)
        }, onFailure: { error in
            failure(error)
        })
    }

    private func getTrending(options: SvrfOptions?,
                             success: @escaping (_ response: SvrfTrendingResponse) -> Void,
                             failure: @escaping (_ error: Error?) -> Void) {

        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            success(trendingResponse)
        }, onFailure: { error in
            failure(error)
        })
    }

    private func getById(id: String,
                         success: @escaping (_ response: SvrfMediaResponse) -> Void,
                         failure: @escaping (_ error: Error?) -> Void) {

        _ = SvrfAPIManager.getMedia(by: id, onSuccess: { mediaResponse in
            success(mediaResponse)
        }, onFailure: { error in
            failure(error)
        })
    }

    func testAuthenticationWithIncorrectApiKey() {

        let promise = expectation(description: "Authentication with incorrect API key")
        authenticate(withApiKey: incorrectApiKey, success: { authenticationResponse in

            if authenticationResponse.success == true {
                XCTFail("Authenticated with wrong API key")
            }
            promise.fulfill()
        }, failure: { _ in
            promise.fulfill()
        })
        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    // MARK: - Authentication Tests
    func testAuthenticationWithCorrectApiKey() {

        let promise = expectation(description: "Authentication with correct API key")
        authenticate(withApiKey: correctApiKey, success: { authenticationResponse in

            if authenticationResponse.success == false {
                XCTFail("Authentication failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Authentication failed")
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    // MARK: - Search Methods Tests
    func testSearchMethodWithEmptyQuery() {

        let promise = expectation(description: "Search with emty query")
        search(query: "", options: nil, success: { searchResponse in
            if searchResponse.success == true {
                XCTFail("Search success with empty")
            }
            promise.fulfill()
        }, failure: { _ in
            promise.fulfill()
        })
        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWithNotEmptyQuery() {

        let promise = expectation(description: "Search with query")
        search(query: singleSearchQuery, options: nil, success: { searchMediaResponse in
            if searchMediaResponse.success == false {
                XCTFail("Search with query failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with query failed")

            promise.fulfill()
        })
        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWithMultipleParameters() {

        let promise = expectation(description: "Search with multiple parameters")

        let options = SvrfOptions(type: [.photo], size: 1)
        search(query: singleSearchQuery, options: options, success: { _ in
            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with muptiple parameters failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWithPhotoType() {

        let promise = expectation(description: "Search with photo type")

        let options = SvrfOptions(type: [.photo])
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            var isOnlySearchedType = true

            if let mediaArray = searchResponse.media {
                for mediaObject in mediaArray where mediaObject.type != SvrfMediaType.photo {
                    isOnlySearchedType = false
                }

                XCTAssertTrue(isOnlySearchedType, "Search with photo type failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with photo type failed")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWithVideoType() {

        let promise = expectation(description: "Search with video type")

        let options = SvrfOptions(type: [.video])
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            var isOnlySearchedType = true

            if let mediaArray = searchResponse.media {
                for mediaObject in mediaArray where mediaObject.type != SvrfMediaType.video {
                    isOnlySearchedType = false
                }

                XCTAssertTrue(isOnlySearchedType, "Search with video type failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with photo type failed")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith3dType() {

        let promise = expectation(description: "Search with 3d type")

        let options = SvrfOptions(type: [._3d])
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            var isOnlySearchedType = true

            if let mediaArray = searchResponse.media {
                for mediaObject in mediaArray where mediaObject.type != SvrfMediaType._3d {
                    isOnlySearchedType = false
                }

                XCTAssertTrue(isOnlySearchedType, "Search with 3d type failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with 3d type failed")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWithMultipleTypes() {

        let promise = expectation(description: "Search with multiple types")

        let options = SvrfOptions(type: [.photo, .video])
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            var isOnlySearchedTypes = true

            if let mediaArray = searchResponse.media {
                for mediaObject in mediaArray where mediaObject.type == SvrfMediaType._3d {
                    isOnlySearchedTypes = false
                }

                XCTAssertFalse(isOnlySearchedTypes, "Search with multiple types failed")
            }

            promise.fulfill()
        }, failure: { _ in
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith5Size() {

        let promise = expectation(description: "Search with size = 5")

        let options = SvrfOptions(size: 5)
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            if let mediaArray = searchResponse.media {
                XCTAssertTrue(mediaArray.count <= 5, "Search with size = 5 failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with size = 5 failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith20Size() {

        let promise = expectation(description: "Search with size = 20")

        let options = SvrfOptions(size: 20)
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            if let mediaArray = searchResponse.media {
                XCTAssertTrue(mediaArray.count <= 20, "Search with size = 20 failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with size = 20 failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith50Size() {
        let promise = expectation(description: "Search with size = 50")

        let options = SvrfOptions(size: 50)
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            if let mediaArray = searchResponse.media {
                XCTAssertTrue(mediaArray.count <= 50, "Search with size = 50 failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with size = 50 failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith70Size() {

        let promise = expectation(description: "Search with size = 70")

        let options = SvrfOptions(size: 70)
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            if let mediaArray = searchResponse.media {
                XCTAssertTrue(mediaArray.count <= 70, "Search with size = 70 failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with size = 70 failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith100Size() {

        let promise = expectation(description: "Search with size = 100")

        let options = SvrfOptions(size: 100)
        search(query: singleSearchQuery, options: options, success: { searchResponse in
            if let mediaArray = searchResponse.media {
                XCTAssertTrue(mediaArray.count <= 100, "Search with size = 100 failed")
            }

            promise.fulfill()
        }, failure: { _ in
            XCTFail("Search with size = 100 failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith3Page() {

        let promise = expectation(description: "Search with page = 3")

        let options = SvrfOptions(pageNum: 3)
        _ = SvrfAPIManager.search(query: singleSearchQuery, options: options, onSuccess: { searchResponse in
            XCTAssertTrue(searchResponse.pageNum == 3, "Search with page = 3 failed")
            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Search with page = 3 failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testSearchMethodWith15Page() {

        let promise = expectation(description: "Search with page = 15")

        let options = SvrfOptions(pageNum: 15)
        _ = SvrfAPIManager.search(query: singleSearchQuery, options: options, onSuccess: { searchResponse in
            XCTAssertTrue(searchResponse.pageNum == 15, "Search with page = 15 failed")
            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Search with page = 15 failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    // MARK: - Trending Methods Tests
    func testGetTrendingWithoutParameters() {

        let promise = expectation(description: "Get trending without parameters")

        _ = SvrfAPIManager.getTrending(options: nil, onSuccess: { _ in
            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending without parameters failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWithPhotoType() {

        let promise = expectation(description: "Get trending with photo type")

        let options = SvrfOptions(type: [.photo])
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            var isOnlySearchedType = true

            if let mediaArray = trendingResponse.media {
                for mediaObject in mediaArray where mediaObject.type != SvrfMediaType.photo {
                    isOnlySearchedType = false
                }

                XCTAssertTrue(isOnlySearchedType, "Get trending with photo type failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with photo type failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWithVideoType() {

        let promise = expectation(description: "Get trending with video type")

        let options = SvrfOptions(type: [.video])
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            var isOnlySearchedType = true

            if let mediaArray = trendingResponse.media {
                for mediaObject in mediaArray where mediaObject.type != SvrfMediaType.video {
                    isOnlySearchedType = false
                }

                XCTAssertTrue(isOnlySearchedType, "Get trending with video type failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with video type failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWith3dType() {

        let promise = expectation(description: "Get trending with 3d type")

        let options = SvrfOptions(type: [._3d])
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            var isOnlySearchedType = true

            if let mediaArray = trendingResponse.media {
                for mediaObject in mediaArray where mediaObject.type != SvrfMediaType._3d {
                    isOnlySearchedType = false
                }

                XCTAssertTrue(isOnlySearchedType, "Get trending with 3d type failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with 3d type failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWithMultipleTypes() {

        let promise = expectation(description: "Get trending with multiple types")
        let options = SvrfOptions(type: [.video, .photo])
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            var isOnlySearchedTypes = true
            if let mediaArray = trendingResponse.media {
                for mediaObject in mediaArray where mediaObject.type == SvrfMediaType._3d {
                    isOnlySearchedTypes = false
                }
                XCTAssertFalse(isOnlySearchedTypes, "Get trending with multiple types failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWith5Size() {

        let promise = expectation(description: "Get trending with size = 5")

        let options = SvrfOptions(size: 5)
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            if let mediaArray = trendingResponse.media {
                XCTAssertTrue(mediaArray.count <= 5, "Get trending with size = 5 failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with size = 5")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWith20Size() {

        let promise = expectation(description: "Get trending with size = 20")

        let options = SvrfOptions(size: 20)
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            if let mediaArray = trendingResponse.media {
                XCTAssertTrue(mediaArray.count <= 20, "Get trending with size = 20 failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with size = 20")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWith50Size() {

        let promise = expectation(description: "Get trending with size = 50")

        let options = SvrfOptions(size: 50)
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            if let mediaArray = trendingResponse.media {
                XCTAssertTrue(mediaArray.count <= 50, "Get trending with size = 50 failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with size = 50")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWith70Size() {

        let promise = expectation(description: "Get trending with size = 70")

        let options = SvrfOptions(size: 70)
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            if let mediaArray = trendingResponse.media {
                XCTAssertTrue(mediaArray.count <= 70, "Get trending with size = 70 failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with size = 70")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWith100Size() {

        let promise = expectation(description: "Get trending with size = 100")

        let options = SvrfOptions(size: 100)
        _ = SvrfAPIManager.getTrending(options: options, onSuccess: { trendingResponse in
            if let mediaArray = trendingResponse.media {
                XCTAssertTrue(mediaArray.count <= 100, "Get trending with size = 100 failed")
            }

            promise.fulfill()
        }, onFailure: { _ in
            XCTFail("Get trending with size = 100")
            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    func testGetTrendingWithPageNum() {
        let promise = expectation(description: "Get trending with page num")

        _ = SvrfAPIManager.getTrending(options: nil, onSuccess: { trendingResponse in

            let options = SvrfOptions(pageNum: trendingResponse.pageNum)
            _ = SvrfAPIManager.getTrending(options: options, onSuccess: { _ in

                promise.fulfill()
            }, onFailure: { _ in
                XCTFail("Get trending with page num failed")
            })
        }, onFailure: { _ in
            XCTFail("Get trending with page num")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }

    // MARK: - Get media by id
    func testGetMediaById() {
        let promise = expectation(description: "Get media by id")

        _ = SvrfAPIManager.getTrending(options: nil, onSuccess: { trendingResponse in
            if let id = trendingResponse.media?.first?.id {
                _ = SvrfAPIManager.getMedia(by: id, onSuccess: { _ in

                    promise.fulfill()
                }, onFailure: { _ in
                    XCTFail("Get media by id failed")
                })
            } else {
                XCTFail("Get media by id failed")

                promise.fulfill()
            }
        }, onFailure: { _ in
            XCTFail("Get media by id failed")

            promise.fulfill()
        })

        waitForExpectations(timeout: requestTimeOut, handler: nil)
    }
}

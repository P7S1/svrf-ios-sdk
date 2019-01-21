//
//  SvrfSDK.swift
//  SvrfSDK
//
//  Created by Andrei Evstratenko on 12/11/2018.
//  Copyright © 2018 Svrf, Inc. All rights reserved.
//

import Foundation
import SVRFClient
import SvrfGLTFSceneKit
import Analytics
import SceneKit
import ARKit

public typealias SvrfMedia = Media

private enum ChildNode: String {
    case head = "Head"
    case occluder = "Occluder"
}

public class SvrfSDK: NSObject {

    private static let svrfApiKeyKey = "SVRF_API_KEY"
    private static let svrfXAppTokenKey = "x-app-token"
    private static let svrfAuthTokenKey = "SVRF_AUTH_TOKEN"
    private static let svrfAuthTokenExpireDateKey = "SVRF_AUTH_TOKEN_EXPIRE_DATE"
    private static let svrfAnalyticsKey = "J2bIzgOhVGqDQ9ZNqVgborNthH6bpKoA"

    private static let dispatchGroup = DispatchGroup()

    // MARK: public functions
    /**
     Authenticate your API Key with the Svrf API.
     
     - parameters:
     - onSuccess: Success closure.
     - onFailure: Failure closure.
     - error: A *SvrfError*.
     */
    public static func authenticate(onSuccess success: (() -> Void)? = nil,
                                    onFailure failure: ((_ error: SvrfError) -> Void)? = nil) {

        dispatchGroup.enter()

        setupAnalytics()

        if !needUpdateToken() {

            let authToken = String(data: (SvrfKeyChain.load(key: svrfAuthTokenKey))!, encoding: .utf8)!

            SVRFClientAPI.customHeaders = [svrfXAppTokenKey: authToken]

            if let success = success {
                success()
            }

            dispatchGroup.leave()

            return
        } else if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let apiKey = dict[svrfApiKeyKey] as? String {

            let body = Body(apiKey: apiKey)
            AuthenticateAPI.authenticate(body: body) { (authResponse, error) in

                if error != nil {
                    if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.response.rawValue,
                                          description: error?.localizedDescription))
                    }

                    dispatchGroup.leave()

                    return
                }

                if let authToken = authResponse?.token, let expireIn = authResponse?.expiresIn {

                    _ = SvrfKeyChain.save(key: svrfAuthTokenKey, data: Data(authToken.utf8))
                    UserDefaults.standard.set(getTokenExpireDate(expireIn: expireIn),
                                              forKey: svrfAuthTokenExpireDateKey)
                    SVRFClientAPI.customHeaders = [svrfXAppTokenKey: authToken]

                    if let success = success {
                        success()
                    }

                    dispatchGroup.leave()

                    return
                } else {
                    if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.Auth.responseNoToken.rawValue, description: nil))
                    }

                    dispatchGroup.leave()

                    return
                }
            }
        } else {
            if let failure = failure {
                failure(SvrfError(title: SvrfErrorTitle.Auth.apiKey.rawValue, description: nil))
            }

            dispatchGroup.leave()
        }
    }

    /**
     The Svrf Search Endpoint brings the power of immersive search found on [Svrf.com](https://www.svrf.com)
     to your app or project.
     Svrf's search engine enables your users to instantly find the immersive experience they're seeking.
     Content is sorted by the Svrf rating system, ensuring that the highest quality content and most
     prevalent search results are returned.

     - parameters:
     - query: Url-encoded search query.
     - options: Structure with parameters of search
     - onSuccess: Success closure.
     - mediaArray: An array of *Media* from the Svrf API.
     - onFailure: Error closure.
     - error: A *SvrfError*.
     */
    public static func search(query: String,
                              options: SearchOptions,
                              onSuccess success: @escaping (_ mediaArray: [Media]) -> Void,
                              onFailure failure: ((_ error: SvrfError) -> Void)? = nil) {

        dispatchGroup.notify(queue: .main) {

            MediaAPI.search(q: query,
                            type: options.type,
                            stereoscopicType: options.stereoscopicType?.rawValue,
                            category: options.category?.rawValue,
                            size: options.size,
                            pageNum: options.pageNum) { (searchMediaResponse, error) in

                if let error = error {
                    if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.response.rawValue,
                                          description: error.localizedDescription))
                    }
                } else {
                    if let mediaArray = searchMediaResponse?.media {
                        success(mediaArray)
                    } else if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.responseNoMediaArray.rawValue, description: nil))
                    }
                }
            }
        }
    }

    /**
     The Svrf Trending Endpoint provides your app or project with the hottest immersive content curated by real humans.
     The experiences returned mirror the [Svrf homepage](https://www.svrf.com), from timely cultural content
     to trending pop-culture references.
     The trending experiences are updated regularly to ensure users always get fresh updates of immersive content.
     
     - parameters:
     - options: Structure with parameters of trending
     - onSuccess: Success closure.
     - mediaArray: An array of *Media* from the Svrf API.
     - onFailure: Error closure.
     - error: A *SvrfError*.
     */
    public static func getTrending(options: TrendingOptions?,
                                   onSuccess success: @escaping (_ mediaArray: [Media]) -> Void,
                                   onFailure failure: ((_ error: SvrfError) -> Void)? = nil) {

        dispatchGroup.notify(queue: .main) {

            MediaAPI.getTrending(type: options?.type,
                                 stereoscopicType: options?.stereoscopicType?.rawValue,
                                 category: options?.category?.rawValue,
                                 size: options?.size,
                                 nextPageCursor: options?.nextPageCursor,
                                 completion: { (trendingResponse, error) in

                if let error = error {
                    if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.response.rawValue,
                                          description: error.localizedDescription))
                    }
                } else {
                    if let mediaArray = trendingResponse?.media {
                        success(mediaArray)
                    } else if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.responseNoMediaArray.rawValue, description: ""))
                    }
                }
            })
        }
    }

    /**
     Fetch SVRF media by its ID.
     
     - parameters:
     - id: ID of *Media* to fetch.
     - onSuccess: Success closure.
     - media: *Media* from the Svrf API.
     - onFailure: Error closure.
     - error: A *SvrfError*.
     */
    public static func getMedia(identifier: String,
                                onSuccess success: @escaping (_ media: Media) -> Void,
                                onFailure failure: ((_ error: SvrfError) -> Void)? = nil) {

        dispatchGroup.notify(queue: .main) {

            MediaAPI.getById(id: identifier, completion: { (singleMediaResponse, error) in

                if let error = error {
                    if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.response.rawValue,
                                          description: error.localizedDescription))
                    }
                } else {
                    if let media = singleMediaResponse?.media {
                        success(media)
                    } else if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.response.rawValue, description: nil))
                    }
                }
            })
        }
    }

    /**
     Generates a *SCNNode* for a *Media* with a *type* `_3d`. This method can used to generate
     the whole 3D model, but is not recommended for face filters.
     
     - attention: Face filters should be retrieved using the `getFaceFilter` method.
     - parameters:
     - media: The *Media* to generate the *SCNNode* from. The *type* must be `_3d`.
     - returns: SCNNode?
     */
    public static func getNodeFromMedia(media: Media,
                                        onSuccess success: @escaping (_ node: SCNNode) -> Void,
                                        onFailure failure: ((_ error: SvrfError) -> Void)? = nil) {

        if media.type == ._3d {
            if let scene = getSceneFromMedia(media: media) {
                success(scene.rootNode)
            } else if let failure = failure {
                failure(SvrfError(title: SvrfErrorTitle.getScene.rawValue, description: nil))
            }
        } else if let failure = failure {
            failure(SvrfError(title: SvrfErrorTitle.incorrectMediaType.rawValue, description: nil))
        }
    }

    /**
     Blend shape mapping allows SVRF's ARKit compatible face filters to have animations that
     are activated by your user's facial expressions.
     
     - Attention: This method enumerates through the node's hierarchy.
     Any children nodes with morpher targets that follow the
     [ARKit blend shape naming conventions]:
     (https://developer.apple.com/documentation/arkit/arfaceanchor/blendshapelocation) will be affected.
     - Note: The 3D animation terms "blend shapes", "morph targets", and "pose morphs" are often used interchangably.
     - parameters:
     - blendShapes: A dictionary of *ARFaceAnchor* blend shape locations and weights.
     - for: The node with morpher targets.
     */
    public static func setBlendShapes(blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber], for node: SCNNode) {

        node.enumerateHierarchy { (childNode, _) in

            for (blendShape, weight) in blendShapes {
                let targetName = blendShape.rawValue
                childNode.morpher?.setWeight(CGFloat(weight.floatValue), forTargetNamed: targetName)
            }
        }
    }

    /**
     The SVRF API allows you to access all of SVRF's ARKit compatible face filters and stream them directly to your app.
     Use the `getFaceFilter` method to stream a face filter to your app and convert it into a *SCNNode* in runtime.
     
     - parameters:
     - media: The *Media* to generate the face filter from. The *type* must be `_3d`.
     - returns: SCNNode
     */
    public static func getFaceFilter(with media: Media,
                                     onSuccess success: @escaping (_ faceFilter: SCNNode) -> Void,
                                     onFailure failure: ((_ error: SvrfError) -> Void)? = nil) {

            if media.type == ._3d, let glbUrlString = media.files?.glb, let glbUrl = URL(string: glbUrlString) {
                let modelSource = GLTFSceneSource(url: glbUrl)

                do {
                    let faceFilter = SCNNode()
                    let node = try modelSource.scene().rootNode

                    if let occluderNode = node.childNode(withName: ChildNode.occluder.rawValue, recursively: true) {
                        faceFilter.addChildNode(occluderNode)
                        setOccluderNode(node: occluderNode)
                    }

                    if let headNode = node.childNode(withName: ChildNode.head.rawValue, recursively: true) {
                        faceFilter.addChildNode(headNode)
                    }

                    faceFilter.morpher?.calculationMode = SCNMorpherCalculationMode.normalized

                    success(faceFilter)

                    SEGAnalytics.shared().track("Face Filter Node Requested",
                                                properties: ["media_id": media.id ?? "unknown"])
                } catch {
                    if let failure = failure {
                        failure(SvrfError(title: SvrfErrorTitle.getScene.rawValue,
                                          description: error.localizedDescription))
                    }
                }
            }
        }

        // MARK: private functions
        /**
         Renders a *SCNScene* from a *Media*'s glb file using *SvrfGLTFSceneKit*.
         
         - parameters:
         - media: The *Media* to return a *SCNScene* from.
         - returns: SCNScene?
         */
        private static func getSceneFromMedia(media: Media) -> SCNScene? {

            if let glbUrlString = media.files?.glb {
                if let glbUrl = URL(string: glbUrlString) {

                    let modelSource = GLTFSceneSource(url: glbUrl)

                    do {
                        let scene = try modelSource.scene()

                        SEGAnalytics.shared().track("3D Node Requested",
                                                    properties: ["media_id": media.id ?? "unknown"])

                        return scene
                    } catch {

                    }
                }
            }

            return nil
        }

        /**
         Checks if the Svrf authentication token has expired.
         
         - returns: Bool
         */
    private static func needUpdateToken() -> Bool {
        
        if let tokenExpirationDate = UserDefaults.standard.object(forKey: svrfAuthTokenExpireDateKey) as? Date,
            let receivedData = SvrfKeyChain.load(key: svrfAuthTokenKey),
            String(data: receivedData, encoding: .utf8) != nil {

            let twoDays = 172800
            if Int(Date().timeIntervalSince(tokenExpirationDate)) < twoDays {
                return false
            }
        }

        return true
    }

        /**
         Takes the `expireIn` value returned by the Svrf authentication endpoint and returns the expiration date.
         
         - parameters:
         - expireIn: The time until token expiration in seconds.
         - returns: Date
         */
        private static func getTokenExpireDate(expireIn: Int) -> Date {

            guard let timeInterval = TimeInterval(exactly: expireIn) else {
                return Date()
            }

            return Date().addingTimeInterval(timeInterval)
        }

        /**
         Setup Segment analytic event tracking.
         */
        private static func setupAnalytics() {

            let configuration = SEGAnalyticsConfiguration(writeKey: svrfAnalyticsKey)
            configuration.trackApplicationLifecycleEvents = true
            configuration.recordScreenViews = false

            SEGAnalytics.setup(with: configuration)

            if let receivedData = SvrfKeyChain.load(key: svrfAuthTokenKey),
                let authToken = String(data: receivedData, encoding: .utf8) {

                let body = SvrfJWTDecoder.decode(jwtToken: authToken)
                if let appId = body["appId"] as? String {
                    SEGAnalytics.shared().identify(appId)
                }

            }
        }

        /**
         Sets a node to have all of its children set as an occluder.
         - parameters:
         - node: A *SCNNode* likely named *Occluder*.
         */
        private static func setOccluderNode(node: SCNNode) {
            // Any child of this node should be occluded
            node.enumerateHierarchy { (childNode, _) in
                childNode.geometry?.firstMaterial?.colorBufferWriteMask = []
                childNode.renderingOrder = -1
            }
        }
}

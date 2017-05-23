import PusherPlatform

@objc public class ChatManager: NSObject {
    static public let namespace = "chat_api/v1"

    public let app: App
    public internal(set) var userSubscription: PCUserSubscription? = nil

    public var currentUser: PCCurrentUser? {
        get {
            return self.userSubscription?.currentUser
        }
    }

    let userStore: PCUserStore
    public var users: Set<PCUser> {
        get {
            return self.userStore.users
        }
    }

    // TODO: _remove_ userId should just be inferred from user token
    public var userId: Int? = nil

    public init(
        id: String,
        app: App? = nil,
        authorizer: PPAuthorizer? = nil,
        logger: PPLogger = PPDefaultLogger(),
        baseClient: PPBaseClient? = nil
    ) {
        self.app = app ?? App(id: id, authorizer: authorizer, client: baseClient, logger: logger)
        self.userStore = PCUserStore(app: self.app)
    }

    public func addConnectCompletionHandler(completionHandler: @escaping (PCCurrentUser?, Error?) -> Void) {
        guard let userSub = userSubscription else {
            self.app.logger.log("userSubscription is nil so unable to add a connectCompletionHandler", logLevel: .debug)
            return
        }

        userSub.connectCompletionHandlers.append(completionHandler)
    }

    public func connect(
        userId: Int,
        delegate: PCChatManagerDelegate,
        completionHandler: @escaping (PCCurrentUser?, Error?) -> Void
    ) {
        self.userId = userId
        let path = "/\(ChatManager.namespace)/users/\(userId)"

        let subscribeRequest = PPRequestOptions(method: HTTPMethod.SUBSCRIBE.rawValue, path: path)

        var resumableSub = PPResumableSubscription(
            app: self.app,
            requestOptions: subscribeRequest
        )

        self.userSubscription = PCUserSubscription(
            app: self.app,
            resumableSubscription: resumableSub,
            userStore: self.userStore,
            delegate: delegate,
            connectCompletionHandler: { user, error in
                guard let cUser = user else {
                    completionHandler(nil, error)
                    return
                }

                completionHandler(cUser, nil)
            }
        )

        // TODO: Fix this stuff

        self.app.subscribeWithResume(
            with: &resumableSub,
            using: subscribeRequest,
            //            onOpening: onOpening,
            //            onOpen: onOpen,
            //            onResuming: onResuming,
            onEvent: self.userSubscription!.handleEvent,
            onEnd: { statusCode, headers, info in
                print("ENDED")
            },
            onError: { error in
                completionHandler(nil, error)
            }
        )
    }

    //    fileprivate func onUserSubscriptionStateChange(newState: ) {
    //        self.delegate?.userSubscriptionStateChanged(from: <#T##PCUserSubscriptionState#>, to: <#T##PCUserSubscriptionState#>)
    //    }

}




extension ChatManager {
    // TODO: Should a user creation function be available in the Swift lib?

    public func createUser(name: String, completionHandler: @escaping (Int?, Error?) -> Void) {
        let randomString = NSUUID().uuidString

        let userObject: [String: Any] = ["name": name, "id": randomString]

        guard JSONSerialization.isValidJSONObject(userObject) else {
            completionHandler(nil, PCError.invalidJSONObjectAsData(userObject))
            return
        }

        guard let data = try? JSONSerialization.data(withJSONObject: userObject, options: []) else {
            completionHandler(nil, PCError.failedToJSONSerializeData(userObject))
            return
        }

        let path = "/\(ChatManager.namespace)/users"

        let generalRequest = PPRequestOptions(method: HTTPMethod.POST.rawValue, path: path, body: data)

        self.app.requestWithRetry(
            using: generalRequest,
            onSuccess: { data in
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    completionHandler(nil, PCError.failedToDeserializeJSON(data))
                    return
                }

                guard let json = jsonObject as? [String: Any] else {
                    completionHandler(nil, PCError.failedToCastJSONObjectToDictionary(jsonObject))
                    return
                }

                guard let id = json["id"] as? Int else {
                    completionHandler(nil, PCError.userIdNotFoundInResponseJSON(json))
                    return
                }

                completionHandler(id, nil)
            },
            onError: { error in
                completionHandler(nil, error)
            }
        )
    }
}
import UIKit

/**
 TODO:
 Counter
**/

enum ReviewKitError: ErrorType{
    case AppIdNotPresentError
    case UnknownError
}

/**
 * User feedback: For future releases
**/
class ReviewKitFeedback: NSObject, NSCoding{
    var message: String? = ""
    var question: String? = ""
    var version: String? = ""
    var dateFeedback: String? = ""
    var additionalInfo: [String: String]? = [:]

    init(message: String?, question: String?, version: String?){
        self.dateFeedback = "\(NSDate().timeIntervalSince1970)"
        self.message = message
        self.question = question
        self.version = version

        if let infoDictionary = NSBundle.mainBundle().infoDictionary{
            // App info
            self.additionalInfo?.updateValue("\(infoDictionary["CFBundleShortVersionString"])", forKey: "CFBundleShortVersionString")
            self.additionalInfo?.updateValue("\(infoDictionary["CFBundleVersion"])", forKey: "CFBundleVersion")
            self.additionalInfo?.updateValue("\(infoDictionary["DTPlatformVersion"])", forKey: "DTPlatformVersion")
            self.additionalInfo?.updateValue("\(infoDictionary["DTPlatformName"])", forKey: "DTPlatformName")

        }


    }

    @objc required init?(coder aDecoder: NSCoder) {
        message = aDecoder.decodeObjectForKey("message") as? String
        question = aDecoder.decodeObjectForKey("question") as? String
        version = aDecoder.decodeObjectForKey("version") as? String
        dateFeedback = aDecoder.decodeObjectForKey("dateFeedback") as? String
        additionalInfo = aDecoder.decodeObjectForKey("additionalInfo") as? [String: String]
    }

    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(message, forKey: "message")
        aCoder.encodeObject(question, forKey: "question")
        aCoder.encodeObject(version, forKey: "version")
        aCoder.encodeObject(dateFeedback, forKey: "dateFeedback")
        aCoder.encodeObject(additionalInfo, forKey: "additionalInfo")
    }
}


/**
 * Feedback satisfaction
 **/
enum ReviewKitFeedbackSatisfaction:String{
    case Satisfied = "Satisfied"
    case NotSatisfied = "Not Satisfied"
    case NotAvailable = "Not Available"
}

/**
 * Feedback status
 **/
enum ReviewKitFeedbackStatus: String{
    case Start = "Start"
    case Rate = "Rate"
    case Support = "Support"
}

/**
 * Support type
**/
enum ReviewKitSupportType{
    case Email
    case Question
}

/**
 * Delegate
 **/
protocol ReviewKitDelegate{
    func userDidTapSupport(askSupport:Bool, supportType: ReviewKitSupportType, review:ReviewKitPreference);
    func userDidTapRate(rated:Bool, review:ReviewKitPreference);
    func userDidRespond();
}

/**
 * Review preference
**/
class ReviewKitPreference:NSObject, NSCoding{
    var satisfaction: ReviewKitFeedbackSatisfaction? = ReviewKitFeedbackSatisfaction.NotAvailable
    var status: ReviewKitFeedbackStatus? = ReviewKitFeedbackStatus.Start
    var dateReview: String? = ""
    var version: String? = ""
    var hasEnjoyedApp: Bool = false
    var hasRatedApp: Bool = false
    var hasSentFeedback: Bool = false
    var feedback: ReviewKitFeedback? = nil

    override init() {
        super.init()
    }

    @objc required init?(coder aDecoder: NSCoder) {
        if let satisfactionFromPreferences = aDecoder.decodeObjectForKey("satisfaction") as? String{
            satisfaction = ReviewKitFeedbackSatisfaction.init(rawValue: satisfactionFromPreferences)
        }

        if let statusFromPreferences = aDecoder.decodeObjectForKey("status") as? String{
            status = ReviewKitFeedbackStatus.init(rawValue: statusFromPreferences)
        }
        dateReview = aDecoder.decodeObjectForKey("dateReview") as? String
        version = aDecoder.decodeObjectForKey("version") as? String
        hasEnjoyedApp = aDecoder.decodeBoolForKey("hasEnjoyed")
        hasRatedApp = aDecoder.decodeBoolForKey("hasRatedApp")
        hasSentFeedback = aDecoder.decodeBoolForKey("hasSentFeedback")
        feedback = aDecoder.decodeObjectForKey("feedback") as? ReviewKitFeedback
    }

    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.satisfaction?.rawValue, forKey: "satisfaction")
        aCoder.encodeObject(self.status?.rawValue, forKey: "status")
        aCoder.encodeObject(dateReview, forKey: "dateReview")
        aCoder.encodeObject(version, forKey: "version")
        aCoder.encodeBool(hasEnjoyedApp, forKey: "hasEnjoyed")
        aCoder.encodeBool(hasRatedApp, forKey: "hasRatedApp")
        aCoder.encodeBool(hasSentFeedback, forKey: "hasSentFeedback")
        aCoder.encodeObject(feedback, forKey: "feedback")
    }
}

/**
 * ReviewKit: It allows to
**/
class ReviewKit: UIView {
    // Top Layout Guide
    private var topLayoutGuide:UILayoutSupport?
    // TODO: Remove?
    private var topView: UIView?
    // TODO: Remove?
    private var bottomView: UIView?
    // The superview for ReviewKit
    private var containerView:UIView?
    // Title lable
    private var titleLabel: UILabel! = UILabel(frame: CGRectZero)
    // It controls the accept button
    private var acceptButton: UIButton! = UIButton(frame: CGRectZero)
    // It controls the reject button
    private var rejectButton: UIButton! = UIButton(frame: CGRectZero)

    // Support questions
    private let USER_QUESTIONS: [String: String] = [
        "Start": "Are you enjoying Sol.no?",
        "Rate": "Would you rate us on the Apple Store, then?",
        "Email":"Do you mind telling us what we do wrong?",
        "Question":"Another question here?!?"
    ]

    private let OK_BUTTON_TEXT: [String: String]  = [
        "Start": "Yes, Indeed",
        "Rate": "Yes, sure",
        "Email": "Yes, sure",
        "Question": "This"
    ]

    private let REJECT_BUTTON_TEXT: [String: String]  = [
        "Start": "Not really",
        "Rate": "No, thanks",
        "Email": "No, thanks",
        "Question": "That"
    ]

    // ITunes URL
    private let ITUNES_URL:String = "itms-apps://itunes.apple.com/app/"
    private var itunesNSUrl:NSURL?

    private var transition: CATransition?
    // ReviewKit Delegate
    var delegate:ReviewKitDelegate?

    // The satisfaction status
    private var satisfactionStatus: ReviewKitFeedbackSatisfaction = ReviewKitFeedbackSatisfaction.NotSatisfied
    // The feedback status
    private var feedbackStatus: ReviewKitFeedbackStatus = ReviewKitFeedbackStatus.Start
    // This is the review version. It will not ask twice to review the same version.
    private var reviewVersion: String?
    // This is the app version from the Bundle. Only for information about the app
    private var appVersion:String?
    // App id in the Apple Store
    private var appId: String?

    // Review preference array. User can review more than once based on the version
    private var reviewPreferences:[ReviewKitPreference] = []
    // Current version being reviewed
    private var currentReview:ReviewKitPreference = ReviewKitPreference()

    // Support type
    private var supportType:ReviewKitSupportType =  ReviewKitSupportType.Email


    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    init(appId:String, version:String, supportType:ReviewKitSupportType? = ReviewKitSupportType.Email) throws{
        guard appId.characters.count > 0 else{
            throw ReviewKitError.AppIdNotPresentError
        }

        if let support = supportType{
            self.supportType = support
        }

        super.init(frame:CGRectZero)
        self.reviewVersion = version
        self.appId = appId
        self.itunesNSUrl = NSURL(string: "\(self.ITUNES_URL)\(self.appId!)")
        self.readPreferences()
    }

    convenience init(appId:String, version:String, topLayoutGuide: UILayoutSupport) throws{
        try self.init(appId:appId, version:version)

        self.topLayoutGuide = topLayoutGuide
    }

    convenience init(appId:String, version:String, topLayoutGuide: UILayoutSupport, topView:UIView, bottomView:UIView?) throws {
        try self.init(appId:appId, version:version)
        self.topView = topView
        self.bottomView = bottomView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(){
        self.createReviewBox()
        self.createTransition()
    }

    /**
    ** Save the preferences in NSUserDefaults
    ** It saves the information in the "reviews" key
    **/
    private func savePreferences(){
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(self.reviewPreferences)
        NSUserDefaults.standardUserDefaults().setObject(encodedData, forKey: "reviews")
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    /**
    ** Read the preferences from NSUserDefaults
    **
    **/
    private func readPreferences(){

        if let nspreferences = NSUserDefaults.standardUserDefaults().objectForKey("reviews") as? NSData, let pref = NSKeyedUnarchiver.unarchiveObjectWithData(nspreferences),  let reviews = pref as? [ReviewKitPreference]{
            self.reviewPreferences = reviews
        }
    }

    /**
    ** Add a review to the review preferences.
    ** It will add the current review only if the current version has not being reviewed yet.
    **/
    private func addReview(){
        for (_, val) in self.reviewPreferences.enumerate(){
            let pref = val as ReviewKitPreference
            if (pref.version == reviewVersion) // Version already reviewed
            {
                return;
            }
        }
        reviewPreferences.append(self.currentReview)
        self.savePreferences()
    }

    /**
    ** Reset the review
    **/
    private func resetReview(){
        currentReview = ReviewKitPreference()
        currentReview.status = ReviewKitFeedbackStatus.Start
        currentReview.satisfaction = ReviewKitFeedbackSatisfaction.NotAvailable
        currentReview.hasEnjoyedApp = false
        currentReview.hasRatedApp = false
        currentReview.hasSentFeedback = false
        currentReview.dateReview = "\(NSDate().timeIntervalSince1970)"
        currentReview.feedback = nil
        currentReview.version = reviewVersion
    }

    /**
    ** Create the transition
    **/
    private func createTransition(){
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = 1.0
        self.transition = animation
    }

    @IBAction func rejectButtonAction(sender:UIButton){
        if(self.feedbackStatus == .Start){
            // Reset feedback
            self.resetReview()

            self.titleLabel?.layer.addAnimation(self.transition!, forKey: kCATransitionFade)
            self.titleLabel?.text = self.supportType == ReviewKitSupportType.Email ? self.USER_QUESTIONS["Email"] : self.USER_QUESTIONS["Question"]
            self.titleLabel?.layer.removeAnimationForKey(kCATransitionFade)



            self.satisfactionStatus = ReviewKitFeedbackSatisfaction.NotSatisfied
            self.feedbackStatus = ReviewKitFeedbackStatus.Support

            self.currentReview.hasEnjoyedApp = false

            self.changeButton()

        }else if(self.feedbackStatus == .Rate){
            currentReview.hasRatedApp = false
            currentReview.feedback = ReviewKitFeedback(message: "User did not want to give feedback", question: self.titleLabel?.text,  version: self.reviewVersion)
            self.addReview()

            self.delegate?.userDidTapRate(false, review: self.currentReview)
        }
        else if (self.feedbackStatus == .Support){
            currentReview.hasSentFeedback = false
            currentReview.feedback = ReviewKitFeedback(message: "User did not want to rate the app", question: self.titleLabel?.text,  version: self.reviewVersion)
            self.addReview()

            self.delegate?.userDidTapSupport(false, supportType: self.supportType, review: self.currentReview)
        }
    }

    @IBAction func okButtonAction(sender:UIButton){
        if(self.feedbackStatus == .Start){
            self.resetReview()

            self.layer.addAnimation(self.transition!, forKey: kCATransitionFade)
            self.titleLabel?.text = self.USER_QUESTIONS["Rate"]
            self.changeButton()
            self.layer.removeAnimationForKey(kCATransitionFade)



            self.satisfactionStatus = ReviewKitFeedbackSatisfaction.Satisfied
            self.feedbackStatus = ReviewKitFeedbackStatus.Rate

            self.currentReview.hasEnjoyedApp = true

            self.changeButton()

        }else if(self.feedbackStatus == .Support){
            currentReview.hasSentFeedback = true
            currentReview.feedback = ReviewKitFeedback(message: "User wanted to give feedback", question: self.titleLabel?.text,  version: self.reviewVersion)
            self.addReview()

            self.delegate?.userDidTapSupport(true, supportType: self.supportType, review:self.currentReview)
        }
        else if (self.feedbackStatus == .Rate){
            currentReview.hasRatedApp = true
            currentReview.feedback = ReviewKitFeedback(message: "User wanted to rate the app", question: self.titleLabel?.text,  version: self.reviewVersion)
            self.addReview()

            self.delegate?.userDidTapRate(true, review:self.currentReview)
            // Open the AppStore page
            UIApplication.sharedApplication().openURL(self.itunesNSUrl!)
        }

    }

    func changeButton(){
        var okButtonText: String
        var rejectButtonText:String
        switch(self.feedbackStatus){
            case ReviewKitFeedbackStatus.Rate:
                okButtonText = self.OK_BUTTON_TEXT["Rate"]!
                rejectButtonText = self.REJECT_BUTTON_TEXT["Rate"]!
            case ReviewKitFeedbackStatus.Support:
                okButtonText = (self.supportType == ReviewKitSupportType.Email ? self.OK_BUTTON_TEXT["Email"] : self.OK_BUTTON_TEXT["Question"])!
                rejectButtonText = (self.supportType == ReviewKitSupportType.Email ? self.REJECT_BUTTON_TEXT["Email"] : self.REJECT_BUTTON_TEXT["Question"])!
            default:
                okButtonText = self.OK_BUTTON_TEXT["Rate"]!
                rejectButtonText = self.REJECT_BUTTON_TEXT["Rate"]!
        }
        self.acceptButton.setTitle(okButtonText, forState: UIControlState.Normal)
        self.rejectButton.setTitle(rejectButtonText, forState: UIControlState.Normal)
    }


    func createReviewBox() -> UIView{
        let backgroundColor = UIColor(colorLiteralRed: 215.0/255.0, green: 0.0/255.0, blue: 12.0/255.0, alpha: 0.95)
        let view: UIView = UIView(frame: CGRectZero)
        let font = UIFont.systemFontOfSize(15)
        self.backgroundColor = backgroundColor

        self.titleLabel.font = font
        self.titleLabel.text = self.USER_QUESTIONS["Start"]!
        self.titleLabel.textColor = UIColor.whiteColor()
        self.titleLabel.textAlignment = NSTextAlignment.Center


        self.rejectButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
        self.rejectButton.setTitle(self.REJECT_BUTTON_TEXT["Start"], forState: UIControlState.Normal)
        self.rejectButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.rejectButton.layer.borderWidth = 1.0
        self.rejectButton.layer.cornerRadius = 5.0
        self.rejectButton.enabled = true
        self.rejectButton.userInteractionEnabled = true
        self.rejectButton.addTarget(self, action: #selector(ReviewKit.rejectButtonAction), forControlEvents: UIControlEvents.TouchUpInside)

        self.acceptButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
        self.acceptButton.setTitle(self.OK_BUTTON_TEXT["Start"], forState: UIControlState.Normal)
        self.acceptButton.backgroundColor = UIColor.whiteColor()
        self.acceptButton.tintColor = backgroundColor
        self.acceptButton.setTitleColor(backgroundColor, forState: UIControlState.Normal)
        self.acceptButton.layer.borderColor = backgroundColor.CGColor
        self.acceptButton.layer.borderWidth = 1.0
        self.acceptButton.layer.cornerRadius = 5.0
        self.acceptButton.addTarget(self, action: #selector(ReviewKit.okButtonAction), forControlEvents: UIControlEvents.TouchUpInside)

        self.addSubview(self.titleLabel)
        self.addSubview(rejectButton)
        self.addSubview(acceptButton)
        //self.superview!.addSubview(self)

        let views: [String: AnyObject!] = [
            "myView":self,
            "superview": self.superview,
            "label": self.titleLabel,
            "rejectButton":self.rejectButton,
            "okButton":self.acceptButton
        ]

        let metrics: [String: CGFloat] = ["viewWidth":self.superview!.frame.size.width, "viewHeight": 100, "topComponentHeight":50]


        var constraints:[NSLayoutConstraint] = NSLayoutConstraint.constraintsWithVisualFormat("|-(0)-[myView(viewWidth)]-(0)-|", options: [NSLayoutFormatOptions.AlignAllCenterY, NSLayoutFormatOptions.AlignAllLeading, NSLayoutFormatOptions.AlignAllTrailing], metrics: metrics, views: views)
        if let topView = self.topView, let bottomView=self.bottomView{
            constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[topView]-(<=1)-[myView(viewHeight)]-(<=1)-[bottomView]", options: [], metrics: metrics, views: views)
        }else if let topView = self.topView{
            constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[topView]-(<=1)-[myView(viewHeight)]", options: [], metrics: metrics, views: views)
        }
        else if let topGuide = self.topLayoutGuide{
            constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[topGuide]-[myView(viewHeight)]", options: [], metrics: metrics, views: views)
        }else{
            constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[myView(viewHeight)]", options: [], metrics: metrics, views: views)
        }


        // Label
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options: [.AlignAllLeading,.AlignAllTrailing,.AlignAllCenterY], metrics: metrics, views: views)
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-(>=20)-[label]", options: [], metrics: metrics, views: views)

        // Buttons
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("|-(<=50)-[rejectButton(==50)]-(<=20)-[okButton(==rejectButton)]-(<=50)-|", options: [.AlignAllCenterY], metrics: metrics, views: views)
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-(15)-[rejectButton]-(>=5)-|", options: [], metrics: metrics, views: views)
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-(15)-[okButton]-(>=5)-|", options: [], metrics: metrics, views: views)

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        self.bottomView?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activateConstraints(constraints)

        return view
    }

    /**
    ** Check if a particular version has been rated
    **/
    static func hasRated(version: String?) -> Bool{
        if let nspreferences = NSUserDefaults.standardUserDefaults().objectForKey("reviews") as? NSData,
            let pref = NSKeyedUnarchiver.unarchiveObjectWithData(nspreferences),
            let reviews = pref as? [ReviewKitPreference]{
            if (reviews.count <= 0){
                return false // Not been rated yet
            }

            if let v = version {
                // Check if they have reviewed a particular version
                let reviewedVersion = reviews.filter({ (review:ReviewKitPreference) -> Bool in
                    return review.version == v
                })
                return reviewedVersion.count > 0 ? true: false
            }else{
                // Check if they have ever reviewed the app
                return reviews.count >= 0
            }

        }
        return false // App has not been reviewed yet

    }
}

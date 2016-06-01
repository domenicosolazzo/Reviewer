import UIKit
import MessageUI

/**
 TODO:
 Counter
 Second question
**/
/**
 * User feedback: For future releases
**/
class Feedback: NSObject, NSCoding{
    var message: String?
    var version: String?
    var dateFeedback: String?
    
    
    @objc required init?(coder aDecoder: NSCoder) {
        message = aDecoder.decodeObjectForKey("message") as? String
        version = aDecoder.decodeObjectForKey("version") as? String
        dateFeedback = aDecoder.decodeObjectForKey("dateFeedback") as? String
    }
    
    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(message, forKey: "message")
        aCoder.encodeObject(version, forKey: "version")
        aCoder.encodeObject(dateFeedback, forKey: "dateFeedback")
    }
}


/**
 * Feedback satisfaction
 **/
enum FeedbackSatisfaction:String{
    case Satisfied = "Satisfied"
    case NotSatisfied = "Not Satisfied"
    case NotAvailable = "Not Available"
}

/**
 * Feedback status
 **/
enum FeedbackStatus: String{
    case Start = "Start"
    case Rate = "Rate"
    case Support = "Support"
}

/**
 * Delegate
 **/
protocol ReviewKitDelegate{
    func userDidTapSupport(askSupport:Bool);
    func userDidTapRate(rated:Bool);
    func userDidRespond();
}

/**
 * Review preference
**/
class ReviewPreference:NSObject, NSCoding{
    var satisfaction: FeedbackSatisfaction?
    var status: FeedbackStatus?
    var dateReview: String?
    var version: String?
    var hasEnjoyedApp: Bool = false
    var hasRatedApp: Bool = false
    var hasSentFeedback: Bool = false
    var feedback: Feedback?
    
    override init() {
        super.init()
    }
    
    @objc required init?(coder aDecoder: NSCoder) {
        if let satisfactionFromPreferences = aDecoder.decodeObjectForKey("satisfaction") as? String{
            satisfaction = FeedbackSatisfaction.init(rawValue: satisfactionFromPreferences)
        }
        
        if let statusFromPreferences = aDecoder.decodeObjectForKey("status") as? String{
            status = FeedbackStatus.init(rawValue: statusFromPreferences)
        }
        dateReview = aDecoder.decodeObjectForKey("dateReview") as? String
        version = aDecoder.decodeObjectForKey("version") as? String
        hasEnjoyedApp = aDecoder.decodeBoolForKey("hasEnjoyed")
        hasRatedApp = aDecoder.decodeBoolForKey("hasRatedApp")
        hasSentFeedback = aDecoder.decodeBoolForKey("hasSentFeedback")
        feedback = aDecoder.decodeObjectForKey("feedback") as? Feedback
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
    
    // Start Question
    private let START_QUESTION:String = "Are you enjoying Sol.no?"
    // Accept question
    private let ACCEPT_QUESTION:String = "Would you rate us on the Apple Store, then?"
    // Rejection question
    private let REJECT_QUESTION: String = "Do you mind telling us what we do wrong?"
    // Reject Button
    private let REJECT_SATISFACTION_BUTTONTEXT: String = "Not really"
    // OK Button
    private let OK_SATISFACTION_BUTTONTEXT:String = "Yes, Indeed"
    // Reject Question Button
    private let REJECT_QUESTION_BUTTONTEXT: String = "No, thanks"
    // OK Question Button
    private let OK_QUESTION_BUTTONTEXT: String = "Yes, sure"
    
    // ITunes URL
    private let ITUNES_URL:String = "itms-apps://itunes.apple.com/app/"
    private var itunesNSUrl:NSURL?
    
    private var transition: CATransition?
    // ReviewKit Delegate
    var delegate:ReviewKitDelegate?
    
    // The satisfaction status
    private var satisfactionStatus: FeedbackSatisfaction = FeedbackSatisfaction.NotSatisfied
    // The feedback status
    private var feedbackStatus: FeedbackStatus = FeedbackStatus.Start
    // This is the review version. It will not ask twice to review the same version.
    private var reviewVersion: String?
    // This is the app version from the Bundle. Only for information about the app
    private var appVersion:String?
    // App id in the Apple Store
    private var appId: String?
    
    // Review preference array. User can review more than once based on the version
    private var reviewPreferences:[ReviewPreference] = []
    // Current version being reviewed
    private var currentReview:ReviewPreference = ReviewPreference()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    init(appId:String, version:String){
        super.init(frame:CGRectZero)
        self.reviewVersion = version
        self.appId = appId
        self.itunesNSUrl = NSURL(string: "\(self.ITUNES_URL)\(self.appId)")
        self.readPreferences()
    }
    
    convenience init(appId:String, version:String, topLayoutGuide: UILayoutSupport){
        self.init(appId:appId, version:version)
        
        self.topLayoutGuide = topLayoutGuide
    }
    
    convenience init(appId:String, version:String, topLayoutGuide: UILayoutSupport, topView:UIView, bottomView:UIView?){
        self.init(appId:appId, version:version)
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
        
        if let nspreferences = NSUserDefaults.standardUserDefaults().objectForKey("reviews") as? NSData, let pref = NSKeyedUnarchiver.unarchiveObjectWithData(nspreferences),  let reviews = pref as? [ReviewPreference]{
            self.reviewPreferences = reviews
        }
    }
    
    /**
    ** Add a review to the review preferences.
    ** It will add the current review only if the current version has not being reviewed yet.
    **/
    private func addReview(){
        for (_, val) in self.reviewPreferences.enumerate(){
            let pref = val as ReviewPreference
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
        currentReview = ReviewPreference()
        currentReview.status = FeedbackStatus.Start
        currentReview.satisfaction = FeedbackSatisfaction.NotAvailable
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
            self.titleLabel?.text = self.REJECT_QUESTION
            self.titleLabel?.layer.removeAnimationForKey(kCATransitionFade)
            
            self.changeButton()
            
            self.satisfactionStatus = FeedbackSatisfaction.NotSatisfied
            self.feedbackStatus = FeedbackStatus.Support
            
            self.currentReview.hasEnjoyedApp = false
            
        }else if(self.feedbackStatus == .Rate){
            currentReview.hasRatedApp = false
            self.addReview()
            
            self.delegate?.userDidTapRate(false)
        }
        else if (self.feedbackStatus == .Support){
            currentReview.hasSentFeedback = false
            self.addReview()
            
            self.delegate?.userDidTapSupport(false)
        }
    }
    
    @IBAction func okButtonAction(sender:UIButton){
        if(self.feedbackStatus == .Start){
            self.resetReview()
            
            self.layer.addAnimation(self.transition!, forKey: kCATransitionFade)
            self.titleLabel?.text = self.ACCEPT_QUESTION
            self.changeButton()
            self.layer.removeAnimationForKey(kCATransitionFade)
            
            self.changeButton()
            
            self.satisfactionStatus = FeedbackSatisfaction.Satisfied
            self.feedbackStatus = FeedbackStatus.Rate
            
            self.currentReview.hasEnjoyedApp = true
            
        }else if(self.feedbackStatus == .Support){
            currentReview.hasSentFeedback = true
            self.addReview()
            
            self.delegate?.userDidTapSupport(true)
        }
        else if (self.feedbackStatus == .Rate){
            currentReview.hasRatedApp = true
            self.addReview()
            
            self.delegate?.userDidTapRate(true)
            // Open the AppStore page
            UIApplication.sharedApplication().openURL(self.itunesNSUrl!)
        }
        
    }
    
    func changeButton(){
        self.acceptButton.setTitle(self.OK_QUESTION_BUTTONTEXT, forState: UIControlState.Normal)
        self.rejectButton.setTitle(self.REJECT_QUESTION_BUTTONTEXT, forState: UIControlState.Normal)
    }

    
    func createReviewBox() -> UIView{
        let backgroundColor = UIColor(colorLiteralRed: 215.0/255.0, green: 0.0/255.0, blue: 12.0/255.0, alpha: 0.95)
        let view: UIView = UIView(frame: CGRectZero)
        let font = UIFont.systemFontOfSize(15)
        self.backgroundColor = backgroundColor
        
        self.titleLabel.font = font
        self.titleLabel.text = self.START_QUESTION
        self.titleLabel.textColor = UIColor.whiteColor()
        self.titleLabel.textAlignment = NSTextAlignment.Center
        
        
        self.rejectButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
        self.rejectButton.setTitle(self.REJECT_SATISFACTION_BUTTONTEXT, forState: UIControlState.Normal)
        self.rejectButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.rejectButton.layer.borderWidth = 1.0
        self.rejectButton.layer.cornerRadius = 5.0
        self.rejectButton.enabled = true
        self.rejectButton.userInteractionEnabled = true
        self.rejectButton.addTarget(self, action: #selector(ReviewKit.rejectButtonAction), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.acceptButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
        self.acceptButton.setTitle(self.OK_SATISFACTION_BUTTONTEXT, forState: UIControlState.Normal)
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
        
        
        // Test
        //constraints += [NSLayoutConstraint(item: self.bottomView!, attribute: NSLayoutAttribute.TopMargin, relatedBy: NSLayoutRelation.Equal , toItem: self, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1, constant: 750.0)]
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        //self.topView?.translatesAutoresizingMaskIntoConstraints = false
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
            let reviews = pref as? [ReviewPreference]{
            if (reviews.count <= 0){
                return false // Not been rated yet
            }
            
            if let v = version {
                // Check if they have reviewed a particular version
                let reviewedVersion = reviews.filter({ (review:ReviewPreference) -> Bool in
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

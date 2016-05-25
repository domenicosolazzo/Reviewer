import UIKit


private enum ReviewerSatisfaction{

    case Satisfied

    case NotSatisfied

}


private enum ReviewerStatus{

    case Start

    case Rate

    case Support

}


protocol ReviewerDelegate{

    func userDidTapSupport(askSupport:Bool);

    func userDidTapRate(rated:Bool);

    func userDidRespond();

}


class Reviewer: UIView {

    private var topView: UIView?

    private var bottomView: UIView?

    private var titleLabel: UILabel! = UILabel(frame: CGRectZero)

    private var acceptButton: UIButton! = UIButton(frame: CGRectZero)

    private var rejectButton: UIButton! = UIButton(frame: CGRectZero)

    private var transition: CATransition?

    var delegate:ReviewerDelegate?



    private var satisfactionStatus: ReviewerSatisfaction = ReviewerSatisfaction.NotSatisfied

    private var feedbackStatus: ReviewerStatus = ReviewerStatus.Start

    private var topLayoutGuide:UILayoutSupport?


    override init(frame: CGRect) {

        super.init(frame: frame)

    }



    init(appId:String, topLayoutGuide: UILayoutSupport){

        super.init(frame: CGRectZero)



        self.topLayoutGuide = topLayoutGuide



    }



    convenience init(appId:String, topLayoutGuide: UILayoutSupport, topView:UIView, bottomView:UIView?){

        self.init(appId:appId, topLayoutGuide: topLayoutGuide)

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



    private func createTransition(){

        let animation = CATransition()

        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        animation.type = kCATransitionFade

        animation.duration = 1.0

        self.transition = animation

    }



    @IBAction func rejectButtonAction(sender:UIButton){

        print("Refusing.....")



        if(self.feedbackStatus == .Start){

            self.titleLabel?.layer.addAnimation(self.transition!, forKey: kCATransitionFade)

            self.titleLabel?.text = "Do you mind telling us what we do wrong?"

            self.titleLabel?.layer.removeAnimationForKey(kCATransitionFade)



            self.changeButton()



            self.satisfactionStatus = FeedbackSatisfaction.NotSatisfied

            self.feedbackStatus = FeedbackStatus.Support



        }else if(self.feedbackStatus == .Rate){

            self.delegate?.userDidTapRate(false)

        }

        else if (self.feedbackStatus == .Support){

            // Do something

            self.delegate?.userDidTapSupport(false)

        }



    }



    @IBAction func okButtonAction(sender:UIButton){

        print("Accepting...")





        if(self.feedbackStatus == .Start){

            self.layer.addAnimation(self.transition!, forKey: kCATransitionFade)

            self.titleLabel?.text = "Would you rate us on the Apple Store, then?"

            self.changeButton()

            self.layer.removeAnimationForKey(kCATransitionFade)



            self.changeButton()



            self.satisfactionStatus = FeedbackSatisfaction.Satisfied

            self.feedbackStatus = FeedbackStatus.Rate



        }else if(self.feedbackStatus == .Support){

            self.delegate?.userDidTapSupport(true)

        }

        else if (self.feedbackStatus == .Rate){

            // Do something

            print("Opening app store")

            self.delegate?.userDidTapRate(true)

            UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/app/id567951633")!)

        }



    }



    func changeButton(){

        self.acceptButton.setTitle("Ok, sure!", forState: UIControlState.Normal)

        self.rejectButton.setTitle("No, thanks!", forState: UIControlState.Normal)

    }





    func createReviewBox() -> UIView{

        let backgroundColor = UIColor(colorLiteralRed: 215.0/255.0, green: 0.0/255.0, blue: 12.0/255.0, alpha: 0.95)

        let view: UIView = UIView(frame: CGRectZero)

        let font = UIFont.systemFontOfSize(15)

        self.backgroundColor = backgroundColor



        self.titleLabel.font = font

        self.titleLabel.text = "Are you enjoying Sol.no?"

        self.titleLabel.textColor = UIColor.whiteColor()

        self.titleLabel.textAlignment = NSTextAlignment.Center





        self.rejectButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)

        self.rejectButton.setTitle("Not really", forState: UIControlState.Normal)

        self.rejectButton.layer.borderColor = UIColor.whiteColor().CGColor

        self.rejectButton.layer.borderWidth = 1.0

        self.rejectButton.layer.cornerRadius = 5.0

        self.rejectButton.enabled = true

        self.rejectButton.userInteractionEnabled = true

        self.rejectButton.addTarget(self, action: #selector(ReviewKit.rejectButtonAction), forControlEvents: UIControlEvents.TouchUpInside)



        self.acceptButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)

        self.acceptButton.setTitle("Yes, indeed", forState: UIControlState.Normal)

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

            "topGuide":self.topLayoutGuide,

            "label": self.titleLabel,

            "rejectButton":self.rejectButton,

            "okButton":self.acceptButton,

            "topView": self.topView,

            "bottomView":self.bottomView

        ]



        let metrics: [String: CGFloat] = ["viewWidth":self.superview!.frame.size.width, "viewHeight": 160, "topComponentHeight":50]





        var constraints:[NSLayoutConstraint] = NSLayoutConstraint.constraintsWithVisualFormat("|-(0)-[myView(viewWidth)]-(0)-|", options: [NSLayoutFormatOptions.AlignAllCenterY, NSLayoutFormatOptions.AlignAllLeading, NSLayoutFormatOptions.AlignAllTrailing], metrics: metrics, views: views)

        if let topView = self.topView, let bottomView=self.bottomView{

            constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[topView]-(<=1)-[myView(viewHeight)]-(<=1)-[bottomView]", options: [], metrics: metrics, views: views)

        }else if let topView = self.topView{

            constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[topView]-(<=1)-[myView(viewHeight)]", options: [], metrics: metrics, views: views)

        }

        else{

            constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[topGuide]-[myView(viewHeight)]", options: [], metrics: metrics, views: views)

        }





        // Label

        constraints += NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options: [.AlignAllLeading,.AlignAllTrailing,.AlignAllCenterY], metrics: metrics, views: views)

        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-(>=50)-[label]", options: [], metrics: metrics, views: views)



        // Buttons

        constraints += NSLayoutConstraint.constraintsWithVisualFormat("|-(<=50)-[rejectButton(==50)]-(<=50)-[okButton(==rejectButton)]-(<=50)-|", options: [.AlignAllCenterY], metrics: metrics, views: views)

        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-(20)-[rejectButton]-(>=20)-|", options: [], metrics: metrics, views: views)

        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[label]-(20)-[okButton]-(>=20)-|", options: [], metrics: metrics, views: views)





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


}

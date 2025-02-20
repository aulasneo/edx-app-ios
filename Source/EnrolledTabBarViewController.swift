//
//  EnrolledTabBarViewController.swift
//  edX
//
//  Created by Salman on 19/12/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

private enum TabBarOptions: Int {
    case Course, Profile, CourseCatalog, Debug
    static let options = [CourseCatalog, Course, Profile, Debug]
    
    func title(config: OEXConfig? = nil) -> String {
        switch self {
        case .Course:
            return Strings.learn
        case .Profile:
            return Strings.UserAccount.profile
        case .CourseCatalog:
            return config?.discovery.type == .native ? Strings.findCourses : Strings.discover
        case .Debug:
            return Strings.debug
        }
    }
}

class EnrolledTabBarViewController: UITabBarController, InterfaceOrientationOverriding, ChromeCastConnectedButtonDelegate {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider & ServerConfigProvider
    
    private let environment: Environment
    private var tabBarItems: [TabBarItem] = []
    
    // add the additional resources options like 'debug'(special developer option) in additionalTabBarItems
    private var additionalTabBarItems : [TabBarItem] = []
    
    private let tabBarImageFontSize : CGFloat = 22
    static var courseCatalogIndex: Int = 0
    
    private var screenTitle: String {
        guard let option = TabBarOptions.options.first else { return Strings.courses }
        return option.title(config: environment.config)
    }
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = screenTitle
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        prepareTabViewData()
        delegate = self
        
        view.accessibilityIdentifier = "EnrolledTabBarViewController:view"
        selectedIndex = 1
        title = ""
        
        addTabbarIndicator()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func prepareTabViewData() {
        tabBarItems = []
        var item : TabBarItem
        for option in TabBarOptions.options {
            switch option {
            case .Course:
                item = TabBarItem(title: option.title(), viewController: ForwardingNavigationController(rootViewController: LearnContainerViewController(environment: environment)), icon: Icon.CoursewareEnrolled, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
            case .Profile:
                item = TabBarItem(title: option.title(), viewController: ForwardingNavigationController(rootViewController: ProfileOptionsViewController.init(environment: environment)), icon: Icon.Person, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
            case .CourseCatalog:
                guard let router = environment.router,
                    let discoveryController = router.discoveryViewController() else { break }
                item = TabBarItem(title: option.title(config: environment.config), viewController: ForwardingNavigationController(rootViewController: discoveryController), icon: Icon.Discovery, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
                EnrolledTabBarViewController.courseCatalogIndex = 0
            case .Debug:
                if environment.config.shouldShowDebug() {
                    item = TabBarItem(title: option.title(), viewController: ForwardingNavigationController(rootViewController: DebugMenuViewController(environment: environment)), icon: Icon.Discovery, detailText: Strings.Dashboard.courseCourseDetail)
                    additionalTabBarItems.append(item)
                }
            }
        }
        
        if additionalTabBarItems.count > 0 {
            let item = TabBarItem(title:Strings.resourses, viewController:
                AdditionalTabBarViewController(environment: environment, cellItems: additionalTabBarItems), icon: Icon.MoreOptionsIcon, detailText: "")
            tabBarItems.append(item)
        }
    
        loadTabBarViewControllers(tabBarItems: tabBarItems)
    }
    
    private func loadTabBarViewControllers(tabBarItems: [TabBarItem]) {
        var controllers : [UIViewController] = []
        for tabBarItem in tabBarItems {
            let controller = tabBarItem.viewController
            controller.tabBarItem = UITabBarItem(title:tabBarItem.title, image:tabBarItem.icon.imageWithFontSize(size: tabBarImageFontSize), selectedImage: tabBarItem.icon.imageWithFontSize(size: tabBarImageFontSize))
            controller.tabBarItem.accessibilityIdentifier = "EnrolledTabBarViewController:tab-bar-item-\(tabBarItem.title)"
            controllers.append(controller)
        }
        viewControllers = controllers
        tabBar.isHidden = (tabBarItems.count == 1)
    }
    
    // MARK: Deep Linking
    @discardableResult
    func switchTab(with type: DeepLinkType) -> UIViewController {
        var controller: UIViewController?
        
        switch type {
        case .profile:
            selectedIndex = tabBarViewControllerIndex(with: ProfileOptionsViewController.self)
            controller = tabBarViewController(ProfileOptionsViewController.self)
            break
        case .program, .programDetail:
            selectedIndex = tabBarViewControllerIndex(with: LearnContainerViewController.self)
            controller = tabBarViewController(LearnContainerViewController.self)
            break
        case .courseDashboard, .courseDates, .courseVideos, .courseHandout, .courseComponent, .courseAnnouncement, .discussions, .discussionPost, .discussionTopic, .discussionComment:
            selectedIndex = tabBarViewControllerIndex(with: LearnContainerViewController.self)
            controller = tabBarViewController(LearnContainerViewController.self)
            break
        case .discovery, .discoveryCourseDetail, .discoveryProgramDetail:
            if environment.config.discovery.isEnabled {
                selectedIndex = environment.config.discovery.type == .webview ? tabBarViewControllerIndex(with: OEXFindCoursesViewController.self) : tabBarViewControllerIndex(with: CourseCatalogViewController.self)
                if let discovery = tabBarViewController(OEXFindCoursesViewController.self) {
                    controller = discovery
                } else if let discovery = tabBarViewController(CourseCatalogViewController.self) {
                    controller = discovery
                }
            }
            break
        default:
            selectedIndex = 0
            break
        }
        navigationItem.title = titleOfViewController(index: selectedIndex)
        
        return controller ?? tabBarItems[selectedIndex].viewController
    }
}

extension EnrolledTabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title
    }
}

extension UITabBarController {
    func addTabbarIndicator(color: UIColor = OEXStyles.shared().primaryDarkColor(), lineHeight: CGFloat = 2) {
        guard let count = tabBar.items?.count else { return }
        let tabBarItemSize = CGSize(width: tabBar.frame.width / CGFloat(count), height: tabBar.frame.height)
        let indicator = createTabbarIndicator(color: color, size: tabBarItemSize, lineHeight: lineHeight)
        tabBar.selectionIndicatorImage = indicator
    }
    
    private func createTabbarIndicator(color: UIColor, size: CGSize, lineHeight: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: size.height - lineHeight, width: size.width, height: lineHeight )
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

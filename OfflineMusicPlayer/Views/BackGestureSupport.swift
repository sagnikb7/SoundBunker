import SwiftUI

/// Preserve native interactive navigation; at a modal root the same edge dismisses it.
struct BackGestureSupport: UIViewControllerRepresentable {
    var rootBack: (() -> Void)? = nil
    func makeUIViewController(context: Context) -> Controller { Controller(rootBack: rootBack) }
    func updateUIViewController(_ controller: Controller, context: Context) { controller.rootBack = rootBack }
    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        var rootBack: (() -> Void)?
        private weak var navigation: UINavigationController?
        private weak var nativePop: UIGestureRecognizer?
        private weak var attachedView: UIView?
        private var edge: UIScreenEdgePanGestureRecognizer?
        init(rootBack: (() -> Void)?) { self.rootBack = rootBack; super.init(nibName: nil, bundle: nil) }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func loadView() { view = UIView(); view.backgroundColor = .clear; view.isUserInteractionEnabled = false }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            var ancestor: UIViewController? = parent
            while let controller = ancestor {
                if let nav = controller as? UINavigationController ?? controller.navigationController { navigation = nav; break }
                ancestor = controller.parent
            }
            if let pop = navigation?.interactivePopGestureRecognizer {
                // SwiftUI can leave its recognizer disabled or with a stale delegate on pushed
                // List screens. One edge recognizer handles stack pops and modal roots uniformly.
                nativePop = pop
                pop.isEnabled = false
            }
            guard edge == nil, let target = navigation?.view ?? parent?.view else { return }
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(back(_:)))
            gesture.edges = .left
            gesture.maximumNumberOfTouches = 1
            gesture.cancelsTouchesInView = false
            gesture.delegate = self
            target.addGestureRecognizer(gesture); edge = gesture; attachedView = target
        }
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            let canPop = (navigation?.viewControllers.count ?? 0) > 1
            return navigation?.transitionCoordinator == nil && (canPop || rootBack != nil)
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
        @objc private func back(_ gesture: UIScreenEdgePanGestureRecognizer) {
            guard gesture.state == .ended, gesture.translation(in: attachedView).x > 50 else { return }
            if let navigation = navigation, navigation.viewControllers.count > 1 {
                navigation.popViewController(animated: true)
            } else {
                rootBack?()
            }
        }
        deinit {
            if let edge = edge { attachedView?.removeGestureRecognizer(edge) }
            nativePop?.isEnabled = true
        }
    }
}

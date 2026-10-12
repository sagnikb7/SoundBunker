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
                nativePop = pop; pop.isEnabled = true; pop.delegate = self
            }
            guard rootBack != nil, edge == nil, let target = navigation?.view ?? parent?.view else { return }
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(back(_:)))
            gesture.edges = .left; gesture.delegate = self
            target.addGestureRecognizer(gesture); edge = gesture; attachedView = target
        }
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === nativePop { return (navigation?.viewControllers.count ?? 0) > 1 && navigation?.transitionCoordinator == nil }
            return rootBack != nil && (navigation?.viewControllers.count ?? 1) <= 1
        }
        @objc private func back(_ gesture: UIScreenEdgePanGestureRecognizer) {
            if gesture.state == .ended, gesture.translation(in: attachedView).x > 50 { rootBack?() }
        }
        deinit { if let edge = edge { attachedView?.removeGestureRecognizer(edge) } }
    }
}

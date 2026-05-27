import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    private let viewModel = ShareExtensionViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        let rootView = ShareExtensionView(
            viewModel: viewModel,
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: CancellationError())
            },
            onSave: { [weak self] in
                self?.viewModel.save()
            },
            onOpenApp: { [weak self] in
                self?.openApp()
            }
        )

        let hostingController = UIHostingController(rootView: rootView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)

        Task {
            await viewModel.load(from: extensionContext)
        }
    }

    private func openApp() {
        extensionContext?.open(ShareImportStore.importedURL) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}

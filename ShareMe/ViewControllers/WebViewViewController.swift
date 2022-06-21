//
//  WebViewViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 19.06.2022.
//

import WebKit

class WebViewViewController: UIViewController {
    
    private let webView: WKWebView = {
//        let preferences = WKWebpagePreferences()
//        if #available(iOS 14.0, *) {
//            preferences.allowsContentJavaScript = true
//        } else {
//            // Fallback on earlier versions
//        }
        let configuration = WKWebViewConfiguration()
//        configuration.defaultWebpagePreferences = preferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
    
    private let url: URL
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(webView)
        configureButtons()
        webView.load(URLRequest(url: url))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }

    private func configureButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didTapDone))
    }
    
    @objc private func didTapDone() {
        dismiss(animated: true)
    }
    
}

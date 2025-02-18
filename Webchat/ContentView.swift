//
//  ContentView.swift
//  Webchat
//
//  Created by Maulana Nur Ardian on 13/02/25.
//

import SwiftUI
@preconcurrency import WebKit
import AVFoundation

struct WebView: UIViewRepresentable {
    @Binding var progress: Double
    @Binding var isLoading: Bool
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: WebView
        private let audioSession = AVAudioSession.sharedInstance()
        private var filePathCallback: (([URL]?) -> Void)?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.progress = 0.3
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.progress = 1.0
                self.parent.isLoading = false;
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Handle messages from JavaScript
        }
        
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        decisionHandler(granted ? .grant : .deny)
                    }
                }
            } else {
                audioSession.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        decisionHandler(granted ? .grant : .deny)
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first }.first?.rootViewController?.present(picker, animated: true)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true, completion: nil)
            if let imageURL = info[.imageURL] as? URL {
                filePathCallback?([imageURL])
            } else {
                filePathCallback?(nil)
            }
            filePathCallback = nil
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
            filePathCallback?(nil)
            filePathCallback = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        webConfiguration.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "<Server URL>")!))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ContentView: View {
    @State private var progress: Double = 0.0
    @State private var isLoading: Bool = true
    
    var body: some View {
        ZStack {
            WebView(progress: $progress, isLoading: $isLoading)
            
            if isLoading {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: UIScreen.main.bounds.width * 0.4, height: 6)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

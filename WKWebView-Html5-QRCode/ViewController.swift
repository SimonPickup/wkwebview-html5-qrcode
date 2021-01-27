//
//  ViewController.swift
//  WKWebView-Html5-QRCode
//
//  Created by Simon Pickup on 25/01/2021.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupConsoleCapture()
        
        guard let jsPath = Bundle.main.path(forResource: "html5-qrcode.min", ofType: "js"), let jsString = try? String(contentsOfFile: jsPath) else {

            print("Unable to load html5-qrcode.min")
            return
        }
        webView.evaluateJavaScript(jsString)
        
        let url = URL(string: "https://try.html5-qrcode.org/")
        let html = """
        <html>
        <body onload="javascript:showScanner()">
        <p>QR Scanner appears below</p>
        <div id="reader" height="200px"></div>
        <p>QR Scanner appears above</p>
        <script type="text/javascript">
            function onScanSuccess(qrMessage) {
                // handle the scanned code as you like
                console.log(`QR matched = ${qrMessage}`);
            }

            function onScanFailure(error) {
                // handle scan failure, usually better to ignore and keep scanning
                console.warn(`QR error = ${error}`);
            }

            function showScanner() {
                console.log('showing scanner');
                let html5QrcodeScanner = new Html5QrcodeScanner("reader", { fps: 10, qrbox: 250 }, /* verbose= */ true);
                html5QrcodeScanner.render(onScanSuccess, onScanFailure);
            }
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: url)
    }

    private func setupConsoleCapture() {
        // inject JS to capture console.log output and send to iOS
        let source = """
        function sprintf(str, ...args) {
            return args.reduce((_str, val) => _str.replace(/%s|%v|%d|%f|%d/, val), str);
        }
        function captureDebug(str, ...args) {
            var msg = sprintf(str, ...args);
            window.webkit.messageHandlers.logHandler.postMessage({ msg, level: 'debug' });
        }
        function captureInfo(str, ...args) {
            var msg = sprintf(str, ...args);
            window.webkit.messageHandlers.logHandler.postMessage({ msg, level: 'info' });
        }
        function captureLog(str, ...args) {
            var msg = sprintf(str, ...args);
            window.webkit.messageHandlers.logHandler.postMessage({ msg, level: 'log' });
        }
        function captureWarn(str, ...args) {
            var msg = sprintf(str, ...args);
            window.webkit.messageHandlers.logHandler.postMessage({ msg, level: 'warn' });
        }
        function captureError(str, ...args) {
            var msg = sprintf(str, ...args);
            window.webkit.messageHandlers.logHandler.postMessage({ msg, level: 'error' });
        }
        window.console.error = captureError;
        window.console.warn = captureWarn;
        window.console.log = captureLog;
        window.console.debug = captureLog;
        window.console.info = captureLog;
        function captureOnError(str, ...args) {
            var msg = sprintf(str, ...args);
            window.webkit.messageHandlers.logHandler.postMessage({msg, level: 'onerror' });
        }
        window.onerror = captureOnError;
        """
        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        self.webView.configuration.userContentController.addUserScript(script)
        // register the bridge script that listens for the output
        self.webView.configuration.userContentController.add(self, name: "logHandler")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        guard
            let body = message.body as? [String:Any],
            let msg = body["msg"] as? String,
            let level = body["level"] as? String
        else {
            print("Unexpected message format: \(message)")
            return
        }

        switch level {
        case "debug":
            print("🟦 \(msg)")
        case "info":
            print("🟩 \(msg)")
        case "warn":
            print("🟧 \(msg)")
        case "error":
            print("🟥 \(msg)")
        case "onerror":
            print("💥 \(msg)")
        // case "log":
        default:
            print("\(msg)")
        }
    }
}

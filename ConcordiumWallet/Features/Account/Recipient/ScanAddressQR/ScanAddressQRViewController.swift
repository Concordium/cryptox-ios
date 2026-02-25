//
//  ScanAddressQRViewController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 16/04/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import AVFoundation

class ScanAddressQRFactory {
    class func create(with presenter: ScanAddressQRPresenter) -> ScanAddressQRViewController {
        ScanAddressQRViewController.instantiate(fromStoryboard: "SendFund") {coder in
            return ScanAddressQRViewController(coder: coder, presenter: presenter)
        }
    }
}

class ScanAddressQRViewController: BaseViewController, Storyboarded, ShowToast {

	var presenter: ScanAddressQRPresenterProtocol

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    @IBOutlet weak var scanGuide: UIImageView! {
        didSet {
            scanGuide.tintColor = .white
        }
    }
    
    init?(coder: NSCoder, presenter: ScanAddressQRPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "scanQr.title".localized

        presenter.view = self
        presenter.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 1)

        DispatchQueue.global(priority: .background).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func failed() {
        let ac = UIAlertController(title: "scanQr.unsupportedMessage.title".localized,
                message: "scanQr.unsupportedMessage.message".localized,
                preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "ok".localized, style: .default))
        present(ac, animated: true)
//        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            DispatchQueue.global().async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func found(code: String) {
        presenter.scannedQrCode(code)
    }
}

extension ScanAddressQRViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard captureSession.isRunning else { return }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            captureSession.stopRunning()
            found(code: stringValue)
        }
    }
}

extension ScanAddressQRViewController: ScanAddressQRViewProtocol {
    func showQrValid() {
        scanGuide.tintColor = .green
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func showQrInvalid() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        scanGuide.tintColor = .red
        showToast(withMessage: "scanQr.invalidQr".localized)
        
        UIView.animate(withDuration: 0.3, delay: 1.0, animations: {
            self.scanGuide.tintColor = .white
        })
    }
    
    func stopScanner() {
        guard let captureSession = captureSession else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }
    
    func restartScanner() {
        guard let captureSession = captureSession,
              isViewLoaded,
              view.window != nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let captureSession = self.captureSession else { return }
            
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
    
    func dismissScanner() {
        stopScanner()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.presentingViewController != nil {
                self.dismiss(animated: true, completion: nil)
            } else if let navigationController = self.navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else if let navigationController = self.navigationController {
                navigationController.dismiss(animated: true, completion: nil)
            }
        }
    }
}


import SwiftUI
import AVFoundation
import AudioToolbox

struct ScanQRView: View {

    @ObservedObject var flow: AccountsFlowViewModel

    @StateObject private var scanner = QRScannerViewModel()
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {

            QRPreviewView(session: scanner.session)
                .ignoresSafeArea()

            VStack {

                Spacer()

                Image(systemName: "viewfinder")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .foregroundColor(scanner.isValid ? .green : scanner.isInvalid ? .red : .white)

                Spacer()

                Button("Cancel") {
                    scanner.stop()
                    dismiss()
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            scanner.onCodeScanned = { code in
                handleScanned(code)
            }
            scanner.start()
        }
        .onDisappear {
            scanner.stop()
        }
    }

    private func handleScanned(_ code: String) {
        scanner.stop()

        if code.lowercased().contains("wc:") {
            scanner.markValid()
            flow.handleWalletConnect(code)
        } else {
            scanner.markInvalid()
            scanner.restartAfterDelay()
        }
    }
}

@MainActor
final class QRScannerViewModel: NSObject, ObservableObject {

    let session = AVCaptureSession()

    @Published var isValid = false
    @Published var isInvalid = false

    var onCodeScanned: ((String) -> Void)?

    private let metadataOutput = AVCaptureMetadataOutput()

    override init() {
        super.init()
        configure()
    }

    private func configure() {

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }

        session.addInput(input)

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
    }

    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func markValid() {
        isInvalid = false
        isValid = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func markInvalid() {
        isValid = false
        isInvalid = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func restartAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isInvalid = false
            self.start()
        }
    }
}

extension QRScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue
        else { return }

        stop()
        onCodeScanned?(stringValue)
    }
}

struct QRPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds

        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

//
//  ScanAddressQRSwiftUIView.swift
//  ConcordiumWallet
//
//  Unified QR scanner: camera (AVFoundation) + overlay, toolbar, toasts; driven by ViewModel.
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - Dismissible protocol (for UIKit hosting)

protocol ScanAddressQRScannerDismissible: AnyObject {
    func dismissScanner()
}

// MARK: - Main scanner view

struct ScanAddressQRSwiftUIView: View {
    let viewModel: ScanAddressQRViewModel
    var onResult: (QRScannerOutput) -> Void
    var onDismiss: () -> Void

    @State private var isCameraRunning = true
    @State private var scanGuideState: ScanGuideState = .idle
    @State private var showInvalidToast = false
    @State private var showUnsupportedAlert = false

    private enum ScanGuideState {
        case idle
        case valid
        case invalid
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScanAddressQRCameraView(
                isRunning: isCameraRunning,
                onCodeScanned: handleScannedCode,
                onUnsupported: { showUnsupportedAlert = true }
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Image("qr_overlay")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundStyle(scanGuideColor)
                    .frame(maxWidth: 320, maxHeight: 320)
                    .padding(.horizontal, 30)
                Spacer()
            }

            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text("scanQr.title".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                Spacer()
            }
        }
        .toast(isPresented: $showInvalidToast, duration: 1.5, position: .top) {
            Text("scanQr.invalidQr".localized)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(uiColor: .pinkyMain))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .alert("scanQr.unsupportedMessage.title".localized, isPresented: $showUnsupportedAlert) {
            Button("ok".localized) { onDismiss() }
        } message: {
            Text("scanQr.unsupportedMessage.message".localized)
        }
        .onDisappear {
            isCameraRunning = false
        }
    }

    private var scanGuideColor: Color {
        switch scanGuideState {
        case .idle: return .white
        case .valid: return .green
        case .invalid: return .red
        }
    }

    private func handleScannedCode(_ code: String) {
        let result = viewModel.process(code)
        switch result {
        case .valid(let output):
            scanGuideState = .valid
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isCameraRunning = false
            onResult(output)
        case .invalid(let dismissAfterDelay):
            scanGuideState = .invalid
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            showInvalidToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                scanGuideState = .idle
            }
            if dismissAfterDelay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Camera (AVFoundation) – private to this module

private struct ScanAddressQRCameraView: UIViewRepresentable {
    let isRunning: Bool
    let onCodeScanned: (String) -> Void
    let onUnsupported: () -> Void

    func makeUIView(context: Context) -> ScanAddressQRCameraUIView {
        let view = ScanAddressQRCameraUIView()
        view.onCodeScanned = onCodeScanned
        view.onUnsupported = onUnsupported
        view.setupSession()
        return view
    }

    func updateUIView(_ uiView: ScanAddressQRCameraUIView, context: Context) {
        if isRunning {
            uiView.startRunning()
        } else {
            uiView.stopRunning()
        }
    }
}

private final class ScanAddressQRCameraUIView: UIView {
    var onCodeScanned: ((String) -> Void)?
    var onUnsupported: (() -> Void)?

    private var captureSession: AVCaptureSession?
    private var isSessionConfigured = false

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer?.frame = bounds
    }

    func setupSession() {
        guard !isSessionConfigured else { return }

        let session = AVCaptureSession()
        captureSession = session

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async { self.onUnsupported?() }
            return
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            DispatchQueue.main.async { self.onUnsupported?() }
            return
        }

        guard session.canAddInput(videoInput) else {
            DispatchQueue.main.async { self.onUnsupported?() }
            return
        }
        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            DispatchQueue.main.async { self.onUnsupported?() }
            return
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        if let previewLayer = videoPreviewLayer {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }

        isSessionConfigured = true
        startRunning()
    }

    func startRunning() {
        guard let session = captureSession, isSessionConfigured else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            guard session.isRunning == false else { return }
            session.startRunning()
        }
    }

    func stopRunning() {
        guard let session = captureSession else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }
}

extension ScanAddressQRCameraUIView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let session = captureSession, session.isRunning else { return }
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }

        stopRunning()
        DispatchQueue.main.async { [weak self] in
            self?.onCodeScanned?(stringValue)
        }
    }
}

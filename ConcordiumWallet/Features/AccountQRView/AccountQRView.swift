//
//  AccountQRView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 30.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import JDStatusBarNotification

struct AccountQRView: View {
    let account: AccountDataType
    
    
    @SwiftUI.Environment(\.dismiss) var dismiss
    @State private var image: UIImage?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(1.0, contentMode: .fit)
                            .tint(Color.white)
                            .background(Color.clear)
                            .padding(60)
                    }
                }
                .background(.white.opacity(0.63))
                .background(
                    EllipticalGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.62, green: 0.95, blue: 0.92), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.93, green: 0.85, blue: 0.75), location: 0.27),
                            Gradient.Stop(color: Color(red: 0.62, green: 0.6, blue: 0.71), location: 1.00),
                        ],
                        center: UnitPoint(x: 0.09, y: 0.18))
                )
                .cornerRadius(24, corners: .allCorners)
                .aspectRatio(1.0, contentMode: .fit)
                .padding(18)
                
                VStack(alignment: .leading) {
                    Text(account.displayName)
                        .font(.satoshi(size: 19,weight: .medium))
                        .foregroundColor(.white)
                    Text(account.address)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.66, green: 0.68, blue: 0.73))
                }
                .padding(20)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 1)
                )
                Spacer()
                HStack(spacing: 20) {
                    Button {
                        showShareSheet.toggle()
                    } label: {
                        Text("accountAddress.share".localized)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .font(.satoshi(size: 17, weight: .semibold))
                            .padding(.vertical, 11)
                            .background(Color.clear)
                            .overlay(
                                Capsule(style: .circular)
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                    
                    Button {
                        CopyPasterHelper.copy(string: account.address)
                        NotificationPresenter.shared.present("general.copied".localized, includedStyle: .success, duration: 5)
                    } label: {
                        Text("accountAddress.copy")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.black)
                            .font(.satoshi(size: 17, weight: .semibold))
                            .padding(.vertical, 11)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 25)
                .padding(.bottom, 24)
            }
            .padding(18)
            .modifier(AppBackgroundModifier())
        }
        .navigationTitle("accountAddress.title".localized)
        .onAppear {
            generateImage()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [account.address])
        }
    }
    
    private func generateImage() {
        guard image == nil else { return }
        self.image = QRCodeGenerator.generateQRCode(from: account.address)
    }
    
    func actionSheet() {
        let activityVC = UIActivityViewController(activityItems: [account.address as Any], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
    }
}

extension CIImage {
    /// Inverts the colors and creates a transparent image by converting the mask to alpha.
    /// Input image should be black and white.
    var transparent: CIImage? {
        return inverted?.blackTransparent
    }
    
    /// Inverts the colors.
    var inverted: CIImage? {
        guard let invertedColorFilter = CIFilter(name: "CIColorInvert") else { return nil }
        
        invertedColorFilter.setValue(self, forKey: "inputImage")
        return invertedColorFilter.outputImage
    }
    
    /// Converts all black to transparent.
    var blackTransparent: CIImage? {
        guard let blackTransparentFilter = CIFilter(name: "CIMaskToAlpha") else { return nil }
        blackTransparentFilter.setValue(self, forKey: "inputImage")
        return blackTransparentFilter.outputImage
    }
    
    /// Applies the given color as a tint color.
    func tinted(using color: UIColor) -> CIImage?
    {
        guard
            let transparentQRImage = transparent,
            let filter = CIFilter(name: "CIMultiplyCompositing"),
            let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return nil }
        
        let ciColor = CIColor(color: color)
        colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
        let colorImage = colorFilter.outputImage
        
        filter.setValue(colorImage, forKey: kCIInputImageKey)
        filter.setValue(transparentQRImage, forKey: kCIInputBackgroundImageKey)
        
        return filter.outputImage!
    }
}

struct QRCodeGenerator {
    
    static func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 4, y: 4)
        if let qrCodeImage = filter.outputImage?.transparent?.inverted?.transformed(by: transform) {
            if let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
                return UIImage(cgImage: qrCodeCGImage)
            }
        }
        
        return UIImage()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

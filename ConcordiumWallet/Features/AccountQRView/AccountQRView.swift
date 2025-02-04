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
        VStack(spacing: 14) {
            Text("to \(account.displayName)")
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish2)
            VStack(alignment: .center, spacing: 30) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .renderingMode(.template)
                        .interpolation(.none)
                        .aspectRatio(1.0, contentMode: .fit)
                        .foregroundStyle(.white)
                }
                
                Text(account.address)
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 35) {
                    
                    Button {
                        CopyPasterHelper.copy(string: account.address)
                        NotificationPresenter.shared.present("general.copied".localized, includedStyle: .success, duration: 5)
                    } label: {
                        HStack(spacing: 8) {
                            Image("Copy")
                            Text("accountAddress.copy")
                                .foregroundColor(.white)
                                .font(.satoshi(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(.white.opacity(0.07))
                        .cornerRadius(4)
                    }
                    
                    Button {
                        showShareSheet.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image("PaperPlaneTilt")
                            Text("accountAddress.share".localized)
                                .foregroundColor(.white)
                                .font(.satoshi(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(.white.opacity(0.07))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(60)
            .modifier(FloatingGradientBGStyleModifier())
            .cornerRadius(16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 20)
        .padding(18)
        .modifier(AppBackgroundModifier())
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

#Preview {
    AccountQRView(account: AccountDataTypeFactory.create())
}

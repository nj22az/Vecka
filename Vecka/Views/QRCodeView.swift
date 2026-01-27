//
//  QRCodeView.swift
//  Vecka
//
//  QR Code generation and scanning for contact sharing
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation

struct QRCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let contact: Contact

    @State private var qrCodeImage: UIImage?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // Contact info
                VStack(spacing: 12) {
                    if let imageData = contact.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                    } else {
                        // 情報デザイン: White background with black border, black text
                        Circle()
                            .fill(colors.surface)
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(colors.border, lineWidth: 2))
                            .overlay {
                                Text(contact.initials)
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colors.primary)
                            }
                    }

                    Text(contact.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let organization = contact.organizationName {
                        Text(organization)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // QR Code - 情報デザイン styling
                if let qrImage = qrCodeImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .background(colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(colors.border, lineWidth: 2)
                        )
                } else {
                    ProgressView()
                        .frame(width: 250, height: 250)
                }

                Text("Scan this QR code to save contact")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Share button
                Button {
                    shareQRCode()
                } label: {
                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Contact QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateQRCode()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    private func generateQRCode() {
        // Exclude photo from QR code to keep it scannable
        let vcard = contact.toVCard(includePhoto: false)

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(vcard.utf8)
        filter.correctionLevel = "H" // High error correction for better scanning

        guard let outputImage = filter.outputImage else { return }

        // Scale up for high quality (20x gives us crisp QR codes)
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        let scaledImage = outputImage.transformed(by: transform)

        // Add quiet zone (white border) for better scanning
        let quietZoneSize: CGFloat = 40
        let imageSize = scaledImage.extent.size
        let finalSize = CGSize(
            width: imageSize.width + quietZoneSize * 2,
            height: imageSize.height + quietZoneSize * 2
        )

        let renderer = UIGraphicsImageRenderer(size: finalSize)
        let finalImage = renderer.image { _ in
            // White background
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: finalSize))

            // Draw QR code centered
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let qrImage = UIImage(cgImage: cgImage)
                qrImage.draw(at: CGPoint(x: quietZoneSize, y: quietZoneSize))
            }
        }

        qrCodeImage = finalImage
    }

    private func shareQRCode() {
        guard let qrImage = qrCodeImage else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(contact.displayName)-QR.png"
        let url = tempDir.appendingPathComponent(filename)

        if let data = qrImage.pngData() {
            do {
                try data.write(to: url)
                shareURL = url
                showingShareSheet = true
            } catch {
                print("Failed to save QR code: \(error)")
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - QR Code Scanner

struct QRCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @StateObject private var scanner = QRScannerViewModel()
    @State private var showingImportedContact = false
    @State private var importedContact: Contact?

    var body: some View {
        NavigationStack {
            ZStack {
                QRScannerViewRepresentable(scanner: scanner)

                VStack {
                    Spacer()

                    if scanner.isScanning {
                        Text("Point camera at QR code")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .padding()
                            .background(
                                Squircle(cornerRadius: 12)
                                    .fill(colors.surface)
                            )
                            .overlay(
                                Squircle(cornerRadius: 12)
                                    .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                            )
                            .padding()
                    }
                }
            }
            .navigationTitle("Scan Contact QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: scanner.scannedVCard) { _, vcard in
                if let vcard = vcard, let contact = Contact.fromVCard(vcard) {
                    importedContact = contact
                    showingImportedContact = true
                }
            }
            .sheet(isPresented: $showingImportedContact) {
                NavigationStack {
                    if let scannedContact = importedContact {
                        ContactDetailView(contact: scannedContact)
                    }
                }
            }
        }
    }
}

class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = true
    @Published var scannedVCard: String?

    var captureSession: AVCaptureSession?

    func startScanning() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        captureSession?.stopRunning()
        isScanning = false
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            // Check if this is a vCard
            if stringValue.hasPrefix("BEGIN:VCARD") {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                scannedVCard = stringValue
                stopScanning()
            }
        }
    }
}

struct QRScannerViewRepresentable: UIViewRepresentable {
    @ObservedObject var scanner: QRScannerViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        scanner.startScanning()

        if let captureSession = scanner.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            // Add scanning frame overlay
            let overlayView = QRScannerOverlayView()
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(overlayView)

            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: view.topAnchor),
                overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // Clean up capture session
    }
}

class QRScannerOverlayView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Semi-transparent background
        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(rect)

        // Clear center square
        let squareSize: CGFloat = 250
        let squareRect = CGRect(
            x: (rect.width - squareSize) / 2,
            y: (rect.height - squareSize) / 2,
            width: squareSize,
            height: squareSize
        )

        context.setBlendMode(.destinationOut)
        context.fill(squareRect)

        // Draw border
        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(3)
        context.stroke(squareRect)

        // Draw corner accents
        let cornerLength: CGFloat = 20
        let corners: [(CGPoint, CGPoint)] = [
            // Top-left
            (CGPoint(x: squareRect.minX, y: squareRect.minY), CGPoint(x: squareRect.minX + cornerLength, y: squareRect.minY)),
            (CGPoint(x: squareRect.minX, y: squareRect.minY), CGPoint(x: squareRect.minX, y: squareRect.minY + cornerLength)),
            // Top-right
            (CGPoint(x: squareRect.maxX, y: squareRect.minY), CGPoint(x: squareRect.maxX - cornerLength, y: squareRect.minY)),
            (CGPoint(x: squareRect.maxX, y: squareRect.minY), CGPoint(x: squareRect.maxX, y: squareRect.minY + cornerLength)),
            // Bottom-left
            (CGPoint(x: squareRect.minX, y: squareRect.maxY), CGPoint(x: squareRect.minX + cornerLength, y: squareRect.maxY)),
            (CGPoint(x: squareRect.minX, y: squareRect.maxY), CGPoint(x: squareRect.minX, y: squareRect.maxY - cornerLength)),
            // Bottom-right
            (CGPoint(x: squareRect.maxX, y: squareRect.maxY), CGPoint(x: squareRect.maxX - cornerLength, y: squareRect.maxY)),
            (CGPoint(x: squareRect.maxX, y: squareRect.maxY), CGPoint(x: squareRect.maxX, y: squareRect.maxY - cornerLength))
        ]

        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(5)

        for (start, end) in corners {
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }
    }
}

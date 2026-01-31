//
//  QRCodeView.swift
//  Vecka
//
//  情報デザイン: QR Code sharing for contacts - beautiful bento card presentation
//  Like ShareableFact, presents contact QR code in a pretty card format
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation

// MARK: - Contact QR Card Sheet (情報デザイン styled)

/// Beautiful QR code card for sharing contacts
/// Follows the ShareableFact pattern with bento compartmentalization
struct ContactQRCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let contact: Contact

    @State private var qrCodeImage: UIImage?

    private let cornerRadius: CGFloat = 16

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// Contact group color for accents
    private var accentColor: Color {
        Color(hex: contact.group.avatarColor)
    }

    var body: some View {
        ZStack {
            // Background
            colors.surface
                .ignoresSafeArea()

            VStack(spacing: JohoDimensions.spacingLG) {
                // Close button at top
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .frame(width: 36, height: 36)
                            .background(colors.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)

                Spacer()

                // The QR Card (情報デザイン bento style)
                qrCard
                    .frame(width: 340)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Share button
                if let qrImage = qrCodeImage {
                    ShareLink(
                        item: Image(uiImage: qrImage),
                        preview: SharePreview(
                            "\(contact.displayName) QR Code",
                            image: Image(uiImage: qrImage)
                        )
                    ) {
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("Share QR Code")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(colors.primaryInverted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(colors.border, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
            }
            .padding(.vertical, JohoDimensions.spacingLG)
        }
        .onAppear {
            generateQRCode()
        }
    }

    // MARK: - QR Card (Bento Style like ShareableFact)

    private var qrCard: some View {
        ZStack {
            // Layer 1: Solid background
            cardShape
                .fill(colors.surface)

            // Layer 2: Content compartments
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER: App branding + contact group icon
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: App branding
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Text("CONTACTS")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.leading, JohoDimensions.spacingMD)

                    Spacer()

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Group icon
                    Image(systemName: contact.group.icon)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 48)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 40)
                .background(accentColor.opacity(0.3))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // MAIN CONTENT: Contact info + QR Code
                // ═══════════════════════════════════════════════════════════════
                VStack(spacing: JohoDimensions.spacingMD) {
                    // Contact avatar and name
                    HStack(spacing: JohoDimensions.spacingMD) {
                        // Avatar
                        ZStack {
                            if let imageData = contact.imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(colors.border, lineWidth: 2))
                            } else {
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(contact.initials.isEmpty ? "?" : contact.initials)
                                            .font(.system(size: 20, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                    )
                                    .overlay(Circle().stroke(colors.border, lineWidth: 2))
                            }
                        }

                        // Name and org
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.displayName)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .lineLimit(2)

                            if let org = contact.organizationName, !org.isEmpty {
                                Text(org)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }

                    // QR Code (large, centered)
                    if let qrImage = qrCodeImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 200, height: 200)
                            .background(colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(colors.border, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.surface)
                            .frame(width: 200, height: 200)
                            .overlay(
                                ProgressView()
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(colors.border, lineWidth: 2)
                            )
                    }

                    // Quick contact info
                    HStack(spacing: JohoDimensions.spacingMD) {
                        if let phone = contact.phoneNumbers.first {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.green)
                                Text(phone.value)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.primary)
                                    .lineLimit(1)
                            }
                        }

                        if let email = contact.emailAddresses.first {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.yellow)
                                Text(email.value)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(JohoDimensions.spacingMD)
                .background(accentColor.opacity(0.1))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // FOOTER: Instructions
                // ═══════════════════════════════════════════════════════════════
                HStack {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))

                    Text("SCAN TO SAVE CONTACT")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    // Group badge
                    Text(contact.group.localizedName.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                        .tracking(0.5)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(height: 32)
            }
            .clipShape(cardShape)

            // Layer 3: Border
            cardShape
                .strokeBorder(colors.border, lineWidth: 3)
        }
    }

    // MARK: - QR Code Generation

    private func generateQRCode() {
        // Exclude photo from QR code to keep it scannable
        let vcard = contact.toVCard(includePhoto: false)

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(vcard.utf8)
        filter.correctionLevel = "H" // High error correction

        guard let outputImage = filter.outputImage else { return }

        // Scale up for high quality
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return }

        qrCodeImage = UIImage(cgImage: cgImage)
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

// MARK: - Preview

#Preview("Contact QR Card") {
    let previewContact = Contact(
        givenName: "John",
        familyName: "Smith",
        organizationName: "Acme Corporation",
        phoneNumbers: [
            ContactPhoneNumber(label: "mobile", value: "+1-555-0123")
        ],
        emailAddresses: [
            ContactEmailAddress(label: "work", value: "john.smith@acme.com")
        ],
        group: .work
    )

    ContactQRCardSheet(contact: previewContact)
}

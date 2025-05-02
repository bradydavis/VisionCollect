//
//  CameraView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraModel = CameraModel()
    @EnvironmentObject var measurementStore: MeasurementStore
    @Environment(\.presentationMode) var presentationMode
    let instrumentType: String

    var body: some View {
        ZStack {
            if cameraModel.isSessionRunning {
                CameraPreview(session: cameraModel.session)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()
                    Button(action: cameraModel.capturePhoto) {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 20)
                }
            } else {
                ProgressView("Setting up camera...")
            }
        }
        .onAppear {
            print("CameraView appeared for \(instrumentType)")
            cameraModel.checkPermissions()
        }
        .onDisappear {
            print("CameraView disappeared for \(instrumentType)")
            cameraModel.stopSession()
        }
        .alert(isPresented: $cameraModel.showAlertError) {
            Alert(title: Text("Error"), message: Text(cameraModel.alertError), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $cameraModel.showCapturedImage) {
            if let image = cameraModel.capturedImage {
                CapturedImageView(originalImage: image, onSave: { croppedImage in
                    saveImage(croppedImage)
                })
            }
        }
    }

    private func saveImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        measurementStore.addMeasurement(
            imageData: imageData,
            instrumentType: instrumentType,
            userName: measurementStore.currentUser,
            projectNumber: measurementStore.currentProjectNumber
        )
        presentationMode.wrappedValue.dismiss()
    }
    
    private func cropImage(_ inputImage: UIImage) -> UIImage {
        let imageSize = inputImage.size
        
        // Calculate the crop rect
        let cropWidth = imageSize.width - 100 // 50 pixels from each side
        let cropHeight = imageSize.height - 200 // 100 pixels from top and bottom
        let originX: CGFloat = 50
        let originY: CGFloat = 100
        
        // Ensure the crop size is square
        let squareSize = min(cropWidth, cropHeight)
        let squareOriginX = originX + (cropWidth - squareSize) / 2
        let squareOriginY = originY + (cropHeight - squareSize) / 2
        
        let cropRect = CGRect(x: squareOriginX, y: squareOriginY, width: squareSize, height: squareSize)
        
        // Perform the crop
        guard let cgImage = inputImage.cgImage?.cropping(to: cropRect) else {
            return inputImage // Return original image if cropping fails
        }
        
        return UIImage(cgImage: cgImage, scale: inputImage.scale, orientation: inputImage.imageOrientation)
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var alertError: String = ""
    @Published var showAlertError = false
    @Published var capturedImage: UIImage?
    @Published var showCapturedImage = false
    @Published var isSessionRunning = false

    private var output = AVCapturePhotoOutput()

    override init() {
        super.init()
    }

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setUp()
                    }
                }
            }
        case .denied, .restricted:
            alertError = "Camera access is required to use this feature."
            showAlertError = true
        @unknown default:
            break
        }
    }

    private func setUp() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            do {
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                let input = try AVCaptureDeviceInput(device: device!)
                
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }

                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                }
                
                self.session.commitConfiguration()
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                    print("Camera session is running: \(self.isSessionRunning)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertError = "Failed to set up camera: \(error.localizedDescription)"
                    self.showAlertError = true
                    print("Camera setup error: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopSession() {
        session.stopRunning()
        isSessionRunning = false
        print("Camera session stopped")
    }

    func capturePhoto() {
        DispatchQueue.global(qos: .userInitiated).async {
            let settings = AVCapturePhotoSettings()
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            alertError = error.localizedDescription
            showAlertError = true
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            alertError = "Failed to process captured image"
            showAlertError = true
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
            self.showCapturedImage = true
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct CapturedImageView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var croppedImage: UIImage?

    var body: some View {
        VStack {
            if let croppedImage = croppedImage {
                Image(uiImage: croppedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
            HStack {
                Button("Retake") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("Save") {
                    if let croppedImage = croppedImage {
                        onSave(croppedImage)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            croppedImage = cropImage(originalImage)
        }
    }

    private func cropImage(_ inputImage: UIImage) -> UIImage {
        let imageSize = inputImage.size
        
        // Calculate the crop rect
        let cropWidth = imageSize.width - 100 // 50 pixels from each side
        let cropHeight = imageSize.height - 200 // 100 pixels from top and bottom
        let originX: CGFloat = 50
        let originY: CGFloat = 100
        
        // Ensure the crop size is square
        let squareSize = min(cropWidth, cropHeight)
        let squareOriginX = originX + (cropWidth - squareSize) / 2
        let squareOriginY = originY + (cropHeight - squareSize) / 2
        
        let cropRect = CGRect(x: squareOriginX, y: squareOriginY, width: squareSize, height: squareSize)
        
        // Perform the crop
        guard let cgImage = inputImage.cgImage?.cropping(to: cropRect) else {
            return inputImage // Return original image if cropping fails
        }
        
        return UIImage(cgImage: cgImage, scale: inputImage.scale, orientation: inputImage.imageOrientation)
    }
}

//
//  HomeViewController.swift
//  CoreMLSample
//
//  Created by Daiki Kobayashi on 2024/11/02.
//

import UIKit
import CoreML
import Vision

final class HomeViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!
    private let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupView()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "CoreML Sample"
        
        let cameraButtonItem = UIBarButtonItem(image: UIImage(systemName: "camera"), style: .done, target: self, action: #selector(didTapCameraButton(_:)))
        navigationItem.rightBarButtonItem = cameraButtonItem
    }
    
    private func setupView() {
        setupImagePicker()
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }
    
    // MARK: - イベント
    
    @objc private func didTapCameraButton(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true)
    }
}

// MARK: - UINavigationControllerDelegate

extension HomeViewController: UINavigationControllerDelegate {}

// MARK: - UIImagePickerControllerDelegate

extension HomeViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userSelectedImage = info[.originalImage] as? UIImage {
            imageView.image = userSelectedImage
            
            detectImageObject(image: userSelectedImage)
        }
        imagePicker.dismiss(animated: true)
    }
    
    private func detectImageObject(image: UIImage) {
        
        guard let ciImage = CIImage(image: image) else { return }
        let coreMLModel = VNCoreMLModelManager.createImageClassifier()
        
        // Core MLモデルを使用して画像を処理する画像解析リクエスト
        let request = VNCoreMLRequest(model: coreMLModel) { request, error in
            // 解析結果を分類情報として保存
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            // 画像内の一番割合が大きいオブジェクトを出力する
            if let firstResult = results.first {
                let objectArray = firstResult.identifier.components(separatedBy: ",")
                if objectArray.count == 1 {
                    self.navigationItem.title = firstResult.identifier
                } else {
                    self.navigationItem.title = objectArray.first
                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
}

struct VNCoreMLModelManager {
    static func createImageClassifier() -> VNCoreMLModel {
        // Use a default model configuration.
        let defaultConfig = MLModelConfiguration()
        
        
        // Create an instance of the image classifier's wrapper class.
        let imageClassifierWrapper = try? MobileNetV2(configuration: defaultConfig)
        
        
        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }
        
        
        // Get the underlying model instance.
        let imageClassifierModel = imageClassifier.model
        
        
        // Create a Vision instance using the image classifier's model instance.
        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        
        
        return imageClassifierVisionModel
    }
}

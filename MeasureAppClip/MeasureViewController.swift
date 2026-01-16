//
//  MeasureViewController.swift
//  MeasureAppClip
//
//  Created by Ploggvn on 15/1/26.
//  Copyright © 2026 levantAJ. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

final class MeasureViewController: UIViewController {
    // MARK: - UI Elements (Programmatic)
    private lazy var sceneView: ARSCNView = {
        let view = ARSCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var targetImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "targetWhite"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        return indicator
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return label
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "trash.circle.fill"), for: .normal)
        button.tintColor = .white
        button.isHidden = true
        button.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var meterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Unit", for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.addTarget(self, action: #selector(meterButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Logic Properties
    fileprivate lazy var session = ARSession()
    fileprivate lazy var sessionConfiguration = ARWorldTrackingConfiguration()
    fileprivate lazy var isMeasuring = false
    fileprivate lazy var vectorZero = SCNVector3()
    fileprivate lazy var startValue = SCNVector3()
    fileprivate lazy var endValue = SCNVector3()
    fileprivate lazy var lines: [Line] = []
    fileprivate var currentLine: Line?
    fileprivate lazy var unit: DistanceUnit = .centimeter
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetValues()
        isMeasuring = true
        targetImageView.image = UIImage(named: "targetGreen")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMeasuring = false
        targetImageView.image = UIImage(named: "targetWhite")
        if let line = currentLine {
            lines.append(line)
            currentLine = nil
            resetButton.isHidden = false
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - UI Setup
extension MeasureViewController {
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(sceneView)
        view.addSubview(targetImageView)
        view.addSubview(loadingView)
        view.addSubview(messageLabel)
        view.addSubview(resetButton)
        view.addSubview(meterButton)
        
        NSLayoutConstraint.activate([
            // SceneView Full Screen
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Center Target
            targetImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            targetImageView.widthAnchor.constraint(equalToConstant: 30),
            targetImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // Loading
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Message Label
            messageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            
            // Reset Button
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 44),
            resetButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Meter Button (Settings)
            meterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            meterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
}

// MARK: - ARSCNViewDelegate
extension MeasureViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.detectObjects()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        messageLabel.text = "Error occurred"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "Interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "Interruption ended"
    }
}

// MARK: - Actions
extension MeasureViewController {
    @objc func meterButtonTapped() {
        let alertVC = UIAlertController(title: "Settings", message: "Select distance unit", preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "Centimeter", style: .default) { [weak self] _ in
            self?.unit = .centimeter
        })
        alertVC.addAction(UIAlertAction(title: "Inch", style: .default) { [weak self] _ in
            self?.unit = .inch
        })
        alertVC.addAction(UIAlertAction(title: "Meter", style: .default) { [weak self] _ in
            self?.unit = .meter
        })
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Cần thiết cho iPad nếu chạy App Clip trên iPad
        if let popover = alertVC.popoverPresentationController {
            popover.sourceView = meterButton
            popover.sourceRect = meterButton.bounds
        }
        
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc func resetButtonTapped() {
        resetButton.isHidden = true
        for line in lines {
            line.removeFromParentNode()
        }
        lines.removeAll()
    }
}

// MARK: - Privates Logic
extension MeasureViewController {
    fileprivate func setupScene() {
        sceneView.delegate = self
        sceneView.session = session
        loadingView.startAnimating()
        messageLabel.text = "Detecting the world…"
        resetButton.isHidden = true
        
        session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
    }
    
    fileprivate func resetValues() {
        isMeasuring = false
        startValue = SCNVector3()
        endValue = SCNVector3()
    }
    
    fileprivate func detectObjects() {
            guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
            
            if lines.isEmpty {
                messageLabel.text = "Hold screen & move your phone…"
            }
            loadingView.stopAnimating()
            
            if isMeasuring {
                if startValue.x == vectorZero.x && startValue.y == vectorZero.y && startValue.z == vectorZero.z {
                    startValue = worldPosition
                    currentLine = Line(sceneView: sceneView, startVector: startValue, unit: unit)
                }
                endValue = worldPosition
                currentLine?.update(to: endValue)
                // Tính khoảng cách real-time nếu muốn hiển thị ở label
                // messageLabel.text = currentLine?.distance(to: endValue)
            }
        }
}


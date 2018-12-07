//
//  ViewController.swift
//  ballerone
//
//  Created by LLOYD Briggs on 12/6/18.
//  Copyright © 2018 LLOYD Briggs. All rights reserved.
//

//import UIKit
//import SceneKit
import ARKit
import CoreMotion

final class ViewController: UIViewController {
    var ball: SCNNode?
    var timer: Timer?
    let motion = CMMotionManager()

    static var fromStoryboard: ViewController {
        let storyboardID = "ObjectsOnPlanesViewController"
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: storyboardID) as! ViewController
    }

    @IBOutlet weak var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Plane Detection"
        navigationItem.largeTitleDisplayMode = .never;
        let reloadButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reload))
        navigationItem.rightBarButtonItem = reloadButton

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reload()

        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touchLocation = touches.first?.location(in: sceneView) else { return }
        let hitTest = sceneView.hitTest(touchLocation, types: .existingPlaneUsingGeometry)
        if !hitTest.isEmpty {
            if ball != nil { ball?.removeFromParentNode() }
            ball = renderBall()
            let transform = hitTest.first!.worldTransform
            let position = transform.columns.3
            let x = position.x
            let y = position.y + 0.01
            let z = position.z
            ball!.position = SCNVector3(x, y, z)
            sceneView.scene.rootNode.addChildNode(ball!)
            self.startAccelerometers(withBall: ball!)
        }
    }

    private func renderBall() -> SCNNode {
        let ball = SCNSphere(radius: 0.03)
        let node = SCNNode(geometry: ball)

        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: node, options: [
            SCNPhysicsShape.Option.keepAsCompound: true
        ]))
        node.physicsBody?.friction = CGFloat(0.1)
        node.physicsBody?.rollingFriction = CGFloat(0.1)
        node.physicsBody?.isAffectedByGravity = true
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple;

        return node
    }
    
    private func applyForce(withBall ball: SCNNode, forward: Double, right: Double) {
        ball.physicsBody?.clearAllForces()
        ball.physicsBody?.applyForce(SCNVector3(right, 0.0, forward), asImpulse: true)
    }

    private func startAccelerometers(withBall ball: SCNNode) {
        if self.motion.isAccelerometerAvailable {
            self.applyForce(withBall: ball, forward: 0.0, right: 0.0)
            var originX: Double?
            var originZ: Double?
            var appliedForward = false
            var appliedRight = false
            var currentForward = 0.0
            var currentRight = 0.0
            let forceFactor = 0.2
            self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
            self.motion.startAccelerometerUpdates()
            self.timer?.invalidate()
            self.timer = Timer(fire: Date(), interval: (1.0/6.0), repeats: true, block: {(timer) in
                if let data = self.motion.accelerometerData {
                    if originX == nil { originX = data.acceleration.x }
                    if originZ == nil { originZ = data.acceleration.z }
                    let currentX = data.acceleration.x
                    let currentZ = data.acceleration.z
                    let forwardForce = originZ! > currentZ
                    let rightForce = originX! > currentX
                    if forwardForce {
                        if !appliedForward {
                            print("forward")
                            appliedForward = true
                            currentForward = forceFactor * -1.0
                        }
                    } else {
                        if appliedForward {
                            print("backward")
                            appliedForward = false
                            currentForward = forceFactor
                        }
                    }
                    if rightForce {
                        if !appliedRight {
                            print("right")
                            appliedRight = true
                            currentRight = forceFactor
                        }
                    } else {
                        if appliedRight {
                            print("left")
                            appliedRight = false
                            currentRight = forceFactor * -1.0
                        }
                    }
                    self.applyForce(withBall: ball, forward: currentForward, right: currentRight)
                }
            })

            RunLoop.current.add(self.timer!, forMode: .default)
        }
    }

    @objc
    func reload() {
        // Remove existing nodes, if any
        sceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ViewController: ARSCNViewDelegate {
    // When we detect a plane, visualize it by giving the node geometry
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let basePlane = Plane(anchor: planeAnchor, in: sceneView)
        node.addChildNode(basePlane)
    }

    // When we detect an update to a plane, replace previous geometry with new
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let basePlane = Plane(anchor: planeAnchor, in: sceneView)
        node.childNodes.forEach { $0.removeFromParentNode() }
        node.addChildNode(basePlane)
    }

    // When we remove a plane, remove all visualizations
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else { return }
        node.childNodes.forEach { $0.removeFromParentNode() }
    }
}

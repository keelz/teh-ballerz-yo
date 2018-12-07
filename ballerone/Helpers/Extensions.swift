//
//  Extensions.swift
//  MT ARKit Starter
//
//  Created by Phil Tseng on 10/29/18.
//  Copyright © 2018 Metal Toad. All rights reserved.
//

import ARKit

extension ARSCNView {
    // Provides a convenient pointer position vector one meter in front of the camera
    var currentCameraPointer: SCNVector3? {
        guard let pov = pointOfView else { return nil }
        let position = pov.position
        let direction = pov.worldFront
        return SCNVector3(position.x + direction.x, position.y + direction.y + 1, position.z + direction.z)
    }
    
    // Describes the camera's rotation as a quaternion
    var currentCameraOrientation: SCNQuaternion? {
        guard let pov = pointOfView else { return nil }
        return pov.orientation
    }
    
    // Provides the normalized -Z vector in front of the camera
    var currentCameraDirection: SCNVector3? {
        guard let pov = pointOfView else { return nil }
        return pov.worldFront
    }
}

extension SCNNode {
    func centerAlign() {
        let (min, max) = boundingBox
        let extents = float3(max) - float3(min)
        simdPivot = float4x4(translation: ((extents / 2) + float3(min)))
    }
}

extension float4x4 {
    init(translation vector: float3) {
        self.init(float4(1, 0, 0, 0),
                  float4(0, 1, 0, 0),
                  float4(0, 0, 1, 0),
                  float4(vector.x, vector.y, vector.z, 1))
    }
}

@available(iOS 12.0, *)
extension ARPlaneAnchor.Classification {
    var description: String {
        switch self {
        case .wall:
            return "Wall"
        case .floor:
            return "Floor"
        case .ceiling:
            return "Ceiling"
        case .table:
            return "Table"
        case .seat:
            return "Seat"
        case .none(.unknown):
            return "Unknown"
        default:
            return ""
        }
    }
}

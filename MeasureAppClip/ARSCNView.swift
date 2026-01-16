//
//  ARSCNView.swift
//  Measure
//
//  Created by levantAJ on 8/9/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import SceneKit
import ARKit

extension ARSCNView {
    func realWorldVector(screenPosition: CGPoint) -> SCNVector3? {
 
        guard let query = self.raycastQuery(from: screenPosition,
                                            allowing: .estimatedPlane,
                                            alignment: .any) else {
            return nil
        }
        
        let results = self.session.raycast(query)
        
        guard let result = results.first else { return nil }
        
        return SCNVector3.positionFromTransform(result.worldTransform)
    }
}

//
//  GameScene.swift
//  Simple SpriteKit Game
//
//  Created by Daniel Pratt on 1/12/18.
//  Copyright © 2018 Daniel Pratt. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let player = SKSpriteNode(imageNamed: "player")
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.lightGray
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        addChild(player)
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        // create the sprite
        let monster = SKSpriteNode(imageNamed: "monster")
        
        // determine where to spawn the monster along the y axis
        let actualY = random(min: monster.size.height / 2, max: size.height - monster.size.height)
        
        // position the monster slightly off-screen along right edge
        monster.position = CGPoint(x: size.width + monster.size.width / 2, y: actualY)
        
        // add monster to the scene
        addChild(monster)
        
        // determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width / 2, y: actualY) , duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
}

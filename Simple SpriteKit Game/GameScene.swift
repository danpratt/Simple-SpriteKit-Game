//
//  GameScene.swift
//  Simple SpriteKit Game
//
//  Created by Daniel Pratt on 1/12/18.
//  Copyright © 2018 Daniel Pratt. All rights reserved.
//

import SpriteKit
import GameplayKit

// Overloads

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
    
}

// Physics Category
struct PhysicsCategory {
    static let None : UInt32 = 0
    static let All : UInt32 = UInt32.max
    static let Monster: UInt32 = 0b1  // 1
    static let ThrowingStar: UInt32 = 0b10 // 2
    
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let player = SKSpriteNode(imageNamed: "player")
    let background = SKSpriteNode(imageNamed: "gameBackground")
    var monstersDestroyed = 0
    
    override func didMove(to view: SKView) {
        background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        background.zPosition = 0
        addChild(background)
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        addChild(player)
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
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
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        monster.physicsBody?.isDynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.ThrowingStar
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        // determine where to spawn the monster along the y axis
        let actualY = random(min: monster.size.height / 2, max: size.height - monster.size.height)
        
        // position the monster slightly off-screen along right edge
        monster.position = CGPoint(x: size.width + monster.size.width / 2, y: actualY)
        
        // add monster to the scene
        addChild(monster)
        
        // determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width / 2, y: actualY) , duration: TimeInterval(actualDuration))
//        let actionMoveDone = SKAction.removeFromParent()
        let loseAction = SKAction.run() {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, didWin: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Choose one of the thouches to work with
        guard let touch = touches.first else {
            return
        }
        
        let touchlocation = touch.location(in: self)
        
        // setup throwing star image and initial position
        let throwingStar = SKSpriteNode(imageNamed: "projectile")
        throwingStar.position = player.position
        
        // Setup Physics
        throwingStar.physicsBody = SKPhysicsBody(circleOfRadius: throwingStar.size.width/2)
        throwingStar.physicsBody?.isDynamic = true
        throwingStar.physicsBody?.categoryBitMask = PhysicsCategory.ThrowingStar
        throwingStar.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        throwingStar.physicsBody?.collisionBitMask = PhysicsCategory.None
        throwingStar.physicsBody?.usesPreciseCollisionDetection = true
        
        // setup offset
        let offset = touchlocation - throwingStar.position
        
        // don't throw backwards
        if offset.x < 0 { return }
        
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        // add the throwing star to the scene
        addChild(throwingStar)
        
        // get direction of where to shoot
        let direction = offset.normalized()
        
        // make sure it goes far enough to leave the screen
        let shootAmount = direction * 1000
        
        // add the shoot amount to the current position
        let realDest = shootAmount + throwingStar.position
        
        // create the action
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionDone = SKAction.removeFromParent()
        throwingStar.run(SKAction.sequence([actionMove, actionDone]))
    }
    
    // handle physics engine contact
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.ThrowingStar != 0)) {
            if let monster = firstBody.node as? SKSpriteNode, let
                throwingStar = secondBody.node as? SKSpriteNode {
                throwingStarDidCollideWithMonster(throwingStar: throwingStar, monster: monster)
            }
        }
    }
    
    // Handle removing monster after hit
    func throwingStarDidCollideWithMonster(throwingStar: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit")
        throwingStar.removeFromParent()
        monster.removeFromParent()
        monstersDestroyed += 1
        if (monstersDestroyed > 10) {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, didWin: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
}

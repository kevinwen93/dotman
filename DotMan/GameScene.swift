import SpriteKit

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

func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let xDist = a.x - b.x
    let yDist = a.y - b.y
    return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
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

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let hero   : UInt32 = 0b1       // 1
    static let arrow: UInt32 = 0b1 << 1      // 2
    static let blade: UInt32 = 0b1 << 2    // 3
    static let region_hero: UInt32 = 0b1 << 3      //4
    static let world: UInt32 = 0b1 << 4        //5
}

enum action{
    case bladeAction, archerAction, runAction
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    
    let hero = SKSpriteNode(imageNamed: "ship_hero")
    let enemy = SKSpriteNode(imageNamed: "ship_enemy")
    
    let move_base = SKSpriteNode(imageNamed: "base")
    let move_stick = SKSpriteNode(imageNamed: "stick")
    
    let att_base = SKSpriteNode(imageNamed: "base")
    let att_stick = SKSpriteNode(imageNamed: "stick")
    
    let select_base = SKSpriteNode(imageNamed: "select_base")
    let archerSelect = SKSpriteNode(imageNamed: "archer")
    let bladeSelect = SKSpriteNode(imageNamed: "blade")
    
    
    let archer = SKSpriteNode(imageNamed: "archer")
    let blade = SKSpriteNode(imageNamed: "blade")
    
    var moveActive:Bool = false
    var attActive:Bool = false
    
    var selectBladeNow:Bool = false
    
    var validMove:UITouch?
    var validAtt:UITouch?
    
    var arrayArrow :[SKSpriteNode] = [SKSpriteNode]()
    
    var framecount = 0
    
    var actionList = Array(repeating: 0.333, count: 3)
    
    
    override func didMove(to view: SKView) {
        //background white
        //backgroundColor = SKColor.white
        
        let background = SKSpriteNode(imageNamed: "space_gamescene")
        background.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        background.zPosition = -1
        addChild(background)
        
        //Initial position of hero
        hero.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        enemy.position = CGPoint(x:size.width*0.9, y:size.height*0.5)
        
        //add to screen
        addChild(hero)
        addChild(enemy)
        
        //movement stick initialization
        move_base.position = CGPoint(x: size.width * 0.1, y: size.height * 0.15)
        addChild(move_base)
        
        move_stick.position = move_base.position
        addChild(move_stick)
        
        move_base.alpha = 0.6
        move_stick.alpha = 0.6
 
        //attack stick initialization
        att_base.position = CGPoint(x: size.width * 0.9, y: size.height * 0.15)
        addChild(att_base)
        
        att_stick.position = att_base.position
        addChild(att_stick)
        
        //selection initialization
        
        select_base.position = CGPoint(x: size.width * 0.9, y: size.height * 0.85)
        addChild(select_base)
        
        archerSelect.position = select_base.position
        bladeSelect.position = select_base.position
        addChild(archerSelect)
        
        
        att_base.alpha = 0.6
        att_stick.alpha = 0.6
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        //self.physicsBody?.isDynamic = true
        self.physicsBody!.categoryBitMask = PhysicsCategory.world
        self.physicsBody!.contactTestBitMask = PhysicsCategory.None
        self.physicsBody!.collisionBitMask = PhysicsCategory.hero
        
        hero.physicsBody = SKPhysicsBody(circleOfRadius: hero.size.height/2)
        //hero.physicsBody?.isDynamic = true
        hero.physicsBody!.categoryBitMask = PhysicsCategory.hero
        hero.physicsBody!.contactTestBitMask = PhysicsCategory.region_hero | PhysicsCategory.blade
        hero.physicsBody!.collisionBitMask = PhysicsCategory.world
                
    }
    
    override func update(_ currentTime: TimeInterval) {
        framecount += 1
        if(moveActive){
            let v = CGVector(dx: move_stick.position.x - move_base.position.x, dy: move_stick.position.y - move_base.position.y)
            let angle = atan2(v.dy, v.dx)
            let speed: CGFloat = 10
            
            let x_speed : CGFloat = sin(angle - 1.57079633) * speed
            let y_speed : CGFloat = cos(angle - 1.57079633) * speed
            hero.position.x -= x_speed
            hero.position.y += y_speed
            if(attActive){
                if(selectBladeNow){
                    hero.zRotation = blade.zRotation
                }
                else{
                    hero.zRotation = archer.zRotation
                }
            }else{
                hero.zRotation = angle-1.57079633
            }
        }
        
        if(attActive){

            let v = CGVector(dx: att_stick.position.x - att_base.position.x, dy: att_stick.position.y - att_base.position.y)
            let angle = atan2(v.dy, v.dx)
            let x_p : CGFloat = sin(angle - 1.57079633) * 20
            let y_p : CGFloat = cos(angle - 1.57079633) * 20
            if(selectBladeNow){
                blade.position.x = hero.position.x - x_p * 1.1
                blade.position.y = hero.position.y + y_p * 1.1
                blade.zRotation = angle - 1.57079633
                hero.zRotation = blade.zRotation
            }else{
                archer.position.x = hero.position.x - x_p
                archer.position.y = hero.position.y + y_p
                archer.zRotation = angle - 1.57079633
                hero.zRotation = archer.zRotation
            }
        }
        
        arrayArrow = arrayArrow.filter {$0.position.x < self.size.width && $0.position.x > 0 && $0.position.y > 0 && $0.position.y < self.size.height}
        //print(arrayArrow.count)
        if(framecount == 5){
            for i in 0..<arrayArrow.count{
                let region_hero = SKSpriteNode(imageNamed: "region")
                region_hero.position = arrayArrow[i].position
                addChild(region_hero)
                region_hero.physicsBody = SKPhysicsBody(circleOfRadius: region_hero.size.width/2)
                //region_hero.physicsBody?.isDynamic = true
                region_hero.physicsBody!.categoryBitMask = PhysicsCategory.region_hero
                region_hero.physicsBody!.contactTestBitMask = PhysicsCategory.blade | PhysicsCategory.hero
                region_hero.physicsBody!.collisionBitMask = PhysicsCategory.None
                region_hero.physicsBody?.usesPreciseCollisionDetection = true

            }
            framecount = 0
        }
    }
    
    func gameAI(){
        
    }
    
    func movementDetect(_ location: CGPoint){
        if(moveActive){
            let v = CGVector(dx: location.x - move_base.position.x, dy: location.y - move_base.position.y)
            let angle = atan2(v.dy, v.dx)
            
            let length : CGFloat = 40
            
            let xDist: CGFloat  = sin(angle - 1.57079633) * length
            let yDist: CGFloat  = cos(angle - 1.57079633) * length
            
            if(move_base.frame.contains(location)){
                move_stick.position = location
            }else{
                move_stick.position = CGPoint(x: move_base.position.x - xDist, y: move_base.position.y + yDist)
            }
        }
    }
    
    func attDetect(_ location: CGPoint){
        if(attActive){
            let v = CGVector(dx: location.x - att_base.position.x, dy: location.y - att_base.position.y)
            let angle = atan2(v.dy, v.dx)
            
            let length : CGFloat = 40
            let xDist: CGFloat  = sin(angle - 1.57079633) * length
            let yDist: CGFloat  = cos(angle - 1.57079633) * length
            
            if(att_base.frame.contains(location)){
                att_stick.position = location
            }else{
                att_stick.position = CGPoint(x: att_base.position.x - xDist, y: att_base.position.y + yDist)
            }
        }
    }
    
    /*func waveBlade(){
        print("here")
        let blade_rotate = SKSpriteNode(imageNamed: "blade")
        blade_rotate.position = blade.position
        blade_rotate.zRotation = blade.zRotation-0.7
        blade_rotate.anchorPoint = hero.position
        blade.removeFromParent()
        addChild(blade_rotate)
        let rotate = SKAction.rotate(toAngle: blade.zRotation + 1.5, duration: 2)
        blade_rotate.run(rotate)
    }*/
    
    func shootOut(){
        let arrow = SKSpriteNode(imageNamed: "archer")
        arrayArrow.append(arrow)
        
        arrow.position = hero.position
        addChild(arrow)
        let v = CGVector(dx: att_stick.position.x - att_base.position.x, dy: att_stick.position.y - att_base.position.y)
        let angle = atan2(v.dy, v.dx)
        arrow.zRotation = angle - 1.57079633
        let offset = att_stick.position - att_base.position
        let direction = offset.normalized()
        let dest = direction * 1000 + arrow.position
        let shootMove = SKAction.move(to: dest, duration: 1.0)
        let shootMoveDone = SKAction.removeFromParent()
        arrow.run(SKAction.sequence([shootMove, shootMoveDone]))
    }
    
    func bladeDidCollideWithRegion(blade: SKSpriteNode, region: SKSpriteNode){
        region.removeFromParent()
    }
    
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
        //print(contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask)
        print(firstBody.categoryBitMask, secondBody.categoryBitMask)
        if(firstBody.categoryBitMask == PhysicsCategory.blade && secondBody.categoryBitMask == PhysicsCategory.region_hero){
            if let blade = firstBody.node as? SKSpriteNode, let
                region = secondBody.node as? SKSpriteNode {
                bladeDidCollideWithRegion(blade: blade, region: region)
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let location = touch.location(in: self)
            if(!moveActive){
                if(move_base.frame.contains(location)){
                    moveActive = true
                    validMove = touch
                    movementDetect(location)
                }
            }
        
            if(att_base.frame.contains(location)){
                attActive = true
                validAtt = touch
                if(selectBladeNow){
                    blade.position = hero.position
                    addChild(blade)
                    blade.physicsBody = SKPhysicsBody(rectangleOf: blade.size)
                    //blade.physicsBody?.isDynamic = true
                    blade.physicsBody!.categoryBitMask = PhysicsCategory.blade
                    blade.physicsBody!.contactTestBitMask = PhysicsCategory.region_hero | PhysicsCategory.hero
                    blade.physicsBody!.collisionBitMask = PhysicsCategory.None
                }else{
                    archer.position = hero.position
                    addChild(archer)
                }

                attDetect(location)
            }
            
            if(select_base.frame.contains(location)){
                if(selectBladeNow){
                    bladeSelect.removeFromParent()
                    selectBladeNow = false
                    addChild(archerSelect)
                }else{
                    archerSelect.removeFromParent()
                    selectBladeNow = true
                    addChild(bladeSelect)
                }
            }
        }
    }
    
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            
            let location = touch.location(in: self)
            if(moveActive && touch == validMove){
                movementDetect(location)
            }
            if(attActive && touch == validAtt){
                attDetect(location)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        for touch in touches{
            if(moveActive && validMove == touch){
                    let stick_move:SKAction = SKAction.move(to: move_base.position, duration: 0.13)
                    stick_move.timingMode = .easeOut
                    move_stick.run(stick_move)
                    hero.removeAction(forKey: "dot_move")
                    if(attActive){
                        archer.removeAction(forKey: "archer_move")
                    }
                    moveActive = false
                }
        
            if(attActive && validAtt == touch){
                let stick_move:SKAction = SKAction.move(to: att_base.position, duration: 0.13)
                stick_move.timingMode = .easeOut
                att_stick.run(stick_move)
                if(selectBladeNow){
                    //waveBlade()
                    blade.removeFromParent()
                }else{
                    archer.removeFromParent()
                    shootOut()
                }
                attActive = false
            }
        }

    }
}

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

func randomInt(min: Int, max:Int) -> Int {
    return min + Int(arc4random_uniform(UInt32(max - min + 1)))
}

func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
}


func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
}

func randomNumber(probabilities: [Double]) -> Int {
    
    // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
    let sum = probabilities.reduce(0, +)
    // Random number in the range 0.0 <= rnd < sum :
    let rnd = sum * Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
    // Find the first interval of accumulated probabilities into which `rnd` falls:
    var accum = 0.0
    for (i, p) in probabilities.enumerated() {
        accum += p
        if rnd < accum {
            return i
        }
    }
    // This point might be reached due to floating point inaccuracies:
    return (probabilities.count - 1)
}

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
    static let enemy: UInt32 = 0b1 << 5         //6
    static let enemy_missle: UInt32 = 0b1 << 6   //7
}

enum action{
    case bladeAction, archerAction, runAction
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let label = SKLabelNode(fontNamed: "Chalkduster")
    let hero = SKSpriteNode(imageNamed: "ship_hero")
    //let enemy = SKSpriteNode(imageNamed: "ship_enemy")
    //let enemy_detect = SKSpriteNode(imageNamed: "enemy_detect")
    
    
    let move_base = SKSpriteNode(imageNamed: "base")
    let move_stick = SKSpriteNode(imageNamed: "stick")
    
    let att_base = SKSpriteNode(imageNamed: "base")
    let att_stick = SKSpriteNode(imageNamed: "stick")
    
    let select_base = SKSpriteNode(imageNamed: "select_base")
    let archerSelect = SKSpriteNode(imageNamed: "archer")
    let bladeSelect = SKSpriteNode(imageNamed: "blade")
    
    
    let archer = SKSpriteNode(imageNamed: "archer")
    let blade = SKSpriteNode(imageNamed: "blade")
    
    //let archer_enemy  = SKSpriteNode(imageNamed: "archer_enemy")

    
    var moveActive:Bool = false
    var attActive:Bool = false
    
    var selectBladeNow:Bool = false
    
    
    //var enemyArcherActive:Bool = false
    //var enemyBladeActive:Bool = false
    
    //var enemyArcherCount = 0
    //var enemyArcherRandom: Int?
    
    var validMove:UITouch?
    var validAtt:UITouch?
    
    var arrayArrow :[SKSpriteNode] = [SKSpriteNode]()
    
    var arrayRegion :[SKSpriteNode] = [SKSpriteNode]()
    
    var arrayEnemy :[SKSpriteNode] = [SKSpriteNode]()
    
    var arrayMissle :[SKSpriteNode] = [SKSpriteNode]()
    
    var framecount = 0
    var missleCount = 0
    var hitCount = 0
    
    
    //var actionList = Array(repeating: 0.333, count: 3)
    
    
    override func didMove(to view: SKView) {
        //background white
        //backgroundColor = SKColor.white
        
        let background = SKSpriteNode(imageNamed: "space_gamescene")
        background.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        background.zPosition = -1
        addChild(background)
        
        label.fontSize = 40
        label.fontColor = SKColor.blue
        label.position = CGPoint(x: size.width/2, y: size.height*0.9)
        label.zPosition = 1
        label.text = String(hitCount)
        addChild(label)
        
        //Initial position of hero
        hero.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        //enemy.position = CGPoint(x:size.width*0.9, y:size.height*0.5)
        //enemy_detect.position = enemy.position
        //enemy_detect.zPosition = -0.9
        
        //add to screen
        addChild(hero)
        //addChild(enemy)
        //addChild(enemy_detect)
        
        //gameAI()
        
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
        hero.physicsBody!.contactTestBitMask = PhysicsCategory.All
        hero.physicsBody!.collisionBitMask = PhysicsCategory.world
        
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addEnemy),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
        
        let backgroundMusic = SKAudioNode(fileNamed: "background_music.mp3")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
    }
    
    func addEnemy() {
        
        let enemy = SKSpriteNode(imageNamed: "ship_enemy")
        arrayEnemy.append(enemy)
        let actualY = random(min: enemy.size.height/2, max: size.height - enemy.size.height/2)
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: actualY)
        let v = CGVector(dx: enemy.position.x - hero.position.x, dy: enemy.position.y - hero.position.y)
        let angle = atan2(v.dy, v.dx)
        enemy.zRotation = angle + 1.57079633
        
        
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        //region_hero.physicsBody?.isDynamic = true
        enemy.physicsBody!.categoryBitMask = PhysicsCategory.enemy
        enemy.physicsBody!.contactTestBitMask = PhysicsCategory.All
        enemy.physicsBody!.collisionBitMask = PhysicsCategory.None
        
        addChild(enemy)
        let actualDuration = random(min: CGFloat(1.0), max: CGFloat(3.0))
        let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y: hero.position.y), duration: TimeInterval(actualDuration))
        //let actionMove = SKAction.moveBy(x: 10, y: actualY - hero.position.y ,duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func shootMissle(_ enemy: SKSpriteNode){
        let enemy_missle = SKSpriteNode(imageNamed: "enemy_missle")
        enemy_missle.position = enemy.position
        let v = CGVector(dx: enemy_missle.position.x - hero.position.x, dy: enemy_missle.position.y - hero.position.y)
        let angle = atan2(v.dy, v.dx)
        enemy_missle.zRotation = angle + 1.57079633
        
        enemy_missle.physicsBody!.categoryBitMask = PhysicsCategory.enemy
        enemy_missle.physicsBody!.contactTestBitMask = PhysicsCategory.All
        enemy_missle.physicsBody!.collisionBitMask = PhysicsCategory.None
        
        addChild(enemy_missle)
        let actualDuration = random(min: CGFloat(1.0), max: CGFloat(2.0))
        let actionMove = SKAction.move(to: CGPoint(x: hero.position.x , y: hero.position.y), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        enemy_missle.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    override func update(_ currentTime: TimeInterval) {
        framecount += 1
        missleCount += 1
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
        arrayEnemy = arrayEnemy.filter {$0.position.x > 0 && $0.position.y > 0 && $0.position.y < self.size.height}
        if(framecount == 5){
            for i in 0..<arrayArrow.count{
                let region_hero = SKSpriteNode(imageNamed: "region")
                region_hero.position = arrayArrow[i].position
                arrayRegion.append(region_hero)
                addChild(region_hero)
                region_hero.physicsBody = SKPhysicsBody(circleOfRadius: region_hero.size.width/2)
                //region_hero.physicsBody?.isDynamic = true
                region_hero.physicsBody!.categoryBitMask = PhysicsCategory.region_hero
                region_hero.physicsBody!.contactTestBitMask = PhysicsCategory.blade | PhysicsCategory.hero | PhysicsCategory.arrow | PhysicsCategory.enemy
                region_hero.physicsBody!.collisionBitMask = PhysicsCategory.None
                region_hero.physicsBody?.usesPreciseCollisionDetection = true

            }
            
            framecount = 0
        }
        print(arrayEnemy.count)
        if(missleCount == 40){
            for i in 0..<arrayEnemy.count{
                shootMissle(arrayEnemy[i])
            }
            missleCount = 0
        }
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
    
    
    func shootOut(){
        let arrow = SKSpriteNode(imageNamed: "archer")
        arrayArrow.append(arrow)
        
        arrow.physicsBody = SKPhysicsBody(rectangleOf: arrow.size)
        //region_hero.physicsBody?.isDynamic = true
        arrow.physicsBody!.categoryBitMask = PhysicsCategory.arrow
        arrow.physicsBody!.contactTestBitMask = PhysicsCategory.hero | PhysicsCategory.enemy | PhysicsCategory.region_hero
        arrow.physicsBody!.collisionBitMask = PhysicsCategory.None
        arrow.physicsBody?.usesPreciseCollisionDetection = true

        
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
    
    func arrowDidCollideWithEnemy(enemy: SKSpriteNode, arrow: SKSpriteNode){
        hitCount+=1
        label.text = String(hitCount)
        enemy.position = CGPoint(x: -10, y: -10)
        enemy.removeFromParent();
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
        //print(firstBody.categoryBitMask, secondBody.categoryBitMask)
        if(firstBody.categoryBitMask == PhysicsCategory.blade && secondBody.categoryBitMask == PhysicsCategory.region_hero){
            if let blade = firstBody.node as? SKSpriteNode, let
                region = secondBody.node as? SKSpriteNode {
                bladeDidCollideWithRegion(blade: blade, region: region)
            }
        }
        if(firstBody.categoryBitMask == PhysicsCategory.arrow && secondBody.categoryBitMask == PhysicsCategory.enemy){
            if let arrow = firstBody.node as? SKSpriteNode, let
                enemy = secondBody.node as? SKSpriteNode {
                arrowDidCollideWithEnemy(enemy: enemy, arrow: arrow)
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

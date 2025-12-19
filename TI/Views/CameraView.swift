import SwiftUI
import RealityKit
import ARKit
import Combine

struct CameraView: View {
    var body: some View {
        ZStack {
            ARViewContainer()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("Tap to open/close the treasure chest")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        // Create the treasure chest
        let chestAnchor = AnchorEntity(plane: .horizontal)
        
        let chest = createTreasureChest()
        chestAnchor.addChild(chest)
        
        // Add ambient particles
        let particles = createGoldParticles()
        particles.position.y = 0.15
        chestAnchor.addChild(particles)
        
        arView.scene.addAnchor(chestAnchor)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        context.coordinator.chest = chest
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var arView: ARView?
        var chest: Entity?
        var isOpen = false
        
        @objc func handleTap() {
            guard let chest = chest else { return }
            
            if let lid = chest.findEntity(named: "lid") {
                isOpen.toggle()
                
                let targetRotation: Float = isOpen ? -.pi / 3 : 0
                let duration: TimeInterval = 0.8
                
                var transform = lid.transform
                transform.rotation = simd_quatf(angle: targetRotation, axis: [1, 0, 0])
                
                lid.move(to: transform, relativeTo: lid.parent, duration: duration, timingFunction: .easeInOut)
                
                // Play sound effect (optional)
                if isOpen {
                    // Show gold shine
                    if let goldPile = chest.findEntity(named: "goldPile") {
                        goldPile.isEnabled = true
                    }
                } else {
                    if let goldPile = chest.findEntity(named: "goldPile") {
                        goldPile.isEnabled = false
                    }
                }
            }
        }
    }
}

func createTreasureChest() -> Entity {
    let chestEntity = Entity()
    chestEntity.name = "treasureChest"
    
    // Base of chest (bottom)
    let baseWidth: Float = 0.3
    let baseHeight: Float = 0.15
    let baseDepth: Float = 0.2
    
    // Bottom box
    let bottomMesh = MeshResource.generateBox(width: baseWidth, height: baseHeight, depth: baseDepth)
    var woodMaterial = SimpleMaterial()
    woodMaterial.color = .init(tint: UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0))
    woodMaterial.roughness = .init(floatLiteral: 0.9)
    woodMaterial.metallic = .init(floatLiteral: 0.1)
    
    let bottom = ModelEntity(mesh: bottomMesh, materials: [woodMaterial])
    bottom.position.y = baseHeight / 2
    
    // Add wood planks detail
    for i in 0..<5 {
        let plankMesh = MeshResource.generateBox(width: baseWidth + 0.002, height: 0.015, depth: 0.025)
        var plankMaterial = SimpleMaterial()
        let colorVariation = CGFloat.random(in: 0.35...0.45)
        plankMaterial.color = .init(tint: UIColor(red: colorVariation, green: colorVariation * 0.6, blue: 0.12, alpha: 1.0))
        plankMaterial.roughness = .init(floatLiteral: 0.95)
        
        let plank = ModelEntity(mesh: plankMesh, materials: [plankMaterial])
        plank.position = [0, Float(i) * 0.032 + 0.015, 0]
        bottom.addChild(plank)
    }
    
    // Metal bands around chest
    for i in 0..<3 {
        let bandMesh = MeshResource.generateBox(width: baseWidth + 0.01, height: 0.012, depth: baseDepth + 0.01)
        var metalMaterial = SimpleMaterial()
        metalMaterial.color = .init(tint: UIColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1.0))
        metalMaterial.metallic = .init(floatLiteral: 0.8)
        metalMaterial.roughness = .init(floatLiteral: 0.4)
        
        let band = ModelEntity(mesh: bandMesh, materials: [metalMaterial])
        band.position = [0, Float(i) * 0.06 + 0.02, 0]
        bottom.addChild(band)
    }
    
    // Corner metal brackets
    let bracketPositions: [[Float]] = [
        [-baseWidth/2 + 0.015, 0, -baseDepth/2 + 0.015],
        [baseWidth/2 - 0.015, 0, -baseDepth/2 + 0.015],
        [-baseWidth/2 + 0.015, 0, baseDepth/2 - 0.015],
        [baseWidth/2 - 0.015, 0, baseDepth/2 - 0.015]
    ]
    
    for pos in bracketPositions {
        let bracketMesh = MeshResource.generateBox(width: 0.02, height: baseHeight + 0.02, depth: 0.02)
        var bracketMaterial = SimpleMaterial()
        bracketMaterial.color = .init(tint: UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0))
        bracketMaterial.metallic = .init(floatLiteral: 0.9)
        bracketMaterial.roughness = .init(floatLiteral: 0.3)
        
        let bracket = ModelEntity(mesh: bracketMesh, materials: [bracketMaterial])
        bracket.position = [pos[0], pos[1] + baseHeight/2, pos[2]]
        bottom.addChild(bracket)
    }
    
    chestEntity.addChild(bottom)
    
    // Lid (curved top)
    let lid = Entity()
    lid.name = "lid"
    
    // Create curved lid with multiple segments
    let lidSegments = 8
    for i in 0..<lidSegments {
        let angle = Float(i) * (.pi / Float(lidSegments))
        let segmentHeight: Float = 0.018
        let radius: Float = baseDepth / 2
        
        let segmentMesh = MeshResource.generateBox(width: baseWidth, height: segmentHeight, depth: 0.028)
        var segmentMaterial = SimpleMaterial()
        let colorVar = CGFloat.random(in: 0.38...0.48)
        segmentMaterial.color = .init(tint: UIColor(red: colorVar, green: colorVar * 0.65, blue: 0.14, alpha: 1.0))
        segmentMaterial.roughness = .init(floatLiteral: 0.9)
        
        let segment = ModelEntity(mesh: segmentMesh, materials: [segmentMaterial])
        let yPos = sin(angle) * radius
        let zPos = -cos(angle) * radius
        segment.position = [0, yPos, zPos]
        segment.orientation = simd_quatf(angle: angle, axis: [1, 0, 0])
        
        lid.addChild(segment)
    }

    
    // Lid metal bands
    for i in 0..<3 {
        let bandMesh = MeshResource.generateBox(
            width: baseWidth + 0.01,
            height: 0.01,
            depth: 0.025
        )

        var metalMaterial = SimpleMaterial()
        metalMaterial.color = .init(
            tint: UIColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1.0)
        )
        metalMaterial.metallic = .init(floatLiteral: 0.8)
        metalMaterial.roughness = .init(floatLiteral: 0.4)

        let angle = Float(i + 2) * (.pi / 8)
        let radius: Float = baseDepth / 2
        let yPos = sin(angle) * radius
        let zPos = -cos(angle) * radius

        let band = ModelEntity(mesh: bandMesh, materials: [metalMaterial])
        band.position = [0, yPos, zPos]
        band.orientation = simd_quatf(angle: angle, axis: [1, 0, 0])

        lid.addChild(band)
    }

    
    // Lock mechanism
    let lockMesh = MeshResource.generateBox(width: 0.05, height: 0.04, depth: 0.03)
    var lockMaterial = SimpleMaterial()
    lockMaterial.color = .init(tint: UIColor(red: 0.7, green: 0.6, blue: 0.2, alpha: 1.0))
    lockMaterial.metallic = .init(floatLiteral: 0.95)
    lockMaterial.roughness = .init(floatLiteral: 0.2)
    
    let lock = ModelEntity(mesh: lockMesh, materials: [lockMaterial])
    lock.position = [0, 0.01, baseDepth/2 + 0.01]
    lid.addChild(lock)
    
    // Keyhole
    let keyholeMesh = MeshResource.generateBox(width: 0.008, height: 0.02, depth: 0.005)
    var keyholeMaterial = SimpleMaterial()
    keyholeMaterial.color = .init(tint: .black)
    
    let keyhole = ModelEntity(mesh: keyholeMesh, materials: [keyholeMaterial])
    keyhole.position = [0, 0.01, baseDepth/2 + 0.025]
    lid.addChild(keyhole)
    
    lid.position = [0, baseHeight, -baseDepth/2]
    chestEntity.addChild(lid)
    
    // Gold pile inside (initially hidden)
    let goldPile = createGoldPile()
    goldPile.name = "goldPile"
    goldPile.position.y = baseHeight
    goldPile.isEnabled = false
    chestEntity.addChild(goldPile)
    
    // Add directional light for better shadows
    let light = DirectionalLight()
    light.light.intensity = 1000
    light.light.color = .white
    light.shadow = DirectionalLightComponent.Shadow()
    light.position = [0, 1, 0]
    light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
    chestEntity.addChild(light)
    
    return chestEntity
}

func createGoldPile() -> Entity {
    let goldEntity = Entity()
    
    // Create pile of gold coins and treasures
    for i in 0..<25 {
        let coinMesh = MeshResource.generateBox(width: 0.03, height: 0.003, depth: 0.03, cornerRadius: 0.015)
        var goldMaterial = SimpleMaterial()
        let goldShade = CGFloat.random(in: 0.7...0.9)
        goldMaterial.color = .init(tint: UIColor(red: goldShade, green: goldShade * 0.8, blue: 0.1, alpha: 1.0))
        goldMaterial.metallic = .init(floatLiteral: 0.95)
        goldMaterial.roughness = .init(floatLiteral: 0.15)
        
        let coin = ModelEntity(mesh: coinMesh, materials: [goldMaterial])
        
        let randomX = Float.random(in: -0.08...0.08)
        let randomZ = Float.random(in: -0.05...0.05)
        let layer = Float(i / 8) * 0.01
        
        coin.position = [randomX, layer, randomZ]
        coin.orientation = simd_quatf(angle: Float.random(in: 0...0.5), axis: [1, 0, 0])
        
        goldEntity.addChild(coin)
    }
    
    // Add some gems
    for _ in 0..<8 {
        let gemMesh = MeshResource.generateBox(width: 0.015, height: 0.02, depth: 0.015)
        var gemMaterial = SimpleMaterial()
        let gemColors: [UIColor] = [
            UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0), // Ruby
            UIColor(red: 0.1, green: 0.3, blue: 1.0, alpha: 1.0), // Sapphire
            UIColor(red: 0.1, green: 0.9, blue: 0.3, alpha: 1.0)  // Emerald
        ]
        gemMaterial.color = .init(tint: gemColors.randomElement()!)
        gemMaterial.metallic = .init(floatLiteral: 0.1)
        gemMaterial.roughness = .init(floatLiteral: 0.1)
        
        let gem = ModelEntity(mesh: gemMesh, materials: [gemMaterial])
        gem.position = [Float.random(in: -0.07...0.07), Float.random(in: 0.02...0.04), Float.random(in: -0.04...0.04)]
        
        goldEntity.addChild(gem)
    }
    
    // Point light for gold glow
    let goldLight = PointLight()
    goldLight.light.intensity = 500
    goldLight.light.color = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
    goldLight.light.attenuationRadius = 0.5
    goldLight.position = [0, 0.1, 0]
    goldEntity.addChild(goldLight)
    
    return goldEntity
}

func createGoldParticles() -> Entity {
    let particleEntity = Entity()
    
    // Create sparkle particles
    for i in 0..<15 {
        let particleMesh = MeshResource.generateSphere(radius: 0.003)
        var particleMaterial = UnlitMaterial()
        particleMaterial.color = .init(tint: UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.8))
        
        let particle = ModelEntity(mesh: particleMesh, materials: [particleMaterial])
        
        let angle = Float(i) * (Float.pi * 2 / 15)
        let radius: Float = 0.2
        
        particle.position = [
            cos(angle) * radius,
            Float.random(in: 0...0.15),
            sin(angle) * radius
        ]
        
        particleEntity.addChild(particle)
    }
    
    return particleEntity
}

#Preview {
    CameraView()
}

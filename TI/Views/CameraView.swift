import SwiftUI
import RealityKit
import ARKit
import CoreLocation
import Combine

// MARK: - Camera View
struct CameraView: View {
    var body: some View {
        ZStack {
            ARViewContainer()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("Turn Northwest (↖️) to find the planets!\nVenus (10m), Jupiter (15m), Neptune (20m)\n308° from North")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
            }
        }
    }
}

// MARK: - ARView Container
struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.debugOptions = []
        
        context.coordinator.arView = arView
        
        // Request location permissions for compass
        context.coordinator.setupLocationManager()
        
        // Configure AR session with world tracking
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading // This aligns AR with compass heading!
        arView.session.run(config)
        
        print("🚀 AR View initialized with compass heading")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, CLLocationManagerDelegate {
        var arView: ARView?
        var cancellables = Set<AnyCancellable>()
        var venusEntity: ModelEntity?
        var jupiterEntity: ModelEntity?
        var neptuneEntity: ModelEntity?
        var rotationTimer: Timer?
        var locationManager: CLLocationManager?
        var planetsPlaced = false
        
        func setupLocationManager() {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
            locationManager?.startUpdatingHeading()
            print("📍 Location manager setup for compass")
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            // Once we have compass data and haven't placed planets yet
            if !planetsPlaced && newHeading.headingAccuracy >= 0 {
                print("🧭 Compass heading: \(newHeading.trueHeading)°")
                planetsPlaced = true
                addPlanetsToWest()
            }
        }
        
        func addPlanetsToWest() {
            guard let arView = arView else {
                print("❌ ARView is nil")
                return
            }
            
            print("🌍 Adding planets at 308° (Northwest)...")
            
            // 308 degrees from North
            // Convert to radians: 308° × π/180 = 5.376 radians
            let angle308 = Float(308.0) * Float.pi / 180.0
            
            // Planet distances (in meters) - matching real solar system order from Sun
            let venusDistance: Float = 10.0   // Venus is closer to Sun
            let jupiterDistance: Float = 15.0  // Jupiter is further
            let neptuneDistance: Float = 20.0  // Neptune is furthest
            
            // Create Venus at 10m
            let venusX = sin(angle308) * venusDistance
            let venusZ = -cos(angle308) * venusDistance
            let venusAnchor = AnchorEntity(world: [venusX, 0, venusZ])
            addLighting(to: venusAnchor)
            loadPlanetModel(into: venusAnchor, planetName: "venus", entityRef: \.venusEntity)
            arView.scene.addAnchor(venusAnchor)
            print("✅ Venus placed at 10m, 308° Northwest")
            
            // Create Jupiter at 15m
            let jupiterX = sin(angle308) * jupiterDistance
            let jupiterZ = -cos(angle308) * jupiterDistance
            let jupiterAnchor = AnchorEntity(world: [jupiterX, 0, jupiterZ])
            addLighting(to: jupiterAnchor)
            loadPlanetModel(into: jupiterAnchor, planetName: "jupiter", entityRef: \.jupiterEntity)
            arView.scene.addAnchor(jupiterAnchor)
            print("✅ Jupiter placed at 15m, 308° Northwest")
            
            // Create Neptune at 20m
            let neptuneX = sin(angle308) * neptuneDistance
            let neptuneZ = -cos(angle308) * neptuneDistance
            let neptuneAnchor = AnchorEntity(world: [neptuneX, 0, neptuneZ])
            addLighting(to: neptuneAnchor)
            loadPlanetModel(into: neptuneAnchor, planetName: "neptune", entityRef: \.neptuneEntity)
            arView.scene.addAnchor(neptuneAnchor)
            print("✅ Neptune placed at 20m, 308° Northwest")
        }
        
        func addLighting(to anchor: AnchorEntity) {
            let mainLight = DirectionalLight()
            mainLight.light.intensity = 5000
            mainLight.light.color = .white
            mainLight.position = [2, 2, 1]
            mainLight.look(at: [0, 0, 0], from: mainLight.position, relativeTo: anchor)
            anchor.addChild(mainLight)
            
            let fillLight = DirectionalLight()
            fillLight.light.intensity = 3000
            fillLight.light.color = .white
            fillLight.position = [-2, 1, -1]
            fillLight.look(at: [0, 0, 0], from: fillLight.position, relativeTo: anchor)
            anchor.addChild(fillLight)
            
            let pointLight = PointLight()
            pointLight.light.intensity = 10000
            pointLight.light.attenuationRadius = 5.0
            pointLight.light.color = .white
            pointLight.position = [0, 0, 1]
            anchor.addChild(pointLight)
            
            print("💡 Lighting added")
        }
        
        func loadPlanetModel(into anchor: AnchorEntity, planetName: String, entityRef: ReferenceWritableKeyPath<Coordinator, ModelEntity?>) {
            var planetURL: URL?
            
            // Try to find the planet model file
            if let url = Bundle.main.url(forResource: planetName, withExtension: "usdz", subdirectory: "Resources") {
                planetURL = url
                print("✅ Found \(planetName).usdz in Resources/")
            } else if let url = Bundle.main.url(forResource: planetName, withExtension: "usdz") {
                planetURL = url
                print("✅ Found \(planetName).usdz in root")
            } else if let url = Bundle.main.url(forResource: "Resources/\(planetName)", withExtension: "usdz") {
                planetURL = url
                print("✅ Found with Resources/ prefix")
            }
            
            guard let url = planetURL else {
                print("⚠️ Could not find \(planetName).usdz - creating fallback sphere")
                createFallbackPlanet(into: anchor, planetName: planetName, entityRef: entityRef)
                return
            }
            
            print("📂 Loading \(planetName) from: \(url.path)")
            
            if #available(iOS 18.0, *) {
                Task {
                    do {
                        let model = try await ModelEntity(contentsOf: url)
                        print("✅ \(planetName) loaded! Bounds: \(model.visualBounds(relativeTo: nil))")
                        
                        await MainActor.run {
                            self.setupPlanetModel(model, in: anchor, planetName: planetName, entityRef: entityRef)
                        }
                    } catch {
                        print("❌ Error loading \(planetName): \(error)")
                        self.createFallbackPlanet(into: anchor, planetName: planetName, entityRef: entityRef)
                    }
                }
            } else {
                Entity.loadModelAsync(contentsOf: url)
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Error loading \(planetName): \(error)")
                            self.createFallbackPlanet(into: anchor, planetName: planetName, entityRef: entityRef)
                        }
                    }, receiveValue: { model in
                        print("✅ \(planetName) loaded! Bounds: \(model.visualBounds(relativeTo: nil))")
                        self.setupPlanetModel(model, in: anchor, planetName: planetName, entityRef: entityRef)
                    })
                    .store(in: &self.cancellables)
            }
        }
        
        func setupPlanetModel(_ model: Entity, in anchor: AnchorEntity, planetName: String, entityRef: ReferenceWritableKeyPath<Coordinator, ModelEntity?>) {
            print("🔍 \(planetName) Model Structure:")
            self.printHierarchy(model, level: 0)
            
            print("🔄 Creating sphere for \(planetName)...")
            
            let planetSphere = ModelEntity(
                mesh: .generateSphere(radius: 0.5),
                materials: []
            )
            
            // Try to extract and use the original material
            if let modelEntity = model as? ModelEntity,
               let originalMaterials = modelEntity.model?.materials,
               !originalMaterials.isEmpty {
                print("📋 Copying \(originalMaterials.count) materials from \(planetName)")
                planetSphere.model?.materials = originalMaterials
            } else {
                print("⚠️ No materials found for \(planetName), using fallback color")
                let fallbackColor = getFallbackColor(for: planetName)
                var fallbackMaterial = SimpleMaterial()
                fallbackMaterial.color = .init(tint: fallbackColor)
                fallbackMaterial.roughness = .init(floatLiteral: 0.7)
                planetSphere.model?.materials = [fallbackMaterial]
            }
            
            planetSphere.position = [0, 0, 0]
            planetSphere.scale = [0.42, 0.42, 0.42]
            
            anchor.addChild(planetSphere)
            print("✅ \(planetName) sphere added!")
            
            self[keyPath: entityRef] = planetSphere
            self.startRotation(for: planetSphere)
        }
        
        func createFallbackPlanet(into anchor: AnchorEntity, planetName: String, entityRef: ReferenceWritableKeyPath<Coordinator, ModelEntity?>) {
            print("🔄 Creating fallback sphere for \(planetName)...")
            
            let planetSphere = ModelEntity(
                mesh: .generateSphere(radius: 0.5),
                materials: []
            )
            
            let fallbackColor = getFallbackColor(for: planetName)
            var fallbackMaterial = SimpleMaterial()
            fallbackMaterial.color = .init(tint: fallbackColor)
            fallbackMaterial.roughness = .init(floatLiteral: 0.7)
            planetSphere.model?.materials = [fallbackMaterial]
            
            planetSphere.position = [0, 0, 0]
            planetSphere.scale = [0.42, 0.42, 0.42]
            
            anchor.addChild(planetSphere)
            print("✅ Fallback \(planetName) sphere added!")
            
            self[keyPath: entityRef] = planetSphere
            self.startRotation(for: planetSphere)
        }
        
        func getFallbackColor(for planetName: String) -> UIColor {
            switch planetName.lowercased() {
            case "venus":
                return .orange
            case "jupiter":
                return UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0) // Tan/beige
            case "neptune":
                return UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0) // Blue
            default:
                return .gray
            }
        }
        
        func startRotation(for planet: ModelEntity) {
            print("🔄 Starting rotation for planet...")
            var angle: Float = 0
            
            Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self, weak planet] _ in
                guard self != nil, let planet = planet else { return }
                
                angle += 0.01
                planet.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            }
            
            print("✅ Rotation started")
        }
        
        func printHierarchy(_ entity: Entity, level: Int) {
            let indent = String(repeating: "  ", count: level)
            print("\(indent)↳ \(type(of: entity)) '\(entity.name)' - \(entity.children.count) children")
            
            if let modelEntity = entity as? ModelEntity {
                print("\(indent)  📦 Mesh: \(modelEntity.model?.mesh != nil)")
                print("\(indent)  🎨 Materials: \(modelEntity.model?.materials.count ?? 0)")
            }
            
            for child in entity.children {
                printHierarchy(child, level: level + 1)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CameraView()
}

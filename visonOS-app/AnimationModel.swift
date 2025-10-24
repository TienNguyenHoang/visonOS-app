import Foundation

struct BuilderProject: Codable {
    let version: Int
    let world: World
    let instruction: Instruction
}

struct World: Codable {
    let version: Int
    let nodes: [Node]
}

struct Node: Codable {
    let name: String
    let type: Int
    let parentIndex: Int
    let materialIndices: [Int]?
    let geometryIndex: Int
    let position: [Float]
    let scale: [Float]
    let quaternion: [Float]
}

struct Instruction: Codable {
    let version: Int
    let steps: [InstructionStep2]
}

struct InstructionStep2: Codable {
    let descriptionText: DescriptionText
    let descriptionSpeech: DescriptionSpeech?
    let keyframes: [Keyframe]
}

struct DescriptionText: Codable {
    let text: [String: String]
}

struct DescriptionSpeech: Codable {
    let mediaUrls: [String: String]?
    let mediaNames: [String: String]?
}

struct Keyframe: Codable {
    let cameraPos: [Float]
    let cameraTarget: [Float]
    let nodes: [FrameNode]
}

struct FrameNode: Codable {
    let nodeIndex: Int
    let position: [Float]
    let scale: [Float]
    let quaternion: [Float]
    let visible: Bool
}

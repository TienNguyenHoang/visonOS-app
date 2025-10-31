
import Foundation

struct AnimationModel: Codable {
    let version: Int
    let steps: [AnimInstructionStep]
    let nodes: [Node]
    let env: Env
}

struct Env: Codable {
    let version: Int
    let zenithColor: [Int]
    let nadirColor: [Double]
    let useGradientBg: Bool
    let rotationDeg, envIntensity, bgIntensity: Int
    let bgBlur: Double
    let toneMappingExposure, toneMap: Int
    let envMapURL: String

    enum CodingKeys: String, CodingKey {
        case version, zenithColor, nadirColor, useGradientBg, rotationDeg, envIntensity, bgIntensity, bgBlur, toneMappingExposure, toneMap
        case envMapURL = "envMapUrl"
    }
}

struct Node: Codable {
    let name: String
    let steps: [NodeStep]
    let children: [Node]
}

struct NodeStep: Codable {
    let keyframes: [PurpleKeyframe]
}

struct PurpleKeyframe: Codable {
    let position: CameraPos
    let quaternion: [Double]
    let scale: CameraPos
    let visible: Bool
}

struct CameraPos: Codable {
    let x, y, z: Double
}

struct AnimInstructionStep: Codable {
    let keyframes: [FluffyKeyframe]
    let descriptionText: DescriptionText
    let descriptionSpeech: DescriptionSpeech
}

struct DescriptionSpeech: Codable {
    let mediaUrls, mediaNames: MediaNames
}

struct MediaNames: Codable {
    let en, fr: String
}

struct DescriptionText: Codable {
    let text: MediaNames
}

struct FluffyKeyframe: Codable {
    let cameraPos, cameraTarget: CameraPos
}

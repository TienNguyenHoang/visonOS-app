import Foundation

struct ProjectDetailResponse: Codable {
    let id: String?
    let sent: String?
    let sender: String?
    let data: ProjectDetailData?
    let jwt: JWTInfoP?
    let scope: String?
    let senderIp: String?
    let ack: Bool?
    let received: String?
    let status: Int?
}

struct ProjectDetailData: Codable {
    let count: Int?
    let items: [InstructionDetail]?
}

struct InstructionDetail: Codable, Identifiable {
    let id: String
    let scope: String?
    let client: Int?
    let user: Int?
    let createdBy: Int?
    let updatedBy: Int?
    let version: Int?
    let target: String?
    let status: String?
    let media: MediaInfo?
    let title: [String: String]?
    let locales: [String]?
    let tags: [String]?
    let notes: String?
    let participants: Int?
    let duration: Double?
    let sections: [InstructionSection]?
    let createdAt: String?
    let updatedAt: String?
    let properties: InstructionProperties?
    let qr: String?
    let v: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case scope, client, user, createdBy, updatedBy
        case version = "version"
        case target, status, media, title, locales, tags, notes
        case participants, duration, sections, createdAt, updatedAt, properties, qr
        case v = "__v"
    }
}

struct MediaInfo: Codable {
    let gltfUrl: String?
    let thumbnail: String?
}

struct InstructionSection: Codable {
    let requirements: [String]?
    let steps: [InstructionStep]?
}

struct InstructionStep: Codable, Identifiable {
    let id: Int
    let duration: Double?
    let create: Bool?
    let tips: [String]?
    let camera: CameraInfo?
    let media: String?
    let state: [String: String]?
    let stateRef: String?
    let index: String?
    let stacks: [String: String]? // ✅ thêm để match JSON
    let text: [String: String]?   // ✅ thêm để match JSON
}

struct CameraInfo: Codable {
    let vector: Position3D?
    let target: Position3D?
}

struct Position3D: Codable {
    let x: Double?
    let y: Double?
    let z: Double?
}

struct InstructionProperties: Codable {
    let skipStep: Bool?
    let removeLogo: Bool?
    let advancedViewer: Bool?
    let contentInstruction: ContentInstruction?
    let linkAssembler: String?
}

struct ContentInstruction: Codable {
    let dimensionList: [String]?
    let alertCalloutList: [AlertCallout]?
    let checkTTS: [CheckTTS]?
}

struct AlertCallout: Codable {
    let id: Int?
    let type: String?
    let description: [String: String]?
    let callout: [CalloutPosition]?
}

struct CalloutPosition: Codable {
    let positionX: String?
    let positionY: String?
    let step: Int?
}

struct CheckTTS: Codable {
    let id: Int?
    let tts: [String: String]?
    let step: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case tts = "Tts"
        case step
    }
}

struct JWTInfoP: Codable {
    let scope: String?
    let client: Int?
    let id: Int?
    let sid: String?
    let iat: Int?
    let exp: Int?
    let email: String?
    let locale: String?
    let permissions: [String]?
    let features: [String: Bool]?
}

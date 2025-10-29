import Foundation

struct ProjectResponse: Codable {
    let id: String?
    let sent: String?
    let sender: String?
    let data: ProjectData?
    let jwt: JWTInfo?
    let scope: String?
    let senderIp: String?
    let ack: Bool?
    let received: String?
    let status: Int?
}

struct ProjectData: Codable {
    let count: Int?
    let items: [Project]?
}

struct Project: Codable, Identifiable {
    let id: String
    let createdAt: String?
    let updatedAt: String?
    let createdBy: Int?
    let updatedBy: Int?
    let user: Int?
    let client: Int?
    let scope: String?
    let upc: String?
    let name: String?
    let properties: ProjectProperties?
    let version: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case createdAt, updatedAt, createdBy, updatedBy, user, client, scope, upc, name, properties
        case version = "__v"
    }
}

struct ProjectProperties: Codable {
    let title: [String: String]?
    let notes: String?
    let channel: String?
    let status: String?
    let tags: [String]?
    let type: String?
    let media: String?
    let plan: String?
    let removeLogo: Bool?
    let radius: Bool?
    let docs: [ProjectDoc]?
    let qr: String?
    let activeDisplay: String?
    let activeDocument: String?
    let sharingQrImageUrl: String?
    let linkProject: [LinkInstruction]?
    let infoInstructions: [InfoInstruction]?
    let groupChoices: [GroupChoice]?
}

struct ProjectDoc: Codable {
    let id: String?
    let name: String?
    let version: String?
    let title: [String: String]?
    let createdAt: String?
    let author: Author?
    let media: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, version, title, createdAt, author, media
    }
}

struct Author: Codable {
    let firstname: String?
    let lastname: String?
}

struct LinkInstruction: Codable {
    let id: String?
    let linkInstruction: Int?
    let groupNameInstruction: String?
    let variantId: String?
}
struct InfoInstruction: Codable {
    let id: Int?
    let thumbnail: String?
}

struct GroupChoice: Codable {
    let title: [String: String]?
    let variants: [Variant]?
}

struct Variant: Codable {
    let id: String?
    let choice: VariantChoice?
    let imageVariant: String?
    let title: [String: String]?
}

struct VariantChoice: Codable {
    let color: String?
    let image: String?
    let optional: String?
}

struct JWTInfo: Codable {
    let scope: String?
    let client: Int?
    let id: Int?
    let sid: String?
    let iat: Int?
    let exp: Int?
    let email: String?
    let locale: String?
    let permissions: [String]?
    let features: [String: Int]?
}

extension Project {
    var firstImageURL: String? {
        properties?.media ??
        properties?
            .groupChoices?
            .first?
            .variants?
            .first?
            .choice?.image
    }

    var localizedTitle: String {
        name ?? properties?.title?["en"] ?? "Untitled Project"
    }
}

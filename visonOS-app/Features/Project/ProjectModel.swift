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
    let user: Int?
    let client: Int?
    let scope: String?
    let upc: String?
    let name: String?
    let properties: ProjectProperties?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case createdAt, updatedAt, user, client, scope, upc, name, properties
    }
}

struct ProjectProperties: Codable {
    let title: [String: String]?
    let notes: String?
    let docs: [String]?
    let linkProject: [LinkInstruction]?
    let type: String?
    let media: String?
    let plan: String?
    let removeLogo: Bool?
    let radius: Bool?
    let groupChoices: [GroupChoice]?
}

struct LinkInstruction: Codable {
    let id: String?
    let linkInstruction: Int?
    let groupNameInstruction: String?
    let variantId: String?
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
        properties?
            .groupChoices?
            .first?
            .variants?
            .first?
            .choice?.image
    }
}

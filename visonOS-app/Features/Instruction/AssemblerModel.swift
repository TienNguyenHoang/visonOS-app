struct AssemblerReadResponse: Codable {
    let id: String
    let sent: String
    let sender: String
    let data: AssemblerModel?
    let scope: String
    let senderIp: String?
    let ack: Bool?
    let received: String?
    let status: Int?
}

struct AssemblerModel: Codable, Identifiable {
    let id: String
    let scope: String?
    let client: Int?
    let user: Int?
    let createdAt: String?
    let createdBy: Int?
    let updatedAt: String?
    let updatedBy: Int?
    let tags: [String]?
    let participants: Int?
    let duration: Int?
    let sections: [InstructionSection]?
    let stepCount: Int?
    let animationData: String?
    let status: String?
    let media: MediaInfo?
    let description: String?
    let properties: AssemblerProperties?
    let v: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case scope, client, user, createdAt, createdBy, updatedAt, updatedBy
        case tags, participants, duration, sections, stepCount, animationData
        case status, media, description, properties
        case v = "__v"
    }
}

struct AssemblerProperties: Codable {
    let v1SaveBackupUrl: String?
}

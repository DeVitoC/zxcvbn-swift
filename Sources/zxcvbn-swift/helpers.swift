import Foundation

struct Helpers {
    static let shared = Helpers()
    func loadAdjacencyGraphs() -> [String: [String: [String?]]] {
        guard let path = Bundle.module.url(forResource: "adjacency-graphs", withExtension: "json"),
              let data = try? Data(contentsOf: path) else {
            return [:]
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as! [String: [String: [String?]]]
            return json
        } catch {
            print("Error parsing adjacency graphs: \(error)")
            return [:]
        }
    }
}

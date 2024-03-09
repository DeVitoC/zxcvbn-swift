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

    func loadFrequencyLists() -> [String: [String]] {
        guard let path = Bundle.module.url(forResource: "frequency-lists", withExtension: "json"),
              let data = try? Data(contentsOf: path) else {
            return [:]
        }

        do {
            guard let json: [String: [String]] = try JSONSerialization.jsonObject(with: data) as? [String: [String]] else {
                return [:]
            }
            return json
        } catch {
            print("Error parsing frequency lists: \(error)")
            return [:]
        }
    }

    func buildRankedDict(_ orderedList: [String]) -> [String: Int] {
        var result: [String: Int] = [:]
        for (i, word) in orderedList.enumerated() {
            result[word] = i + 1
        }
        return result
    }
}

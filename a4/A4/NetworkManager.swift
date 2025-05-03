import Foundation
import Alamofire

struct Exercise: Codable, Identifiable {
    var id: String
    
    let bodyPart: String
    let equipment: String
    let gifUrl: String
    let name: String
    let target: String
    let secondaryMuscles: [String]
    let instructions: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case bodyPart, equipment, gifUrl, name, target, secondaryMuscles, instructions
    }
    
    init(
        id: String,
        bodyPart: String,
        equipment: String,
        gifUrl: String,
        name: String,
        target: String,
        secondaryMuscles: [String],
        instructions: [String]
    ) {
        self.id = id
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.gifUrl = gifUrl
        self.name = name
        self.target = target
        self.secondaryMuscles = secondaryMuscles
        self.instructions = instructions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bodyPart = try container.decodeIfPresent(String.self, forKey: .bodyPart) ?? ""
        equipment = try container.decodeIfPresent(String.self, forKey: .equipment) ?? ""
        gifUrl = try container.decodeIfPresent(String.self, forKey: .gifUrl) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        target = try container.decodeIfPresent(String.self, forKey: .target) ?? ""
        
        // Improved ID handling - prioritize numeric IDs
        if let idFromAPI = try? container.decode(String.self, forKey: .id) {
            // Extract digits if present
            let digits = idFromAPI.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            
            // Use digits if available, otherwise use the original ID
            id = !digits.isEmpty ? digits : idFromAPI
        } else {
            // Fallback to using name-based ID if no ID from API
            id = name.replacingOccurrences(of: " ", with: "_").lowercased()
        }
        
        // Handle secondaryMuscles that might be a JSON string or array
        if let musclesArray = try? container.decode([String].self, forKey: .secondaryMuscles) {
            secondaryMuscles = musclesArray
        } else if let musclesString = try? container.decode(String.self, forKey: .secondaryMuscles),
                  let data = musclesString.data(using: .utf8),
                  let musclesFromString = try? JSONDecoder().decode([String].self, from: data) {
            secondaryMuscles = musclesFromString
        } else {
            secondaryMuscles = []
        }
        
        // Handle instructions that might be a JSON string or array
        if let instructionsArray = try? container.decode([String].self, forKey: .instructions) {
            instructions = instructionsArray
        } else if let instructionsString = try? container.decode(String.self, forKey: .instructions),
                  let data = instructionsString.data(using: .utf8),
                  let instructionsFromString = try? JSONDecoder().decode([String].self, from: data) {
            instructions = instructionsFromString
        } else {
            instructions = []
        }
    }
}

class ExerciseService {
    static let shared = ExerciseService()
    private let baseURL = "http://34.59.215.239/api/exercises/"
    
    func fetchAllExercises(completion: @escaping (Result<[Exercise], Error>) -> Void) {
        AF.request(baseURL, method: .get)
            .validate()
            .responseDecodable(of: [Exercise].self) { response in
                switch response.result {
                case .success(let exercises):
                    // Print first few IDs for debugging
                    if !exercises.isEmpty {
                        let sampleIds = exercises.prefix(5).map { $0.id }
                        print("Sample exercise IDs: \(sampleIds)")
                    }
                    completion(.success(exercises))
                case .failure(let error):
                    print("Error fetching exercises: \(error)")
                    completion(.failure(error))
                }
            }
    }
    
    // Optional: Add a method to fetch a single exercise by ID
    func fetchExercise(byId id: String, completion: @escaping (Result<Exercise, Error>) -> Void) {
        let url = baseURL + id
        
        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: Exercise.self) { response in
                switch response.result {
                case .success(let exercise):
                    completion(.success(exercise))
                case .failure(let error):
                    print("Error fetching exercise: \(error)")
                    completion(.failure(error))
                }
            }
    }
    
    // For handling potential API issues or custom error responses
    func handleAPIError(_ data: Data?) -> Error {
        if let data = data,
           let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
            return NSError(domain: "ExerciseAPIError",
                           code: apiError.code ?? 0,
                           userInfo: [NSLocalizedDescriptionKey: apiError.message ?? "Unknown error"])
        }
        return NSError(domain: "ExerciseAPIError",
                       code: 0,
                       userInfo: [NSLocalizedDescriptionKey: "Unknown API error"])
    }
}

// Simple error model for API error responses
struct APIError: Codable {
    let message: String?
    let code: Int?
}

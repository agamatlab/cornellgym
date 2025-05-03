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
        
        if let idFromAPI = try? container.decode(String.self, forKey: .id) {
            id = idFromAPI
        } else {
            id = name.replacingOccurrences(of: " ", with: "_").lowercased()
        }
        
        if let musclesArray = try? container.decode([String].self, forKey: .secondaryMuscles) {
            secondaryMuscles = musclesArray
        } else if let musclesString = try? container.decode(String.self, forKey: .secondaryMuscles),
                  let data = musclesString.data(using: .utf8),
                  let musclesFromString = try? JSONDecoder().decode([String].self, from: data) {
            secondaryMuscles = musclesFromString
        } else {
            secondaryMuscles = []
        }
        
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
    
    public var exerciseIndexMap: [String: Int] = [:]
    public var nextIndex = 1
    
    private let exerciseIndexMapKey = "exerciseIndexMap"
    private let nextIndexKey = "exerciseNextIndex"
    
    init() {
        loadMappings()
    }
    
    func getSequentialId(for originalId: String) -> Int {
        if let existingIndex = exerciseIndexMap[originalId] {
            return existingIndex
        } else {
            let index = nextIndex
            exerciseIndexMap[originalId] = index
            nextIndex += 1
            saveMappings()
            return index
        }
    }
    
    private func saveMappings() {
        UserDefaults.standard.set(exerciseIndexMap, forKey: exerciseIndexMapKey)
        UserDefaults.standard.set(nextIndex, forKey: nextIndexKey)
    }
    
    private func loadMappings() {
        if let savedMap = UserDefaults.standard.dictionary(forKey: exerciseIndexMapKey) as? [String: Int] {
            exerciseIndexMap = savedMap
        }
        
        nextIndex = UserDefaults.standard.integer(forKey: nextIndexKey)
        if nextIndex == 0 {
            nextIndex = 1
        }
        
        print("Loaded \(exerciseIndexMap.count) exercise ID mappings with next index \(nextIndex)")
    }
    
    func fetchAllExercises(completion: @escaping (Result<[Exercise], Error>) -> Void) {
        AF.request(baseURL, method: .get)
            .validate()
            .responseDecodable(of: [Exercise].self) { response in
                switch response.result {
                case .success(let exercises):
                    for exercise in exercises {
                        if self.exerciseIndexMap[exercise.id] == nil {
                            self.exerciseIndexMap[exercise.id] = self.nextIndex
                            self.nextIndex += 1
                        }
                    }
                    
                    self.saveMappings()
                    
                    if !exercises.isEmpty {
                        let sampleIds = exercises.prefix(5).map { $0.id }
                        print("Sample original exercise IDs: \(sampleIds)")
                        
                        for id in sampleIds {
                            print("Exercise ID \(id) maps to sequential ID \(self.exerciseIndexMap[id] ?? -1)")
                        }
                    }
                    
                    completion(.success(exercises))
                case .failure(let error):
                    print("Error fetching exercises: \(error)")
                    completion(.failure(error))
                }
            }
    }
    
    func fetchExercise(byId id: String, completion: @escaping (Result<Exercise, Error>) -> Void) {
        let url = baseURL + id
        
        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: Exercise.self) { response in
                switch response.result {
                case .success(let exercise):
                    if self.exerciseIndexMap[exercise.id] == nil {
                        self.exerciseIndexMap[exercise.id] = self.nextIndex
                        self.nextIndex += 1
                        self.saveMappings()
                    }
                    completion(.success(exercise))
                case .failure(let error):
                    print("Error fetching exercise: \(error)")
                    completion(.failure(error))
                }
            }
    }
    
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

struct APIError: Codable {
    let message: String?
    let code: Int?
}

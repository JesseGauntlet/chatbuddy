import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String)
    case unauthorized
    case noData
    
    var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error \(statusCode): \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .noData:
            return "No data received"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        // Increase timeout to 60 seconds
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 60.0
        session = URLSession(configuration: config)
    }
    
    // MARK: - API Endpoints
    private func endpoint(_ path: String) -> String {
        return "\(Configuration.developmentAPIBaseURL())\(path)"
    }
    
    // MARK: - Generic Request Method
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil, headers: [String: String]? = nil) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication if available
        if let token = Configuration.jwtToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body if available
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    throw APIError.decodingFailed(error)
                }
            case 401:
                throw APIError.unauthorized
            default:
                // Try to parse error message
                let errorMessage: String
                do {
                    let errorResponse = try JSONDecoder().decode([String: String].self, from: data)
                    errorMessage = errorResponse["detail"] ?? "Unknown error"
                } catch {
                    errorMessage = "Unknown error"
                }
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    // MARK: - Health Check
    func checkServerHealth() async throws -> Bool {
        struct HealthResponse: Decodable {
            let status: String
            let version: String
        }
        
        do {
            let response: HealthResponse = try await request(endpoint: Configuration.developmentHealthCheckURL())
            return response.status == "ok"
        } catch {
            throw error
        }
    }
}

// MARK: - Convenience extensions for common HTTP methods
extension APIService {
    func get<T: Decodable>(path: String, headers: [String: String]? = nil) async throws -> T {
        return try await request(endpoint: endpoint(path), method: "GET", headers: headers)
    }
    
    func post<T: Decodable, E: Encodable>(path: String, body: E, headers: [String: String]? = nil) async throws -> T {
        let bodyData = try JSONEncoder().encode(body)
        return try await request(endpoint: endpoint(path), method: "POST", body: bodyData, headers: headers)
    }
    
    func put<T: Decodable, E: Encodable>(path: String, body: E, headers: [String: String]? = nil) async throws -> T {
        let bodyData = try JSONEncoder().encode(body)
        return try await request(endpoint: endpoint(path), method: "PUT", body: bodyData, headers: headers)
    }
    
    func delete<T: Decodable>(path: String, headers: [String: String]? = nil) async throws -> T {
        return try await request(endpoint: endpoint(path), method: "DELETE", headers: headers)
    }
} 
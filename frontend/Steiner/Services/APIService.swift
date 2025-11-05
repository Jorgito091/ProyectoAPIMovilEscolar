import Foundation
import UIKit

final class APIService {
    private let baseURL: URL
    private let token: String?

    init(baseURL: URL = URL(string: "http://localhost:8000")!, token: String? = nil) {
        self.baseURL = baseURL
        self.token = token
    }

    private func makeRequest(url: URL, method: String = "GET", contentType: String? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let ct = contentType { req.setValue(ct, forHTTPHeaderField: "Content-Type") }
        if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 60
        return req
    }

    func fetch<T: Decodable>(_ path: String, as type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        let url: URL
        if let u = URL(string: path), u.host != nil { url = u } else { url = baseURL.appendingPathComponent(path) }
        var req = makeRequest(url: url)
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { return completion(.failure(err)) }
            guard let data = data else { return completion(.failure(NSError(domain: "APIService", code: -1))) }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - POST helpers that don't try to decode into a specific type
    // Use these when the server returns 201/200 without a reliable JSON body or when you only need status.

    func postJSONNoDecode(_ path: String, jsonData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        let url: URL
        if let u = URL(string: path), u.host != nil { url = u } else { url = baseURL.appendingPathComponent(path) }
        var req = makeRequest(url: url, method: "POST", contentType: "application/json")
        req.httpBody = jsonData

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { return completion(.failure(err)) }
            guard let http = resp as? HTTPURLResponse else {
                return completion(.failure(NSError(domain: "APIService", code: -1)))
            }
            if (200..<300).contains(http.statusCode) {
                completion(.success(()))
            } else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                let e = NSError(domain: "APIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: body])
                completion(.failure(e))
            }
        }.resume()
    }

    func postMultipartNoDecode(_ path: String, fields: [String: String], fileFieldName: String, filename: String, fileData: Data, mimeType: String = "application/pdf", completion: @escaping (Result<Void, Error>) -> Void) {
        let url: URL
        if let u = URL(string: path), u.host != nil { url = u } else { url = baseURL.appendingPathComponent(path) }
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        for (k, v) in fields { appendField(name: k, value: v) }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var req = makeRequest(url: url, method: "POST", contentType: "multipart/form-data; boundary=\(boundary)")
        req.httpBody = body

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { return completion(.failure(err)) }
            guard let http = resp as? HTTPURLResponse else {
                return completion(.failure(NSError(domain: "APIService", code: -1)))
            }
            if (200..<300).contains(http.statusCode) {
                completion(.success(()))
            } else {
                let bodyStr = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                let e = NSError(domain: "APIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: bodyStr])
                completion(.failure(e))
            }
        }.resume()
    }
}

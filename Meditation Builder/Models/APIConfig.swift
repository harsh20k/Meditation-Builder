//
//  APIConfig.swift
//  Meditation Builder
//

import Foundation

/// Community API base URL. Set from `terraform output -raw api_base_url` for staging.
enum APIConfig {
    static let baseURL = URL(string: "https://lcn0e7kne5.execute-api.us-east-1.amazonaws.com/v1/v1")!

    /// CloudFront staging alternative: `https://dhdnv4iakcz7z.cloudfront.net/v1`
    /// Production (when DNS exists): `https://api.meditationbuilder.app/v1`
}

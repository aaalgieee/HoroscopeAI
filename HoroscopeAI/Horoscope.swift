//
//  Horoscope.swift
//  HoroscopeAI
//
//  Created by Al Gabriel on 5/3/24.
//

import Foundation


struct Horoscope: Codable {
    let date: String
    let horoscope_data: String
}

struct HoroscopeResponse: Decodable {
    let data: Horoscope
    let status: Int
    let success : Bool
}

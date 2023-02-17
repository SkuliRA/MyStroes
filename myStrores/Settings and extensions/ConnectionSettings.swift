//
//  connectionSettings.swift
//  myStrores
//
//  Created by Skuli on 10.02.2023.
//

import Foundation

// Сюда записываем базы которые у нас подключены к выгрузке
enum BaseCode: String, CaseIterable {
    case flagman = "FL"
    case festival = "FV"
}

enum StoreName: String {
    case flagman = "Магазин Fronzoli Флагман "
    case festival = "Магазин Fronzoli Фестиваль"
}

enum TransferMode {
    case download
    case upload
}

class ConnectionSettings {
    
    static let shared = ConnectionSettings()
    
    let token = "y0_AgAAAAAQPx9CAAke9wAAAADb4_qdJYZmFWUgQYuKW6xROCLAhf_wvDI"
    let path = "/IOS"
    let nameFile = "From1C.json"
    let nameFileResponse = "FromApp.json"
    let urlForDownload = "https://cloud-api.yandex.net" + "/v1/disk/resources/download?path="
    let urlForUpload = "https://cloud-api.yandex.net" + "/v1/disk/resources/upload?path="
    let overwriteOption = "&overwrite=true"
    let headers = ["Authorization": "OAuth y0_AgAAAAAQPx9CAAke9wAAAADb4_qdJYZmFWUgQYuKW6xROCLAhf_wvDI",
                   "Content-Type": "application/x-www-form-urlencoded"]
}

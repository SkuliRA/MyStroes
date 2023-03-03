//
//  NetworkManager.swift
//  myStrores
//
//  Created by Skuli on 17.02.2023.
//

import Foundation
import RealmSwift

protocol NetworkManagerDelegate {
    func afterExchange(error: String)
    func refresh()
}

class NetworkManager {
    
    var delegate: NetworkManagerDelegate!
    
    // будем выгружать файл ответ только после того как будут прочитаны оба файла от 1С
    var readFileCounter: Int = 0 {
        didSet(oldValue) {
            if readFileCounter == 2 {
                // определим дату
                let lastDate: Date
                let userDefault = UserDefaults.standard
                let date = userDefault.object(forKey: "LastDate") as? Date
                if let date = date {
                    lastDate = date
                } else {
                    lastDate = Date()
                }
                // отправим файл запрос
                sendJSONResponse(date: lastDate)
                delegate.refresh()
                // сбросим счетчик
                readFileCounter = 0
            }
        }
    }
    
    // признак того что весь цикл обмена завершен
    var exchangeComplete: (complete: Bool , error: String ) = (true, "") {
        didSet(oldValue) {
            // остановим вращение кнопки
            if exchangeComplete.complete, delegate != nil {
                delegate.afterExchange(error: exchangeComplete.error)
            }
        }
    }
    
    
    // Получим запрос для обращения к серверу Яндекса
    func formRequest(baseCode: String = "", mode: TransferMode) -> URLRequest? {
        
        switch mode {
            
        case .download:
            let token = ConnectionSettings.shared.token
            var path = ConnectionSettings.shared.path + "/" + baseCode + "_" + ConnectionSettings.shared.nameFile
            
            path = "disk:" + path.replacingOccurrences(of: "/", with: "%2F")
            
            let url = URL(string: ConnectionSettings.shared.urlForDownload + path)
            
            guard let requestURL = url else { return nil}
            
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = ConnectionSettings.shared.headers
            
            return request
            
        case .upload:
            var path = ConnectionSettings.shared.path + "/" + ConnectionSettings.shared.nameFileResponse + ConnectionSettings.shared.overwriteOption
            
            path = "disk:" + path.replacingOccurrences(of: "/", with: "%2F")
            
            let url = URL(string: ConnectionSettings.shared.urlForUpload + path)
            
            guard let requestURL = url else { return nil}
            
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = ConnectionSettings.shared.headers
            
            return request
            
        }
    }
    
    // Выполнить запрос к яндексу и получить данные
    func downloadData(with request: URLRequest) {
        
        getRequestToYandex(withRequest: request) { data, error in
            if error != nil {
                
                //print("Не удалось получить ссылку на скачивание!")
                self.exchangeComplete = (true, "Не удалось получить ссылку на скачивание!")
                return
                
            } else if let data = data {
                // Достанем json из данных в модель и получим ссылку для скачивания
                let decoder = JSONDecoder()
                let res = try? decoder.decode(Res.self, from: data)
                
                guard let res = res else {
                    //print("Не удалось получить данные из json в модель")
                    self.exchangeComplete = (true, "Не удалось получить данные из json в модель")
                    return
                }
                
                // Скачать json по ссылке
                let urlForDownload = URL(string: res.href)
                
                guard let urlForDownload = urlForDownload else {
                    //print("Не удалось получить URL!")
                    self.exchangeComplete = (true, "Не удалось получить URL!")
                    return
                }
                
                URLSession.shared.dataTask(with: urlForDownload) { data, response, error in
                    
                    if let data = data {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let tables = try? decoder.decode(Tables.self, from: data)
                        guard let tables = tables else {
                            //print("Не удалось декодировать json")
                            self.exchangeComplete = (true, "Не удалось декодировать json")
                            return
                        }
                       
                        // очистим дату, если данные получены за запрашиваемый период
                        let defaults = UserDefaults.standard
                        let date = defaults.object(forKey: "LastDate") as? Date
                        
                        if let date = date {
                            if tables.dateStart <= date {
                                defaults.removeObject(forKey: "LastDate")
                            }
                        }
                        
                        // Удалить данные из базы за период таблицы
                        self.deletePeriod(dateStart: tables.dateStart, dateEnd: tables.dateEnd, storeName: tables.fromStoreName) //fromStoreName
                        // Записать новые строки в базу данных
                        self.writeToRealm(table: tables)
                        
                        // Удалим данные из таблицы CashInBox по Магазину
                        self.deleteCashInBox(storeName: tables.fromStoreName)
                        // Добавим остатки в кассах по Магазинам
                        self.writeCashInBox(storeName: tables.fromStoreName, cash: tables.cashAtBox)
                        
                    } else if let error = error {
                        //print("HTTP запрос не выполнен \(error)")
                        self.exchangeComplete = (true, "HTTP запрос не выполнен \(error)")
                        return
                    }
                    
                    self.readFileCounter += 1
                    
                }.resume()
                
            }
        }
    }
    
    // Обращаемся к яндексу получаем ответ и выполняем completion с данным ответом
    func getRequestToYandex(withRequest request: URLRequest, withCompletion completion: @escaping(Data?, Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if error != nil {
                completion(nil, error)
                return
            }
            
            guard let data = data else { return }
            
            completion(data, nil)
            
        }
        
        task.resume()
    }
    
    // Отправить файл ответ для 1С
    func sendJSONResponse(date: Date) {
        
        let request = formRequest(mode: .upload)
        
        guard let request = request else {
            print("Не удалось сформировать запрос")
            return
        }
        
        getRequestToYandex(withRequest: request) { data, error in
            
            if error != nil {
                
                print("Не удалось получить ссылку на загрузку!")
                return
                
            } else if let data = data {
                
                // Достанем json из данных в модель и получим ссылку для загрузки
                let decoder = JSONDecoder()
                let res = try? decoder.decode(Res.self, from: data)
                
                guard let res = res else {
                    print("Не удалось получить данные из json в модель")
                    return
                }
                
                // Скачать json по ссылке
                let urlForUpload = URL(string: res.href)
                
                guard let urlForUpload = urlForUpload else {
                    print("Не удалось получить URL!")
                    return
                }
                
                // Подготовим json ответ
                let parameters = ["lastDate": date]
                let jsonEncoder = JSONEncoder()
                jsonEncoder.dateEncodingStrategy = .iso8601
                let jsonData = try! jsonEncoder.encode(parameters)
                //let jsonString = String(data: jsonData, encoding: .utf8)
                
                
                // Подготовим запрос
                var urlRequest = URLRequest(url: urlForUpload)
                urlRequest.httpMethod = "PUT"
                urlRequest.httpBody = jsonData
                
                URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                   
                    if let error = error {
                        print("Не удалось создать файл ответ на сервере \(error.localizedDescription)")
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse, response.statusCode != 201 {
                        print("Не удалось создать файл ответ на сервере")
                    }
                     
                    // обмен завершен
                    self.exchangeComplete.complete = true
                    
                }.resume()
            }
            
        }
    }
    
    // Данные функции подлежат переносы в реалмменеджер ////////////////////
    
    func writeCashInBox(storeName: String, cash: Double) {
        
        let realm = try! Realm()
        
        var cashInbox = CashInBox()
        cashInbox.storeName = storeName
        cashInbox.ammount = cash
        
        // Не получилось использовать менеджер тк нельзя передавать Realm между потоками
        //RealmManager.write(cashInbox)
        try! realm.write{
            realm.add(cashInbox)
        }
        
        print("Запись в таблицу наличных ДС выполнена")
    }
    
    // Удалим данные таблицы
    func deleteCashInBox(storeName: String) {
        
        let realm = try! Realm()
        
        let cashInBox = realm.objects(CashInBox.self)
        
        let rowForStore = cashInBox.where {
            ($0.storeName == storeName)
        }
        
        // Удалим строки
        // Нельзя передавать Realm между потоками не смог использовать RealmManager
        //RealmManager.delete(rowForStore)
        
        try! realm.write{
            realm.delete(rowForStore)
        }
        
        print("Таблица наличных ДС в кассах очищена")
    }
    
    // Удалим данные за период по магазину
    func deletePeriod(dateStart: Date, dateEnd: Date, storeName: String) {
        
        let realm = try! Realm()
        
        let sales = realm.objects(Sales.self)
        
        // Выберем строки за период
        let rowsPerPeriod = sales.where {
            ($0.date >= dateStart) && ($0.date <= dateEnd)
            && ($0.storeName == storeName)
        }
        
        print("Выбрано \(rowsPerPeriod.count) строк")
        
        // Удалим строки
        //RealmManager.delete(rowsPerPeriod)
        // Нельзя передавать Realm между потоками не смог использовать RealmManager
        try! realm.write {
            realm.delete(rowsPerPeriod)
        }
    }
    
    func writeToRealm(table: Tables) {
        
        let realm = try! Realm()
        
        var rows = table.rows
        print("Будет записано \(rows.count) строк")
        for row in rows {
            var newRow = Sales()
            newRow.storeName = row.storeName
            newRow.name = row.name
            newRow.art = row.art
            newRow.date = row.date
            newRow.size = row.size
            newRow.ammount = row.ammount
            newRow.autoDisc = row.autoDisc
            newRow.manDisc = row.manDisc
            newRow.price = row.price
            newRow.qty = row.qty
            newRow.bonusDisc = row.bonusDisc
            
            //RealmManager.write(newRow)
            try! realm.write {
                realm.add(newRow)
            }
        }
        
        print("Запись в базу данных выполнена")
    }
    
}


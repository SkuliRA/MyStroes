//
//  ViewController.swift
//  myStrores
//
//  Created by Skuli on 08.02.2023.
//

import UIKit
import RealmSwift

class PanelViewController: UIViewController {
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var sumToday: UILabel!
    @IBOutlet weak var cashInBoxLabel: UILabel!
    @IBOutlet weak var sumByMonth: UILabel!
    @IBOutlet weak var sumYesterdayLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // будем выгружать файл ответ только после того как будут прочитаны оба файла от 1С
    var readFileCounter: Int = 0 {
        didSet(oldValue) {
            if readFileCounter == 2 {
                sendJSONResponse(date: Date())
                // сбросим счетчик
                readFileCounter = 0
            }
        }
    }
    
    // признак того что весь цикл обмена завершен
    var exchangeComplete: (complete: Bool , error: String ) = (true, "") {
        didSet(oldValue) {
            // остановим вращение кнопки
            if exchangeComplete.complete {
                DispatchQueue.main.async {
                    self.refreshButton.stopRotating()
                    self.refreshButton.isEnabled = true
                    self.refreshButton.tintColor = .black
                }
            }
            
            // Выведем ошибку
            if exchangeComplete.error != "" {
                print(exchangeComplete.error)
                DispatchQueue.main.async {
                    self.refreshButton.tintColor = .red
                }
            }
            
        }
    }
    
    var arrayOfIndicators: [Indicators] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshButton.layer.cornerRadius = 25
        refreshButton.clipsToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Do any additional setup after loading the view.
        //        let config = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        //        Realm.Configuration.defaultConfiguration = config
        //        let realm = try! Realm()
        print(Realm.Configuration.defaultConfiguration)
        
        refreshIndicators()
        
        refreshDataFromYandex(view)
    }
    
    func refreshIndicators() {
        
        arrayOfIndicators.removeAll()
        
        var indicator = Indicators(nameIndicator: "", firstIndicator: "Флагман", secondIndicator: "Фестиваль")
        arrayOfIndicators.append(indicator)
        
        let calendar = Calendar.current
        let startTime = calendar.startOfDay(for: Date())
        
        // Возвращает конец прошлого дня
        let startOfDay = Date().startOfDay()
        
        let startOfYestarday = (startOfDay - 1).startOfDay()
        // Возвращает конец прошлого месяца
        let startOfMonth = Date().startOfMonth()
        
        let store1 = StoreName.flagman.rawValue
        let store2 = StoreName.festival.rawValue
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        
        let salesForYestardayStore1 = getSalesForPeriod(dateStart: startOfYestarday, dateEnd: startOfDay, storeName: store1)
        let salesForYestardayStore2 = getSalesForPeriod(dateStart: startOfYestarday, dateEnd: startOfDay, storeName: store2)
        indicator = Indicators(nameIndicator: "Вчера:", firstIndicator: salesForYestardayStore1.formatWithSpace(), secondIndicator: salesForYestardayStore2.formatWithSpace())
        arrayOfIndicators.append(indicator)
        
        let salesForTodayStore1 = getSalesForPeriod(dateStart: startOfDay, storeName: store1)
        let salesForTodayStore2 = getSalesForPeriod(dateStart: startOfDay, storeName: store2)
        indicator = Indicators(nameIndicator: "Сегодня:", firstIndicator: salesForTodayStore1.formatWithSpace(), secondIndicator: salesForTodayStore2.formatWithSpace())
        arrayOfIndicators.append(indicator)
        
        let salesForMonthStore1 = getSalesForPeriod(dateStart: startOfMonth, storeName: store1)
        let salesForMonthStore2 = getSalesForPeriod(dateStart: startOfMonth, storeName: store2)
        indicator = Indicators(nameIndicator: "Этот месяц:", firstIndicator: salesForMonthStore1.formatWithSpace(), secondIndicator: salesForMonthStore2.formatWithSpace())
        arrayOfIndicators.append(indicator)
        
        let cashInBoxStore1 = getCashInBox(storeName: store1)
        let cashInBoxStore2 = getCashInBox(storeName: store2)
        indicator = Indicators(nameIndicator: "В кассе:", firstIndicator: cashInBoxStore1.formatWithSpace(), secondIndicator: cashInBoxStore2.formatWithSpace())
        arrayOfIndicators.append(indicator)
        
        tableView.reloadData()
    }
    
    func getCashInBox(storeName: String) -> Double {
        
        let realm = try! Realm()
        
        let cashInBox = realm.objects(CashInBox.self)
        
        let cashForStore = cashInBox.where {
            $0.storeName == storeName
        }
        
        return cashForStore.first?.ammount ?? 0
        
    }
    
    // Функция получает продажи за период
    // dateEnd и storeName не обязательные параметры
    func getSalesForPeriod(dateStart: Date, dateEnd: Date? = nil, storeName: String? = nil) -> Double {
        
        let realm = try! Realm()
        
        let sales = realm.objects(Sales.self)
        
        // Выберем строки за период
        let rowsPerPeriod = sales.where {
            if storeName == nil && dateEnd == nil {
                return ($0.date > dateStart)
            } else if dateEnd != nil && storeName == nil {
                return ($0.date > dateStart) && ($0.date <= dateEnd)
            } else if dateEnd == nil && storeName != nil {
                return ($0.date > dateStart) && ($0.storeName == storeName)
            } else {
                return ($0.date > dateStart) && ($0.date <= dateEnd) && ($0.storeName == storeName)
            }
        }
        
        // Просуммируем продажи
        var summ = 0.00
        for row in rowsPerPeriod {
            summ += row.ammount ?? 0.00
        }
        
        return summ
    }
    
    @IBAction func refreshDataFromYandex(_ sender: Any) {
        
        // вращаем кнопку
        refreshButton.rotate(duration: 1.0)
        refreshButton.isEnabled = false
        
        // начало обмена установим признак окончания обмена в ложь
        exchangeComplete = (false, "")
        
        var request: URLRequest!
        
        // Выполним для всех утсановленных в настроках баз
        for base in BaseCode.allCases {
            // Подготовим запрос
            request = formRequest(baseCode: base.rawValue, mode: .download)
            
            guard let request = request else {
                print("Ошибка получения URL запроса")
                return
            }
            
            refreshDataBase(with: request)
        }
        
    }
    
    // Выполнить запрос к яндексу и получить данные
    func refreshDataBase(with request: URLRequest) {
        
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
                        // Нужна будет оптимизация функций Realm
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
                    
                    // Обновим показатели
                    DispatchQueue.main.async {
                        self.refreshIndicators()
                    }
                    
                    self.readFileCounter += 1
                    
                }.resume()
                
            }
        }
        
    }
    
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
}

extension PanelViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped me")
    }
}

extension PanelViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfIndicators.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        
        cell.indicatorLabel.text = arrayOfIndicators[indexPath.row].nameIndicator
        cell.store1Label.text = arrayOfIndicators[indexPath.row].firstIndicator
        cell.store2Label.text = arrayOfIndicators[indexPath.row].secondIndicator
        
        return cell
    }
    
}

extension UIView {
    private static let kRotationAnimationKey = "rotationanimationkey"

    func rotate(duration: Double = 1) {
        if layer.animation(forKey: UIView.kRotationAnimationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")

            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float.pi * 2.0
            rotationAnimation.duration = duration
            rotationAnimation.repeatCount = Float.infinity

            layer.add(rotationAnimation, forKey: UIView.kRotationAnimationKey)
        }
    }

    func stopRotating() {
        if layer.animation(forKey: UIView.kRotationAnimationKey) != nil {
            layer.removeAnimation(forKey: UIView.kRotationAnimationKey)
        }
    }
}

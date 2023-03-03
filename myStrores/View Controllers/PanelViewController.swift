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
    
    var arrayOfIndicators: [Indicators] = []
    var networkManager = NetworkManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkManager.delegate = self
        
        refreshButton.layer.cornerRadius = 25
        refreshButton.clipsToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //        Этим кодом можно очистить БД
        //        let config = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        //        Realm.Configuration.defaultConfiguration = config
        //        let realm = try! Realm()
        
        // Посмотрим где лежит файл БД
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
        
        let realmManager = RealmManager()
        
        let salesForYestardayStore1 = realmManager.getSalesForPeriod(dateStart: startOfYestarday, dateEnd: startOfDay, storeName: store1)
        let salesForYestardayStore2 = realmManager.getSalesForPeriod(dateStart: startOfYestarday, dateEnd: startOfDay, storeName: store2)
        indicator = Indicators(nameIndicator: "Вчера:", firstIndicator: salesForYestardayStore1.summ.formatWithSpace(), secondIndicator: salesForYestardayStore2.summ.formatWithSpace())
        arrayOfIndicators.append(indicator)
        
        let salesForTodayStore1 = realmManager.getSalesForPeriod(dateStart: startOfDay, storeName: store1)
        let salesForTodayStore2 = realmManager.getSalesForPeriod(dateStart: startOfDay, storeName: store2)
        indicator = Indicators(nameIndicator: "Сегодня:", firstIndicator: salesForTodayStore1.summ.formatWithSpace(), secondIndicator: salesForTodayStore2.summ.formatWithSpace())
        arrayOfIndicators.append(indicator)
        
        let salesForMonthStore1 = realmManager.getSalesForPeriod(dateStart: startOfMonth, storeName: store1)
        let salesForMonthStore2 = realmManager.getSalesForPeriod(dateStart: startOfMonth, storeName: store2)
        indicator = Indicators(nameIndicator: "Этот месяц:", firstIndicator: salesForMonthStore1.summ.formatWithSpace(), secondIndicator: salesForMonthStore2.summ.formatWithSpace())
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
    
    @IBAction func refreshDataFromYandex(_ sender: Any) {
        
        // вращаем кнопку
        refreshButton.rotate(duration: 1.0)
        refreshButton.isEnabled = false
        
        // начало обмена установим признак окончания обмена в ложь
        networkManager.exchangeComplete = (false, "")
        
        // Выполним для всех утсановленных в настроках баз
        for base in BaseCode.allCases {
            // Подготовим запрос
            let request = networkManager.formRequest(baseCode: base.rawValue, mode: .download)
            
            guard let request = request else {
                print("Ошибка получения URL запроса")
                return
            }
            
            networkManager.downloadData(with: request)
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

extension PanelViewController: NetworkManagerDelegate {
  
    func afterExchange(error: String) {
        
        DispatchQueue.main.async {
            self.refreshButton.stopRotating()
            self.refreshButton.isEnabled = true
            self.refreshButton.tintColor = .black
        }
        
        if error != "" {
            DispatchQueue.main.async {
                self.refreshButton.tintColor = .red
                print(error)
            }
        }
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.refreshIndicators()
        }
    }
    
}

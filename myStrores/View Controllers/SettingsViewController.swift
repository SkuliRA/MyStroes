//
//  SettingsViewController.swift
//  myStrores
//
//  Created by Skuli on 17.02.2023.
//

import UIKit

class SettingsViewController: UIViewController {
    
    var networkManager = NetworkManager()
    @IBOutlet weak var requestDatePicker: UIDatePicker!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkManager.delegate = self
    }
    
    @IBAction func requestFrom1CButton(_ sender: Any) {
        activityIndicator.startAnimating()
        networkManager.sendJSONResponse(date: requestDatePicker.date)
        // сохраним дату в настройках пользователя
        // и будем держать ее там, пока не получим данные за этот период
        let defaults = UserDefaults.standard
        defaults.set(requestDatePicker.date, forKey: "LastDate")
    }

}

extension SettingsViewController: NetworkManagerDelegate {
   
    func afterExchange(error: String) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
    
  
    func refresh() {

    }
    
}

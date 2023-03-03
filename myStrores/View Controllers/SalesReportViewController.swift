//
//  SalesTodayViewController.swift
//  myStrores
//
//  Created by Skuli on 27.02.2023.
//

import UIKit
import RealmSwift

class SalesReportViewController: UIViewController {
    
    var rowsSales: Results<Sales>!
    let realmManager = RealmManager()
    var storeFilter: String?
    
    @IBOutlet weak var artTextField: UITextField!
    @IBOutlet weak var dateBegin: UIDatePicker!
    @IBOutlet weak var dateEnd: UIDatePicker!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var storePicker: UIPickerView!
    @IBOutlet weak var summ: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshButton.layer.cornerRadius = 10
        refreshButton.clipsToBounds = true
        
        tableView.dataSource = self
        storePicker.delegate = self
        storePicker.dataSource = self
        
        getRowsForPeriod(dateBegin: Date().startOfDay())
        
        storePicker.selectRow(StoreName.allCases.count, inComponent: 0, animated: true)
        
        
    }
    
    @IBAction func refreshReport(_ sender: Any) {
        
        let sales = realmManager.getSalesForPeriod(dateStart: dateBegin.date.startOfDay(), dateEnd: dateEnd.date.endOfDay, storeName: storeFilter)
        
        rowsSales = sales.rows
        
        summ.text = sales.summ.formatWithSpace()
        
        tableView.reloadData()
    }
    
    
    func getRowsForPeriod(dateBegin: Date, dateEnd: Date? = nil, store: String? = nil) {
        
        let sales = realmManager.getSalesForPeriod(dateStart: dateBegin)
        
        rowsSales = sales.rows
        
        summ.text = sales.summ.formatWithSpace()
    }
    
    
}

extension SalesReportViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return rowsSales.count

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellSales", for: indexPath) as! CellSalesReport
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
       
        var storeName = (rowsSales[indexPath.row].storeName ?? "")
        
        if storeName == StoreName.flagman.rawValue {
            cell.backgroundColor = .lightGray
        } else {
            cell.backgroundColor = .none
        }
        
        storeName = storeName.trimmingCharacters(in: .whitespaces)
        cell.store.text = storeName.components(separatedBy: " ").last
        cell.date.text = dateFormatter.string(from: rowsSales[indexPath.row].date!)
        cell.art.text = rowsSales[indexPath.row].art ?? ""
        cell.name.text = rowsSales[indexPath.row].name ?? ""
        cell.size.text = rowsSales[indexPath.row].size ?? ""
        cell.amount.text = rowsSales[indexPath.row].ammount?.formatWithSpace()
        cell.quantity.text = String(rowsSales[indexPath.row].qty!)
        cell.bonus.text = rowsSales[indexPath.row].bonusDisc?.formatWithSpace()
        cell.manDisc.text = rowsSales[indexPath.row].manDisc?.formatWithSpace()
        cell.price.text = rowsSales[indexPath.row].price?.formatWithSpace()
        
        
        
        return cell
    }
}


extension SalesReportViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return StoreName.allCases.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch row {
        case 0: return "Флагман"
        case 1: return "Фестиваль"
        default: return "По всем"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if row <= (StoreName.allCases.count - 1) {
            storeFilter = StoreName.allCases[row].rawValue
        } else {
            storeFilter = nil
        }
    }
}

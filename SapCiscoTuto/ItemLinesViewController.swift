//
//  ItemLinesViewController.swift
//  SapCiscoTuto
//
//  Created by Guillaume Henique on 10/08/2018.
//  Copyright © 2018 SAP. All rights reserved.
//
//  SAP Fiori for iOS Mentor
//  SAP Cloud Platform SDK for iOS Code Example
//  Object Cell
//  Copyright © 2018 SAP SE or an SAP affiliate company. All rights reserved.


import SAPFiori
import SAPOData
import Foundation
import SAPOfflineOData

import SAPCommon


class ItemLinesViewController: UIViewController, UITableViewDataSource, SAPFioriLoadingIndicator {
    
    var loadingIndicator: FUILoadingIndicatorView?
    //var boolDelete: Bool = false
    private let logger = Logger.shared(named: "ItemLinesControllerLogger")
    @IBOutlet var tableView: UITableView!
    var totalQty : Int = 0
    var salesOrderToShow: SalesOrder?
    let objectCellId = "ItemLineCellID"
    var lineItemSet: [SalesOrderLineItem] = [SalesOrderLineItem]()
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var gwsampleEntites: GWSAMPLEBASICEntities<OnlineODataProvider> {
        return self.appDelegate.gwsamplebasicEntities
    }
    private var idSalesOrder: String?
    var entitySelected: SalesOrderLineItem?
    var boolFromCreation: Bool = false
    func setIDSalesOrder(id: String)
    {
        self.idSalesOrder = id
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateSaleOrderToShow()
        self.navigationItem.title="Order : \(idSalesOrder ?? " ")"
        if(boolFromCreation){
            
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "SAP Cisco", style: .plain, target: self, action:#selector(backToDashboard(_:)))
            
            //  navigationItem.backBarButtonItem = UIBarButtonItem(title: "SAP Cisco", style: .plain, target: nil, action:#selector(backToDashboard(_:)))
            // navigationItem.hidesBackButton = false
        }
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh , target: self, action: #selector(refreshScanner(_:)))
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(createLine(_:)))
        let spacer = UIBarButtonItem()
        self.navigationItem.rightBarButtonItems = [addButton,spacer,spacer,spacer,spacer,refreshButton]
        
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: objectCellId)
        tableView.dataSource=self
        updateTable()
    }
    
    func setIdSalesOrder(id: String)
    {
        self.idSalesOrder = id
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if(indexPath.row < self.lineItemSet.count){
            if editingStyle == .delete {
                let entity = self.lineItemSet[indexPath.row]
                self.gwsampleEntites.deleteEntity(entity) { error in
                    self.hideFioriLoadingIndicator()
                    if let error = error {
                        FUIToastMessage.show(message: "Error: this line can't be deleted!")
                        self.logger.error("Create entry failed. Error: \(error)", error: error)
                        self.updateSaleOrderToShow()
                        self.viewDidLoad()
                    }
                    else{
                        FUIToastMessage.show(message: "Item Deleted !")
                        self.viewDidLoad()
                    }
                }
            }
        }
    }
    func updateQty()
    {
        var qty: Int = 0
        for line in lineItemSet
        {
            qty = qty + (line.quantity?.intValue())!
        }
        self.totalQty = qty
    }
    
    // Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.lineItemSet.count+1 // return number of rows of data source
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let objectCell = tableView.dequeueReusableCell(withIdentifier: objectCellId,
                                                       for: indexPath as IndexPath) as! FUIObjectTableViewCell
        if(indexPath.row < self.lineItemSet.count)
        {
            do{
                let orderLine = self.lineItemSet[indexPath.row]
                let query = DataQuery().selectAll().filter(Product.productID == orderLine.productID!)
                let productRelated = try self.gwsampleEntites.fetchProduct(matching: query)
                
                objectCell.subheadlineText = "\(orderLine.productID ?? "")   -   \(productRelated.name ?? "") "
                objectCell.footnoteText = "\(productRelated.category ?? "")"
                objectCell.descriptionText = "price:  \(productRelated.price!)          |"
                
                objectCell.detailImage = HelperImages.imageFromCategory(category: productRelated.category!)
                objectCell.statusText = "qty: \(orderLine.quantity!)     |     \(orderLine.netAmount!) \(orderLine.currencyCode!)"
                /* if(boolDelete){
                 let tap = UITapGestureRecognizerCustom(target: self, action: #selector(self.handleLineTap(_:)))
                 objectCell.addGestureRecognizer(tap)
                 tap.index = indexPath.row
                 }*/
                
            } catch let error
            {
                print(error)
            }
        }else{
            
            objectCell.descriptionText = "      TOTAL              |"
            objectCell.statusText = "qty: \(self.totalQty)   |     \((self.salesOrderToShow?.netAmount)!) \((self.salesOrderToShow?.currencyCode)!)"
        }
        return objectCell
    }
    
    func updateTable() {
        self.showFioriLoadingIndicator()
        let oq = OperationQueue()
        oq.addOperation({
            self.loadData {
                self.updateQty()
                self.hideFioriLoadingIndicator()
            }
        })
        
    }
    
    private func loadData(completionHandler: @escaping () -> Void) {
        self.requestEntities { error in
            defer {
                completionHandler()
            }
            if let error = error {
                let alertController = UIAlertController(title: NSLocalizedString("keyErrorLoadingData", value: "Loading data failed!", comment: "XTIT: Title of loading data error pop up."), message: error.localizedDescription, preferredStyle: .alert)
                
                OperationQueue.main.addOperation({
                    self.present(alertController, animated: true)
                })
                return
            }
            OperationQueue.main.addOperation({
                self.tableView.reloadData()
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addLineItem" {
            if let createLineViewController = segue.destination as? CreateSalesOrderLineViewController{
                createLineViewController.iDSaleOrderToFill = self.salesOrderToShow?.salesOrderID
                createLineViewController.updateProducts()
                
            }
            
        }
        if segue.identifier == "backToDashboardView" {
            let dashboardView = segue.destination as! DashboardViewController
            dashboardView.navigationItem.hidesBackButton = true
            
        }
    }
    
    func requestEntities(completionHandler: @escaping (Error?) -> Void) {
        let query = DataQuery().selectAll().filter(SalesOrderLineItem.salesOrderID == self.idSalesOrder!)
        self.gwsampleEntites.fetchSalesOrderLineItemSet(matching: query) { line, error in
            guard let line = line else {
                completionHandler(error!)
                return
            }
            self.lineItemSet = line
            completionHandler(nil)
        }
        
    }
   
    
    @objc func createLine(_ sender:UITapGestureRecognizerCustom) {
        performSegue(withIdentifier: "addLineItem", sender: nil)
    }
    
    @objc func refreshScanner(_ sender:UITapGestureRecognizerCustom) {
        
        self.updateSaleOrderToShow()
        self.viewDidLoad()
    }
    @objc func backToDashboard(_ sender:UITapGestureRecognizerCustom) {
        // self.performSegue(withIdentifier: "backToDashboardView", sender: nil)
        //self.navigationController?.popViewController(animated: false)
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    
    func updateSaleOrderToShow()
    {
        do{
            
            let querySalesOrder = DataQuery().selectAll().filter(SalesOrder.salesOrderID == (self.idSalesOrder)!)
            self.salesOrderToShow = try self.gwsampleEntites.fetchSalesOrder(matching: querySalesOrder)
            
        } catch let error
        {
            print(error)
        }
        
    }
    
    @objc func handleLineTap(_ sender:UITapGestureRecognizerCustom) {
        self.entitySelected = lineItemSet[sender.index]
        
        FUIToastMessage.show(message: "\(lineItemSet[sender.index].productID ?? " ") selected")
    }
    
    
}

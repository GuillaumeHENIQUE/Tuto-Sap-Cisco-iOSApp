//
//  CreateSalesOrderLineViewController.swift
//  SapCiscoTuto
//
//  Created by Guillaume Henique on 10/08/2018.
//  Copyright © 2018 SAP. All rights reserved.
//


import SAPFiori
import SAPOData
import Foundation
import SAPOfflineOData
import SAPCommon

class CreateSalesOrderLineViewController: UIViewController, UITableViewDataSource, SAPFioriLoadingIndicator {
    
    var entityUpdater: EntityUpdaterDelegate?
    var tableUpdater: EntitySetUpdaterDelegate?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var gwsamplebasicEntities: GWSAMPLEBASICEntities<OnlineODataProvider> {
        return self.appDelegate.gwsamplebasicEntities
    }
    let objectCellId = "ProductCellID"
    var idProductChoosen: String?
    var iDSaleOrderToFill: String?
    @IBOutlet var tableView: UITableView!
    private var productSet: [Product] = [Product]()
    private let logger = Logger.shared(named: "CreateSalesOrderLineViewControllerLogger")
    var loadingIndicator: FUILoadingIndicatorView?
    private var validity = [String: Bool]()
    private var _entity: SalesOrderLineItem?
    var allowsEditableCells = false
    private var gwsampleEntites: GWSAMPLEBASICEntities<OnlineODataProvider> {
        return self.appDelegate.gwsamplebasicEntities
    }
    var indexProductAdded: Int = 0
    var entity: SalesOrderLineItem {
        get {
            if self._entity == nil {
                self._entity = self.createEntityWithDefaultValues()
            }
            return self._entity!
        }
        set {
            self._entity = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: objectCellId)
        tableView.dataSource=self
        
        
        
        self.navigationItem.title="Choose Product To Add: "
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(validateChoice(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
        
        
    }
    /*
     func createEntityWithDefaultValues() -> SalesOrderLineItem {
     let newEntity = SalesOrderLineItem()
     // Fill the mandatory properties with default values
     newEntity.salesOrderID = CellCreationHelper.defaultValueFor(SalesOrderLineItem.salesOrderID)
     newEntity.itemPosition = CellCreationHelper.defaultValueFor(SalesOrderLineItem.itemPosition)
     newEntity.productID = self.productChoosen
     newEntity.deliveryDate = CellCreationHelper.defaultValueFor(SalesOrderLineItem.deliveryDate)
     newEntity.quantity = 1
     }*/
    func updateProducts()
    {
        do{
            
            let queryProducts = DataQuery().selectAll().orderBy(Product.supplierID, SAPOData.SortOrder.ascending).top(20)
            self.productSet = try self.gwsampleEntites.fetchProductSet(matching: queryProducts)
            
            
        } catch let error
        {
            print(error)
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productSet.count // return number of rows of data source
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let objectCell = tableView.dequeueReusableCell(withIdentifier: objectCellId,
                                                       for: indexPath as IndexPath) as! FUIObjectTableViewCell
        let product = self.productSet[indexPath.row]
        
        // objectCell.headlineText = "\(product.entityType ?? "")"
        objectCell.subheadlineText = "\(product.name ?? "")"
        objectCell.footnoteText = "\(product.category ?? "")"
        objectCell.descriptionText = "\(product.productID ?? "") - \(product.description ?? "")"
        objectCell.detailImage = HelperImages.imageFromCategory(category: product.category!) // TODO: Replace with your image
        //   objectCell.detailImage?.accessibilityIdentifier = ""
        let price: String = "\(product.price!.toString() ) EUR"
        objectCell.statusText = price
        objectCell.accessoryType = .disclosureIndicator
        objectCell.splitPercent = CGFloat(0.3)
        let tap = UITapGestureRecognizerCustom(target: self, action: #selector(self.handleProductTap(_:)))
        objectCell.addGestureRecognizer(tap)
        tap.id = product.productID!
        tap.index = indexPath.row
        return objectCell
    }
    
    @objc func createEntity() {
        self.showFioriLoadingIndicator()
        self.logger.info("Creating entity in backend.")
        self.gwsamplebasicEntities.createEntity(self.entity) { error in
            self.hideFioriLoadingIndicator()
            if let error = error {
                self.logger.error("Create entry failed. Error: \(error)", error: error)
                let alertController = UIAlertController(title: NSLocalizedString("keyErrorEntityCreationTitle", value: "Create entry failed", comment: "XTIT: Title of alert message about entity creation error."), message: error.localizedDescription, preferredStyle: .alert)
                //  alertController.addAction(UIAlertAction(title: self.okTitle, style: .default))
                OperationQueue.main.addOperation({
                    // Present the alertController
                    self.present(alertController, animated: true)
                })
                return
            }
            self.logger.info("Create entry finished successfully.")
            OperationQueue.main.addOperation({
                self.dismiss(animated: true) {
                    FUIToastMessage.show(message: NSLocalizedString("keyEntityCreationBody", value: "Created", comment: "XMSG: Title of alert message about successful entity creation."))
                    self.tableUpdater?.entitySetHasChanged()
                }
            })
        }
        
    }
    
    func initializeEntity()
    {
        self.entity.currencyCode = "EUR"
        self.entity.itemPosition = "none"
        self.entity.netAmount = productSet[self.indexProductAdded].price
        self.entity.note = productSet[self.indexProductAdded].description
        self.entity.noteLanguage = productSet[self.indexProductAdded].descriptionLanguage
        self.entity.quantity = BigDecimal(1)
        self.entity.productID = self.idProductChoosen
        self.entity.salesOrderID = self.iDSaleOrderToFill
        
    }
    
    
    @objc func handleProductTap(_ sender:UITapGestureRecognizerCustom) {
        self.idProductChoosen = sender.id
        self.indexProductAdded = sender.index
        FUIToastMessage.show(message: "\(self.productSet[sender.index].productID ?? "") selected")
    }
    
    @objc func validateChoice(_ sender:UITapGestureRecognizerCustom) {
        
        createEntityWithDefaultValues()
        initializeEntity()
        createEntity()
        performSegue(withIdentifier: "backToItemLineViewController", sender: nil)
        
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "backToDashboardViewController" {
            let dashboardView = segue.destination as! DashboardViewController
            FUIToastMessage.show(message: "Line Item Added to SaleOrder \(self.entity.salesOrderID ?? "")")
            dashboardView.navigationItem.hidesBackButton = true
            //dashboardView.navigationItem.backBarButtonItem?.action
        }
        if segue.identifier == "backToItemLineViewController" {
            let lineItemView = segue.destination as! ItemLinesViewController
            FUIToastMessage.show(message: "\(self.idProductChoosen ?? "") Added to SaleOrder!")
            
            lineItemView.setIDSalesOrder(id: self.iDSaleOrderToFill!)
            lineItemView.updateSaleOrderToShow()
            lineItemView.navigationItem.hidesBackButton = true
            lineItemView.boolFromCreation = true
            
        }
    }
    
    
    
    ////////////////////////////////////
    //default values entity creation
    ////////////////////////////////////
    
    private func cellForSalesOrderID(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.salesOrderID ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if SalesOrderLineItem.salesOrderID.isOptional || newValue != "" {
                currentEntity.salesOrderID = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForItemPosition(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.itemPosition ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if SalesOrderLineItem.itemPosition.isOptional || newValue != "" {
                currentEntity.itemPosition = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForProductID(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.productID ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if SalesOrderLineItem.productID.isOptional || newValue != "" {
                currentEntity.productID = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForNote(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.note {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.note = nil
                isNewValueValid = true
            } else {
                if SalesOrderLineItem.note.isOptional || newValue != "" {
                    currentEntity.note = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForNoteLanguage(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.noteLanguage {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.noteLanguage = nil
                isNewValueValid = true
            } else {
                if SalesOrderLineItem.noteLanguage.isOptional || newValue != "" {
                    currentEntity.noteLanguage = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForCurrencyCode(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.currencyCode {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.currencyCode = nil
                isNewValueValid = true
            } else {
                if SalesOrderLineItem.currencyCode.isOptional || newValue != "" {
                    currentEntity.currencyCode = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForGrossAmount(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.grossAmount {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.grossAmount = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.grossAmount = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForNetAmount(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.netAmount {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.netAmount = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.netAmount = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForTaxAmount(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.taxAmount {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.taxAmount = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.taxAmount = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForDeliveryDate(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        value = currentEntity.deliveryDate != nil ? "\(currentEntity.deliveryDate!)" : ""
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if let validValue = LocalDateTime.parse(newValue) { // This is just a simple solution to handle UTC only
                currentEntity.deliveryDate = validValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForQuantity(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        value = currentEntity.quantity != nil ? "\(currentEntity.quantity!)" : ""
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if let validValue = BigDecimal.parse(newValue) {
                currentEntity.quantity = validValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    private func cellForQuantityUnit(tableView: UITableView, indexPath: IndexPath, currentEntity: SalesOrderLineItem, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.quantityUnit {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.quantityUnit = nil
                isNewValueValid = true
            } else {
                if SalesOrderLineItem.quantityUnit.isOptional || newValue != "" {
                    currentEntity.quantityUnit = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            
            return isNewValueValid
        })
    }
    
    
    func createEntityWithDefaultValues() -> SalesOrderLineItem {
        let newEntity = SalesOrderLineItem()
        // Fill the mandatory properties with default values
        newEntity.salesOrderID = CellCreationHelper.defaultValueFor(SalesOrderLineItem.salesOrderID)
        newEntity.itemPosition = CellCreationHelper.defaultValueFor(SalesOrderLineItem.itemPosition)
        newEntity.productID = CellCreationHelper.defaultValueFor(SalesOrderLineItem.productID)
        newEntity.deliveryDate = CellCreationHelper.defaultValueFor(SalesOrderLineItem.deliveryDate)
        newEntity.quantity = CellCreationHelper.defaultValueFor(SalesOrderLineItem.quantity)
        
        // Key properties without default value should be invalid by default for Create scenario
        if newEntity.salesOrderID == nil || newEntity.salesOrderID!.isEmpty {
            self.validity["SalesOrderID"] = false
        }
        if newEntity.itemPosition == nil || newEntity.itemPosition!.isEmpty {
            self.validity["ItemPosition"] = false
        }
        return newEntity
    }
    /////////////////////////////////////////
    //End default values entity creation
    ////////////////////////////////////////
}

extension CreateSalesOrderLineViewController: EntityUpdaterDelegate {
    func entityHasChanged(_ entityValue: EntityValue?) {
        if let entity = entityValue {
            let currentEntity = entity as! SalesOrderLineItem
            self.entity = currentEntity
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
}




//
// ProductSetDetailViewController.swift
// SapCiscoTuto
//
// Created by SAP Cloud Platform SDK for iOS Assistant application on 08/08/18
//

import Foundation
import SAPCommon
import SAPFiori
import SAPFoundation
import SAPOData

class ProductSetDetailViewController: FUIFormTableViewController, SAPFioriLoadingIndicator {
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var gwsamplebasicEntities: GWSAMPLEBASICEntities<OnlineODataProvider> {
        return self.appDelegate.gwsamplebasicEntities
    }

    private var validity = [String: Bool]()
    private var _entity: Product?
    var allowsEditableCells = false
    var entity: Product {
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

    private let logger = Logger.shared(named: "ProductSetMasterViewControllerLogger")
    var loadingIndicator: FUILoadingIndicatorView?
    var entityUpdater: EntityUpdaterDelegate?
    var tableUpdater: EntitySetUpdaterDelegate?
    private let okTitle = NSLocalizedString("keyOkButtonTitle",
                                            value: "OK",
                                            comment: "XBUT: Title of OK button.")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "updateEntity" {
            // Show the Detail view with the current entity, where the properties scan be edited and updated
            self.logger.info("Showing a view to update the selected entity.")
            let dest = segue.destination as! UINavigationController
            let detailViewController = dest.viewControllers[0] as! ProductSetDetailViewController
            detailViewController.title = NSLocalizedString("keyUpdateEntityTitle", value: "Update Entity", comment: "XTIT: Title of update selected entity screen.")
            detailViewController.entity = self.entity
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: detailViewController, action: #selector(detailViewController.updateEntity))
            detailViewController.navigationItem.rightBarButtonItem = doneButton
            let cancelButton = UIBarButtonItem(title: NSLocalizedString("keyCancelButtonToGoPreviousScreen", value: "Cancel", comment: "XBUT: Title of Cancel button."), style: .plain, target: detailViewController, action: #selector(detailViewController.cancel))
            detailViewController.navigationItem.leftBarButtonItem = cancelButton
            detailViewController.allowsEditableCells = true
            detailViewController.entityUpdater = self
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return self.cellForProductID(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.productID)
        case 1:
            return self.cellForTypeCode_(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.typeCode_)
        case 2:
            return self.cellForCategory(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.category)
        case 3:
            return self.cellForName(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.name)
        case 4:
            return self.cellForNameLanguage(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.nameLanguage)
        case 5:
            return self.cellForDescription(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.description)
        case 6:
            return self.cellForDescriptionLanguage(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.descriptionLanguage)
        case 7:
            return self.cellForSupplierID(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.supplierID)
        case 8:
            return self.cellForSupplierName(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.supplierName)
        case 9:
            return self.cellForTaxTarifCode(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.taxTarifCode)
        case 10:
            return self.cellForMeasureUnit(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.measureUnit)
        case 11:
            return self.cellForWeightMeasure(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.weightMeasure)
        case 12:
            return self.cellForWeightUnit(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.weightUnit)
        case 13:
            return self.cellForCurrencyCode(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.currencyCode)
        case 14:
            return self.cellForPrice(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.price)
        case 15:
            return self.cellForWidth(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.width)
        case 16:
            return self.cellForDepth(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.depth)
        case 17:
            return self.cellForHeight(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.height)
        case 18:
            return self.cellForDimUnit(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.dimUnit)
        case 19:
            return self.cellForCreatedAt(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.createdAt)
        case 20:
            return self.cellForChangedAt(tableView: tableView, indexPath: indexPath, currentEntity: self.entity, property: Product.changedAt)
        default:
            return CellCreationHelper.cellForDefault(tableView: tableView, indexPath: indexPath, editingIsAllowed: self.allowsEditableCells)
        }
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 21
    }

    override func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }

    // MARK: - OData property specific cell creators

    private func cellForProductID(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.productID ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if Product.productID.isOptional || newValue != "" {
                currentEntity.productID = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForTypeCode_(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.typeCode_ ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if Product.typeCode_.isOptional || newValue != "" {
                currentEntity.typeCode_ = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForCategory(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.category ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if Product.category.isOptional || newValue != "" {
                currentEntity.category = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForName(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.name ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if Product.name.isOptional || newValue != "" {
                currentEntity.name = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForNameLanguage(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.nameLanguage {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.nameLanguage = nil
                isNewValueValid = true
            } else {
                if Product.nameLanguage.isOptional || newValue != "" {
                    currentEntity.nameLanguage = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForDescription(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.description {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.description = nil
                isNewValueValid = true
            } else {
                if Product.description.isOptional || newValue != "" {
                    currentEntity.description = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForDescriptionLanguage(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.descriptionLanguage {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.descriptionLanguage = nil
                isNewValueValid = true
            } else {
                if Product.descriptionLanguage.isOptional || newValue != "" {
                    currentEntity.descriptionLanguage = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForSupplierID(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.supplierID ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if Product.supplierID.isOptional || newValue != "" {
                currentEntity.supplierID = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForSupplierName(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.supplierName {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.supplierName = nil
                isNewValueValid = true
            } else {
                if Product.supplierName.isOptional || newValue != "" {
                    currentEntity.supplierName = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForTaxTarifCode(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = currentEntity.taxTarifCode != nil ? "\(currentEntity.taxTarifCode!)" : ""
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if let validValue = Int(newValue) {
                currentEntity.taxTarifCode = validValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForMeasureUnit(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.measureUnit ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if Product.measureUnit.isOptional || newValue != "" {
                currentEntity.measureUnit = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForWeightMeasure(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.weightMeasure {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.weightMeasure = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.weightMeasure = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForWeightUnit(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.weightUnit {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.weightUnit = nil
                isNewValueValid = true
            } else {
                if Product.weightUnit.isOptional || newValue != "" {
                    currentEntity.weightUnit = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForCurrencyCode(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        value = "\(currentEntity.currencyCode ?? "")"
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            if Product.currencyCode.isOptional || newValue != "" {
                currentEntity.currencyCode = newValue
                isNewValueValid = true
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForPrice(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.price {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.price = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.price = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForWidth(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.width {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.width = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.width = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForDepth(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.depth {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.depth = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.depth = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForHeight(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.height {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.height = nil
                isNewValueValid = true
            } else {
                if let validValue = BigDecimal.parse(newValue) {
                    currentEntity.height = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForDimUnit(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.dimUnit {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.dimUnit = nil
                isNewValueValid = true
            } else {
                if Product.dimUnit.isOptional || newValue != "" {
                    currentEntity.dimUnit = newValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForCreatedAt(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.createdAt {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.createdAt = nil
                isNewValueValid = true
            } else {
                if let validValue = LocalDateTime.parse(newValue) { // This is just a simple solution to handle UTC only
                    currentEntity.createdAt = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    private func cellForChangedAt(tableView: UITableView, indexPath: IndexPath, currentEntity: Product, property: Property) -> UITableViewCell {
        var value = ""
        if let propertyValue = currentEntity.changedAt {
            value = "\(propertyValue)"
        }
        return CellCreationHelper.cellForProperty(tableView: tableView, indexPath: indexPath, entity: self.entity, property: property, value: value, editingIsAllowed: self.allowsEditableCells, changeHandler: { (newValue: String) -> Bool in
            var isNewValueValid = false
            // The property is optional, so nil value can be accepted
            if newValue.isEmpty {
                currentEntity.changedAt = nil
                isNewValueValid = true
            } else {
                if let validValue = LocalDateTime.parse(newValue) { // This is just a simple solution to handle UTC only
                    currentEntity.changedAt = validValue
                    isNewValueValid = true
                }
            }
            self.validity[property.name] = isNewValueValid
            self.barButtonShouldBeEnabled()
            return isNewValueValid
        })
    }

    // MARK: - OData functionalities

    @objc func createEntity() {
        self.showFioriLoadingIndicator()
        self.view.endEditing(true)
        self.logger.info("Creating entity in backend.")
        self.gwsamplebasicEntities.createEntity(self.entity) { error in
            self.hideFioriLoadingIndicator()
            if let error = error {
                self.logger.error("Create entry failed. Error: \(error)", error: error)
                let alertController = UIAlertController(title: NSLocalizedString("keyErrorEntityCreationTitle", value: "Create entry failed", comment: "XTIT: Title of alert message about entity creation error."), message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: self.okTitle, style: .default))
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

    func createEntityWithDefaultValues() -> Product {
        let newEntity = Product()
        // Fill the mandatory properties with default values
        newEntity.productID = CellCreationHelper.defaultValueFor(Product.productID)
        newEntity.typeCode_ = CellCreationHelper.defaultValueFor(Product.typeCode_)
        newEntity.category = CellCreationHelper.defaultValueFor(Product.category)
        newEntity.name = CellCreationHelper.defaultValueFor(Product.name)
        newEntity.supplierID = CellCreationHelper.defaultValueFor(Product.supplierID)
        newEntity.taxTarifCode = CellCreationHelper.defaultValueFor(Product.taxTarifCode)
        newEntity.measureUnit = CellCreationHelper.defaultValueFor(Product.measureUnit)
        newEntity.currencyCode = CellCreationHelper.defaultValueFor(Product.currencyCode)

        // Key properties without default value should be invalid by default for Create scenario
        if newEntity.productID == nil || newEntity.productID!.isEmpty {
            self.validity["ProductID"] = false
        }
        self.barButtonShouldBeEnabled()
        return newEntity
    }

    @objc func updateEntity(_: AnyObject) {
        self.showFioriLoadingIndicator()
        self.view.endEditing(true)
        self.logger.info("Updating entity in backend.")
        self.gwsamplebasicEntities.updateEntity(self.entity) { error in
            self.hideFioriLoadingIndicator()
            if let error = error {
                self.logger.error("Update entry failed. Error: \(error)", error: error)
                let alertController = UIAlertController(title: NSLocalizedString("keyErrorEntityUpdateTitle", value: "Update entry failed", comment: "XTIT: Title of alert message about entity update failure."), message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: self.okTitle, style: .default))
                OperationQueue.main.addOperation({
                    // Present the alertController
                    self.present(alertController, animated: true)
                })
                return
            }
            self.logger.info("Update entry finished successfully.")
            OperationQueue.main.addOperation({
                self.dismiss(animated: true) {
                    FUIToastMessage.show(message: NSLocalizedString("keyUpdateEntityFinishedTitle", value: "Updated", comment: "XTIT: Title of alert message about successful entity update."))
                    self.entityUpdater?.entityHasChanged(self.entity)
                }
            })
        }
    }

    // MARK: - other logic, helper

    @objc func cancel() {
        OperationQueue.main.addOperation({
            self.dismiss(animated: true)
        })
    }

    // Check if all text fields are valid
    private func barButtonShouldBeEnabled() {
        let anyFieldInvalid = self.validity.values.first { field in
            return field == false
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = anyFieldInvalid == nil
    }
}

extension ProductSetDetailViewController: EntityUpdaterDelegate {
    func entityHasChanged(_ entityValue: EntityValue?) {
        if let entity = entityValue {
            let currentEntity = entity as! Product
            self.entity = currentEntity
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
}

//
//  DashboardViewController.swift
//  SapCiscoTuto
//
//  Created by Guillaume Henique on 08/08/2018.
//  Copyright © 2018 SAP. All rights reserved.
//


//  SAP Fiori for iOS Mentor
//  SAP Cloud Platform SDK for iOS Code Example
//  KPI Header
//  Copyright © 2017 SAP SE or an SAP affiliate company. All rights reserved.

import SAPFiori
import SAPOData
import SAPOfflineOData

import SAPCommon

class DashboardViewController: UITableViewController, SAPFioriLoadingIndicator, FUIBarcodeScanViewControllerDelegate{
    
    var loadingIndicator: FUILoadingIndicatorView?
    private let logger = Logger.shared(named: "DashboardViewControllerLogger")
    var boolUpdateView: Bool = false
    var idSalesOrderToShow: String?
    var salesOrderToShow: SalesOrder?
    var boolAlreadyScanned: Bool = false

    @IBOutlet var myTableView: UITableView!
    
    //var oDataModel: GWSAMPLEBASICEntitiesDataAccess?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private var gwsampleEntites: GWSAMPLEBASICEntities<OnlineODataProvider> {
        return self.appDelegate.gwsamplebasicEntities
    }
    var indexSaleOrderToShow: Int?
    var kpiHeader: FUIKPIHeader!
    var delegate: AppDelegate!
    let cellReuseIdentifier = "FUITimelineCell"
    private var salesOrderSet: [SalesOrder] = [SalesOrder]()
    private var productSet: [Product] = [Product]()
    var productToShow : Product?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initData()
        updateTable()
        initTimeLineView()
    
        NotificationCenter.default.addObserver(self, selector: #selector(pushScanner(_:)), name: Notification.Name("pushScanner"), object: nil)
        
        let updateButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh, target: self, action: #selector(updateValues(_:)))
        let scanButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: self, action: #selector(pushScanner(_:)))
        let spacer = UIBarButtonItem()
        self.navigationItem.rightBarButtonItems = [scanButton, spacer,spacer,spacer,updateButton]
        let imageView = UIImageView(image: self.resizeImage(image:#imageLiteral(resourceName: "logo"), newHeight: 35))
        self.navigationItem.titleView = imageView
        
    }
    
    func updateTable() {
        self.showFioriLoadingIndicator()
        let oq = OperationQueue()
        oq.addOperation({
            self.loadData {
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
                    // Present the alertController
                    self.present(alertController, animated: true)
                })
                return
            }
            OperationQueue.main.addOperation({
                self.tableView.reloadData()
            })
        }
    }
    
    
    func requestEntities(completionHandler: @escaping (Error?) -> Void) {  // MARK: - Data accessing Function (Odata Request)
        
        let query = DataQuery().selectAll().orderBy(SalesOrder.salesOrderID                                                                                                                                                                                                                                                                                                                                                     , SAPOData.SortOrder.descending).top(50)
        self.gwsampleEntites.fetchSalesOrderSet(matching: query) { salesOrders, error in
            guard let salesOrders = salesOrders else {
                completionHandler(error!)
                
                return
            }
            self.salesOrderSet = salesOrders
            completionHandler(nil)
            
        }
    }
    
    func initData() // KPI HEADER Initialization
    {
        do {
            
            let salesOrderCount = try Utils.fetchEntityCount(entity: GWSAMPLEBASICEntitiesMetadata.EntitySets.salesOrderSet, entities: gwsampleEntites)
            
            let kpiView1 = FUIKPIView()
            let kpiView1Metric = FUIKPIMetricItem(string: "\(salesOrderCount)")
            kpiView1.items = [kpiView1Metric]
            kpiView1.captionlabel.text = "Sales Orders"
            
            let productCount = try Utils.fetchEntityCount(entity: GWSAMPLEBASICEntitiesMetadata.EntitySets.productSet, entities : gwsampleEntites)
            let kpiView2 = FUIKPIView()
            let kpiView2Metric = FUIKPIMetricItem(string: "\(productCount)")
            kpiView2.items = [kpiView2Metric]
            kpiView2.captionlabel.text = "Products"
            
            let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.handleKpiTap2(_:)))
            kpiView2.addGestureRecognizer(tap2)
            
            let contactCount = try Utils.fetchEntityCount(entity: GWSAMPLEBASICEntitiesMetadata.EntitySets.contactSet, entities : gwsampleEntites)
            let kpiView3 = FUIKPIView()
            let kpiView3Metric = FUIKPIMetricItem(string: "\(contactCount)")
            kpiView3.items = [kpiView3Metric]
            kpiView3.captionlabel.text = "Contacts"
            
            let tap3 = UITapGestureRecognizer(target: self, action: #selector(self.handleKpiTap3(_:)))
            kpiView3.addGestureRecognizer(tap3)
            
            let partnersCount = try Utils.fetchEntityCount(entity: GWSAMPLEBASICEntitiesMetadata.EntitySets.businessPartnerSet, entities : gwsampleEntites)
            let kpiView4 = FUIKPIView()
            let kpiView4Metric = FUIKPIMetricItem(string: "\(partnersCount)")
            kpiView4.items = [kpiView4Metric]
            kpiView4.captionlabel.text = "Partners"
            
            
            kpiHeader = FUIKPIHeader(items: [kpiView2, kpiView3, kpiView4, kpiView1 ])
            
            tableView.tableHeaderView = kpiHeader
     
        } catch let error
        {
            print(error)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.salesOrderSet.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // SalesOrderTable Cells:
        
        let salesItem = self.salesOrderSet[indexPath.row]
        let timeLineCell = tableView.dequeueReusableCell(withIdentifier: FUITimelineCell.reuseIdentifier, for: indexPath) as! FUITimelineCell
        timeLineCell.timelineWidth = CGFloat(95.0)
        timeLineCell.headlineText = salesItem.customerName
        timeLineCell.subheadlineText = salesItem.salesOrderID
        timeLineCell.nodeImage = FUITimelineNode.complete
        timeLineCell.subAttributeText =  salesItem.billingStatusDescription
        timeLineCell.eventText = convertDateToTimeAgo((salesItem.createdAt)!)
        if let price = salesItem.netAmount {
            timeLineCell.subStatusText = "\(price) \(salesItem.currencyCode!)"
        }
        let tap = UITapGestureRecognizerCustom(target: self, action: #selector(self.handleSalesOrderTap(_:)))
        timeLineCell.addGestureRecognizer(tap)
        tap.id = salesItem.salesOrderID!
        tap.index = indexPath.row
        return timeLineCell
    }
    
    // initialize display settings
    func initTimeLineView(){
        tableView.register(FUITimelineCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.preferredFioriColor(forStyle: .backgroundBase)
        tableView.separatorStyle = .none
    }
    
    func convertDateToTimeAgo(_ localDate: LocalDateTime) -> String { // Date convertion to TimeToGo
        let dateFormatter = DateFormatter()
        // Ex: 2017-08-22T02:12:50.980
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = dateFormatter.date(from: localDate.toString()) {
            return date.getElapsedInterval()
        }
        //Parfois les dates n'ont pas de millisecondes...
        // Ex: 2017-08-22T02:00:00
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: localDate.toString()) {
            return date.getElapsedInterval()
        }
        return localDate.toString()
    }
    
  ///////////////////////////////////////////////////////////////////////
 // Handle Tap  BEGIN
///////////////////////////////////////////////////////////////////////
    
    @objc func handleKpiTap2(_ sender: UITapGestureRecognizer) {
        
        self.performSegue(withIdentifier: "showProducts", sender: nil)
        
    }
    @objc func handleKpiTap3(_ sender: UITapGestureRecognizer) {
        
        self.performSegue(withIdentifier: "showContacts", sender: nil)
        
    }
    
    @objc func handleSalesOrderTap(_ sender:UITapGestureRecognizerCustom) {
        self.idSalesOrderToShow = sender.id
        self.indexSaleOrderToShow = sender.index
        
        self.performSegue(withIdentifier: "showSalesOrderDetail", sender: nil)
    }
    
    @objc func updateValues(_ sender: UITapGestureRecognizer) {
        self.boolUpdateView = true
        self.viewDidLoad()
        self.boolUpdateView = false
    }
    
  ///////////////////////////////////////////////////////////////////////
 // Handle Tap  END
///////////////////////////////////////////////////////////////////////
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        
        if segue.identifier == "showSalesOrderDetail" {
            
            let detailViewController = segue.destination as! ItemLinesViewController
            // detailViewController.navigationItem.leftItemsSupplementBackButton = true
            
            detailViewController.setIDSalesOrder(id: self.idSalesOrderToShow!)
            detailViewController.salesOrderToShow = salesOrderSet[self.indexSaleOrderToShow!]
            
        }
        else if segue.identifier == "showProductDetails" {
            let view = segue.destination as! DetailProductViewController
            if let prod = self.productToShow {
                view.currentIndex = 0
                view.setProductSet(product: prod)
            }
            else {
                //xxx error product is empty, can't show product view with empty entity
                print("error product is empty")
            }
        }
        else if segue.identifier == "showSalesOrderDetailScanner" {
            let view = segue.destination as! ItemLinesViewController
            if let facture = self.salesOrderToShow {
                view.salesOrderToShow = facture
                view.setIDSalesOrder(id: facture.salesOrderID!)
                
            } else {
                //xxx error product is empty, can't show product view with empty entity
                print("error product is empty")
            }
        }
        
    }
    
    

    func resizeImage(image: UIImage, newHeight: CGFloat) -> UIImage {
        
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        
        
        image.draw(in: CGRect(x: 0, y: 0,width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    ////////////////////////////////////
    //QRCode - Data Part
    ////////////////////////////////////
    func requestEntities()
    {
        do{
            
            let queryProducts = DataQuery().selectAll().orderBy(Product.supplierID, SAPOData.SortOrder.ascending).top(20)
            self.productSet = try self.gwsampleEntites.fetchProductSet(matching: queryProducts)
            
            
            
        } catch let error
        {
            print(error)
        }
        
    }
    ////////////////////////////////////
    //QRCode - End Data Part
    ////////////////////////////////////
    
    
    
    ////////////////////////////////////
    // QR CODE part
    ////////////////////////////////////
    @objc func pushScanner(_ sender: Any?) {
        
        // https://experience.sap.com/fiori-design-ios/article/scan-view/
        
        
        self.boolAlreadyScanned = false
        
        let scanViewController = FUIBarcodeScanViewController.createInstanceFromStoryboard()
        
        //        scanViewController.barcodeScanner.scanMode = .qr
        //        scanViewController.barcodeScanner.indicatorBorderColor = UIColor.red.cgColor
        //        scanViewController.barcodeScanner.indicatorBorderWidth = 20
        //        scanViewController.barcodeScanner.promptMessage = "Scan A QR Code"
        //        scanViewController.barcodeScanner.scanResultTransformer = { s in
        //            return "transformed"
        //        }
        scanViewController.delegate = self
        
        let navController = UINavigationController(rootViewController: scanViewController)
        self.navigationController?.present(navController, animated: true, completion: nil)
    }
    
    func barcodeScanViewController(_ barcodeScanViewController: FUIBarcodeScanViewController, didReceiveScanResult scanResult: FUIBarcodeScanResult?) {
        print("scan result: \(String(describing: scanResult?.scanResultString))")
        
        requestEntities()
        
        if(!boolAlreadyScanned){
            
            if let scanRes = scanResult?.scanResultString {
                if let scanDict = convertToDictionary(text: scanRes) {
                    //Here, we have a dict that we got from our JSON QR Code
                    //We expect it to be {"proxyClasses":"id"}
                    //Example : {"Product":"id"}
                    //Try to use the CollectionType enum ?
                    boolAlreadyScanned = true
                    let pKey = scanDict.first?.key ?? "empty"
                    switch pKey {
                    case "Product":
                        let scanEntityId = scanDict.first?.value ?? ""//This is a string
                        
                        if let found = self.productSet.first(where: {$0.productID == scanEntityId}) {
                            FUIToastMessage.show(message: "Success, loading product : \(scanEntityId)", withDuration: 1)
                            barcodeScanViewController.dismiss(animated: true, completion: nil)
                            self.productToShow = found
                            self.performSegue(withIdentifier: "showProductDetails", sender: nil)
                        } else {
                            FUIToastMessage.show(message: "Product ID : \(scanEntityId) not found in catalog", withDuration: 3)
                        }
                    case "SalesOrder":
                        let scanEntityId = scanDict.first?.value ?? ""//This is a string
                        if let found = self.salesOrderSet.first(where: {$0.salesOrderID == scanEntityId}) {
                            FUIToastMessage.show(message: "Success, loading sales order : \(scanEntityId)", withDuration: 1)
                            barcodeScanViewController.dismiss(animated: true, completion: nil)
                            self.salesOrderToShow = found
                            self.performSegue(withIdentifier: "showSalesOrderDetailScanner", sender: nil)
                        } else {
                            FUIToastMessage.show(message: "Sales Order ID : \(scanEntityId) not found in catalog", withDuration: 3)
                        }
                    default:
                        FUIToastMessage.show(message: "\(pKey) n'est pas une catégorie valide", withDuration: 3)
                    }
                }
                else {
                    FUIToastMessage.show(message: "Wrong QR format : {\"Product\":\"id\"} ", withDuration: 3)
                }
            }
            else {
                FUIToastMessage.show(message: "Wrong QR format : {\"Product\":\"id\"} ", withDuration: 3)        }
            
        }
    }
    
    //https://stackoverflow.com/questions/30480672/how-to-convert-a-json-string-to-a-dictionary
    func convertToDictionary(text: String) -> [String: String]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    ////////////////////////////////////
    //end QR CODE part
    ////////////////////////////////////
}

// Date Format
extension Date {
    
    func getElapsedInterval() -> String {
        
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: Date())
        
        if let year = interval.year, year > 0 {
            return year == 1 ? "\(year)" + " " + "year ago" :
                "\(year)" + " " + "years"
        } else if let month = interval.month, month > 0 {
            return month == 1 ? "\(month)" + " " + "month ago" :
                "\(month)" + " " + "months ago"
        } else if let day = interval.day, day > 0 {
            return day == 1 ? "\(day)" + " " + "day ago" :
                "\(day)" + " " + "days ago"
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? "\(hour)" + " " + "hour ago" :
                "\(hour)" + " " + "hours ago"
        } else if let minute = interval.minute, minute > 0 {
            return minute == 1 ? "\(minute)" + " " + "minute ago" :
                "\(minute)" + " " + "minutes ago"
        } else {
            return "a moment ago"
            
        }
        
    }
}



import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage
import SwiftyJSON

class VCMain: UIViewController , UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viewContainerHeightConstrain: NSLayoutConstraint!
    @IBOutlet weak var viewContainer: UIView!
    
    var locationManager = CLLocationManager()
    let authorisationStatus = CLLocationManager.authorizationStatus()
    let regionRadius : Double = 1000
    var spiner : UIActivityIndicatorView?
    var lblProgress : UILabel?
    var collectionView : UICollectionView?
    var collectionViewLowLayout  = UICollectionViewFlowLayout()
    var arrayImagesURL = [String]()
    var arrImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        locationManager.delegate = self
        self.ConfigreLocationServices()
        self.doubleClick()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLowLayout)
     
        collectionView?.register(CVCPhotos.self, forCellWithReuseIdentifier: "cell")
        self.collectionView?.delegate = self
        self.collectionView?.dataSource  = self
        self.collectionView?.backgroundColor = UIColor.orange
        
        // register the preview
        registerForPreviewing(with: self, sourceView: collectionView!)
        
    }
    
    //MARK: Actions
    //Click for get Current Location on center of the map
    @IBAction func btnCurrentLocationClick(_ sender: Any) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            self.centerUserLocation()
        }
    }
    
    //MARK:GestureRecognizer Methods
    // Show Annotation when Doubel Click on map
    func doubleClick(){
        
        let doubleTap  = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.delegate = self
        doubleTap.numberOfTapsRequired  = 2
        view.addGestureRecognizer(doubleTap)
    }
    
    // Swip down to close the view conatiner
    func swipDown(){
        let swapDown  = UISwipeGestureRecognizer(target: self, action: #selector(closeViewContainer))
        swapDown.direction = .down
        viewContainer.addGestureRecognizer(swapDown)
    }
    
    // Remove Annotation When click for another Place
    func removeAnnotation(){
        for annotaion in mapView.annotations{
            mapView.removeAnnotation(annotaion)
        }
    }
    
    // open view that Have CollectionView that has the Images
    func openViewConatainer(){
        self.viewContainer?.addSubview(self.collectionView!)
        self.viewContainerHeightConstrain.constant  = 300
        UIView.animate(withDuration: 2) {
            self.view.layoutIfNeeded()
        }
    }
    
    // Add the Spiner
    func addSpiner(){
        spiner = UIActivityIndicatorView()
        spiner?.center = CGPoint(x: viewContainer.frame.width / 2 , y: 150)
        spiner?.style = .whiteLarge
        spiner?.color = UIColor.black
        spiner?.startAnimating()
        viewContainer.addSubview(spiner!)
    }
    
    func removeSpiner(){
        if spiner != nil{
            spiner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel (){
        lblProgress = UILabel(frame: CGRect(x: (viewContainer.bounds.width / 2) - (100) , y: 175, width: 200, height: 40))
        lblProgress?.textAlignment = .center
        lblProgress?.textColor  = UIColor.black
        lblProgress?.font = UIFont(name: "Avenir Next", size: 14)
        collectionView?.addSubview(lblProgress!)
    }
    
    func removeProgressLabel(){
        if lblProgress != nil {
            lblProgress?.removeFromSuperview()
        }
    }
    
    // get the Url when click of any annotation on the map
    func retriveURLS(annotation :DropPin , handler : @escaping(_ status : Bool)->()){
        
        arrayImagesURL = []
        Alamofire.request(flickrUrl(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            if response.error == nil {
                guard let data = response.data else{return}
                let json = JSON(data)
                for item in json["photos"]["photo"].arrayValue{
                    
                    let postUrl = "https://farm\(item["farm"].stringValue).staticflickr.com/\(item["server"].stringValue)/\(item["id"].stringValue)_\(item["secret"].stringValue)_h_d.jpg"
                    self.arrayImagesURL.append(postUrl)
                }
                handler(true)
            }
            else{
                handler(false)
            }
        }
    }
    
    func retriveImages(handler :@escaping (_ status : Bool)->() ){
        arrImages = []
        
        for url in arrayImagesURL{
            Alamofire.request(url).responseImage { (response) in
                if response.error == nil {
                    guard let image = response.result.value else{return}
                    self.arrImages.append(image)
                    self.lblProgress?.text = "\(self.arrImages.count)/40 IMAGES DOWNLOADED"
                    if self.arrayImagesURL.count == self.arrImages.count{
                        handler(true)
                    }
                }
                else{
                    handler(false)
                }
            }
        }
    }
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
    
    //MARK: methods objective c
    @objc func dropPin (sender : UITapGestureRecognizer){
        self.cancelAllSessions()
        arrayImagesURL = []
        arrImages = []
        self.collectionView?.reloadData()
        self.openViewConatainer()
        
        self.removeAnnotation() ; self.removeSpiner() ; self.removeProgressLabel()
        self.swipDown()
        self.addProgressLabel()
        self.addSpiner()
        
        let touchPoint  = sender.location(in: mapView)
        let touchCoordinate  = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DropPin(coordinate: touchCoordinate, indentifier: "pin")
        mapView.addAnnotation(annotation)
        
        // Call func for get the url when click on the map
        retriveURLS(annotation: annotation) { (finish) in
            if finish {
                self.retriveImages(handler: { (finish) in
                    if finish{
                        self.removeSpiner()
                        self.removeProgressLabel()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
        let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRadius * 2, longitudinalMeters: regionRadius * 2 )
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func closeViewContainer(){
    self.cancelAllSessions()
        
        self.viewContainerHeightConstrain.constant  = 1
        UIView.animate(withDuration: 2, animations: {
            self.view.layoutIfNeeded()
        }) { (true) in
            self.arrayImagesURL = []
            self.arrImages = []
            self.collectionView?.reloadData()
        }
    }
}

extension VCMain: MKMapViewDelegate{
    func centerUserLocation(){
        guard  let coordinate = locationManager.location?.coordinate else {return}
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: self.regionRadius * 2.0, longitudinalMeters: self.regionRadius * 2.0)
        self.mapView.setRegion(region, animated: true)
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pinAnnotation.tintColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
        pinAnnotation.animatesDrop = true
        
        return pinAnnotation
    }
    
    
    
}

//MARK: Location Manager Delegate
extension VCMain: CLLocationManagerDelegate{
    func ConfigreLocationServices(){
        if authorisationStatus == .notDetermined{
            locationManager.requestAlwaysAuthorization()
        }
        else{ return }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.centerUserLocation()
    }
}

extension VCMain : UICollectionViewDataSource , UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CVCPhotos{
            let image = UIImageView(image: arrImages[indexPath.row])
            cell.addSubview(image)
            return cell
        }
        else{
            return UICollectionViewCell()
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vcImage  = storyboard?.instantiateViewController(withIdentifier: "VCImage") as? VCImage{
            vcImage.setImage(image: arrImages[indexPath.row])
            present(vcImage, animated: true, completion: nil)
            
        }
    }
    
}

extension VCMain : UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = self.collectionView?.indexPathForItem(at: location) , let cell = self.collectionView?.cellForItem(at: indexPath) else {return nil}
        
        guard let popImage = storyboard?.instantiateViewController(withIdentifier: "VCImage") as? VCImage else {return nil}
        popImage.setImage(image: arrImages[indexPath.row])
        
        previewingContext.sourceRect = cell.contentView.frame
        return popImage
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
            show(viewControllerToCommit, sender: self)
    }
}

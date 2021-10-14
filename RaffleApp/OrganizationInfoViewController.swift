//
//  OrganizationInfoViewController.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 21/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit
import MapKit

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 1000) {
        let coordinateRegion = MKCoordinateRegion(
        center: location.coordinate,
        latitudinalMeters: regionRadius,
        longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

class OrganizationInfoViewController: UIViewController {
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "MyDatabase")
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var raffleNumberLabel: UILabel!
    let orgLocation = (lati: -41.401881, logi: 147.126236)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        initMap()
        raffleNumberLabel.text = String(database.selectAllRaffles().count)
    }
    
    func initMap() {
        let initialLocation = CLLocation(latitude: orgLocation.lati, longitude: orgLocation.logi)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: orgLocation.lati, longitude: orgLocation.logi)
        mapView.centerToLocation(initialLocation)
        mapView.addAnnotation(annotation)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

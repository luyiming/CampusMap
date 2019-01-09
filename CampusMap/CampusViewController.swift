//
//  CampusViewController.swift
//  CampusMap
//
//  Created by Chun on 2018/11/26.
//  Copyright © 2018 Nemoworks. All rights reserved.
//

import UIKit
import MapKit


class CampusViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var campus = Campus(filename: "Campus")
    var selectedOptions : [MapOptionsType] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let latDelta = campus.overlayTopLeftCoordinate.latitude - campus.overlayBottomRightCoordinate.latitude
        
        // Think of a span as a tv size, measure from one corner to another
        let span = MKCoordinateSpan.init(latitudeDelta: fabs(latDelta), longitudeDelta: 0.0)
        let region = MKCoordinateRegion.init(center: campus.midCoordinate, span: span)
        
        mapView.region = region
        
        print("view did load")
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as? MapOptionsViewController)?.selectedOptions = selectedOptions
    }
    
    
    // MARK: Helper methods
    func loadSelectedOptions() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        for option in selectedOptions {
            switch (option) {
            case .mapPOIs:
                self.addPOIs()
            case .mapBoundary:
                self.addBoundary()
            case .mapLibraryToCSRoute:
                self.addLibraryToCSRoute()
            case .mapGymToRestraurantRoute:
                self.addGymToRestraurantRoute()
            }
        }
    }
    
    @IBAction func closeOptions(_ exitSegue: UIStoryboardSegue) {
        guard let vc = exitSegue.source as? MapOptionsViewController else { return }
        selectedOptions = vc.selectedOptions
        loadSelectedOptions()
    }
    
    func addBoundary() {
        mapView.addOverlay(MKPolygon(coordinates: campus.boundary, count: campus.boundary.count))
    }
    
    func addPOIs() {
        guard let pois = Campus.plist("CampusPOI") as? [[String : String]] else { return }
        
        for poi in pois {
            let coordinate = Campus.parseCoord(dict: poi, fieldName: "location")
            let title = poi["name"] ?? ""
            let typeRawValue = Int(poi["type"] ?? "0") ?? 0
            let type = POIType(rawValue: typeRawValue) ?? .misc
            let subtitle = poi["subtitle"] ?? ""
            let annotation = POIAnnotation(coordinate: coordinate, title: title, subtitle: subtitle, type: type)
            mapView.addAnnotation(annotation)
        }
    }
    
    func addLibraryToCSRoute() {
        guard let points = Campus.plist("LibraryToCSRoute") as? [String] else { return }
        
        let cgPoints = points.map { NSCoder.cgPoint(for: $0) }
        let coords = cgPoints.map { CLLocationCoordinate2DMake(CLLocationDegrees($0.x), CLLocationDegrees($0.y)) }
        let routeLine = MKPolyline(coordinates: coords, count: coords.count)
        
        mapView.addOverlay(routeLine)
    }
    
    func addGymToRestraurantRoute() {
        guard let points = Campus.plist("GymToRestraurantRoute") as? [String] else { return }
        
        let cgPoints = points.map { NSCoder.cgPoint(for: $0) }
        let coords = cgPoints.map { CLLocationCoordinate2DMake(CLLocationDegrees($0.x), CLLocationDegrees($0.y)) }
        let routeLine = MKPolyline(coordinates: coords, count: coords.count)
        
        mapView.addOverlay(routeLine)
    }
    
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
        mapView.mapType = MKMapType.init(rawValue: UInt(sender.selectedSegmentIndex)) ?? .standard
    }
}


// MARK: - MKMapViewDelegate
extension CampusViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.magenta
            lineView.lineWidth = CGFloat(2.0)
            return lineView
        } else if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.strokeColor = UIColor.blue
            polygonView.lineWidth = CGFloat(3.0)
            return polygonView
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = POIAnnotationView(annotation: annotation, reuseIdentifier: "POI")
        annotationView.canShowCallout = true
        return annotationView
    }
}

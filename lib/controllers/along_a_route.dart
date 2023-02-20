import 'dart:math';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart' as here;
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:searches_demo/controllers/search_result_metadata.dart';
import 'package:searches_demo/values/colors.dart';

import 'add_poi_markers.dart';
import 'messages.dart';

class AlongRoute {
  AddMarkers addMarkers = AddMarkers();

  Future<void> setRoute(Point2D touchPoint, HereMapController hereMapController,
      List<MapPolyline> mapPolylines, here.RoutingEngine routingEngine,
      SearchEngine searchEngine, List<MapMarker> mapMarkerList) async {

     if(mapPolylines.isNotEmpty) {
       hereMapController.mapScene.removeMapPolyline(mapPolylines.first);
       mapPolylines.clear();
       hereMapController.mapScene.removeMapMarkers(mapMarkerList);
     }

    GeoCoordinates? startGeoCoordinates =
    hereMapController.viewToGeoCoordinates(touchPoint);
    GeoCoordinates destinationGeoCoordinates = _createRandomGeoCoordinatesInViewport(startGeoCoordinates!,
        hereMapController, searchEngine);
    var startWaypoint = Waypoint.withDefaults(startGeoCoordinates);
    var destinationWaypoint = Waypoint.withDefaults(destinationGeoCoordinates);

    List<Waypoint> waypoints = [startWaypoint, destinationWaypoint];

    routingEngine.calculateCarRoute(waypoints, CarOptions.withDefaults(),
            (RoutingError? routingError, List<here.Route>? routeList) async {
          if (routingError == null) {
            here.Route route = routeList!.first;
            _showRouteOnMap(route, hereMapController, mapPolylines, searchEngine, mapMarkerList);
          } else {
            var error = routingError.toString();
            print('Error while calculating a route: $error');
          }
        });

  }

  GeoCoordinates _createRandomGeoCoordinatesInViewport(GeoCoordinates startGeoCoordinates,
      HereMapController hereMapController, SearchEngine searchEngine) {
    GeoBox? geoBox = hereMapController.camera.boundingBox;
    if (geoBox == null) {
      // Happens only when map is not fully covering the viewport.
      return GeoCoordinates(startGeoCoordinates.latitude - 1, startGeoCoordinates.longitude - 1);
    }

    GeoCoordinates northEast = geoBox.northEastCorner;
    GeoCoordinates southWest = geoBox.southWestCorner;

    double minLat = southWest.latitude;
    double maxLat = northEast.latitude;
    double lat = _getRandom(minLat, maxLat);

    double minLon = southWest.longitude;
    double maxLon = northEast.longitude;
    double lon = _getRandom(minLon, maxLon);

    return GeoCoordinates(lat, lon);
  }

  double _getRandom(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  _showRouteOnMap(here.Route route, HereMapController hereMapController,
      List<MapPolyline> mapPolylines, SearchEngine searchEngine,
      List<MapMarker> mapMarkerList) {
    // Show route as polyline.
    GeoPolyline routeGeoPolyline = route.geometry;

    double widthInPixels = 20;
    MapPolyline routeMapPolyline = MapPolyline(routeGeoPolyline, widthInPixels, general_color);

    hereMapController.mapScene.addMapPolyline(routeMapPolyline);
    mapPolylines.add(routeMapPolyline);

    _searchAlongARoute(route, hereMapController, searchEngine, mapMarkerList);
  }

  // Perform a search for charging stations along the found route.
  void _searchAlongARoute(here.Route route, HereMapController hereMapController,
      SearchEngine searchEngine, List<MapMarker> mapMarkerList) {
    var searchText = 'Park';

    GeoCorridor routeCorridor = GeoCorridor.withPolyline(route.geometry.vertices);
    TextQuery textQuery = TextQuery.withCorridorAreaAndAreaCenter(
        searchText, routeCorridor, hereMapController.camera.state.targetCoordinates);

    int maxItems = 30;
    SearchOptions searchOptions = SearchOptions();
    searchOptions.languageCode = LanguageCode.enUs;
    searchOptions.maxItems = maxItems;

    searchEngine.searchByText(textQuery, searchOptions, (SearchError? searchError, List<Place>? items) {
      if (searchError != null) {
        if (searchError == SearchError.polylineTooLong) {
          print("Search: Route too long.");
        } else {
          print("Search: No '$searchText' found along the route. Error: $searchError");
        }
        return;
      }

      for (Place place in items!) {
        Metadata metadata = Metadata();
        metadata.setCustomValue(
            "key_search_result", SearchResultMetadata(place));
        print("${place.title}, ${place.address.addressText}");
        addMarkers.addPoiMapMarker(hereMapController, place.geoCoordinates, metadata, 4, mapMarkerList);
      }

      Messages().toastMessage("$searchText/s obtained: ${items.length}. See console for details");
    });
  }
}
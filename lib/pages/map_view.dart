import 'dart:async';

import 'package:flutter/material.dart';
import 'package:here_sdk/consent.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/location.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:searches_demo/controllers/along_a_route.dart';
import 'package:searches_demo/controllers/geocode_address.dart';
import 'package:searches_demo/controllers/messages.dart';
import 'package:searches_demo/controllers/reverse_geocode.dart';
import 'package:searches_demo/models/add_location.dart';
import 'dart:io' show Platform;

import 'package:searches_demo/values/colors.dart';
import 'package:searches_demo/models/add_suggestions.dart';
import 'package:searches_demo/controllers/find_places.dart';
import 'package:searches_demo/controllers/get_auto_suggestions.dart';
import 'package:searches_demo/values/strings.dart';

class MyMapViewPage extends StatefulWidget {
  const MyMapViewPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyMapViewPage> createState() => _MyMapViewPageState();
}

class _MyMapViewPageState extends State<MyMapViewPage>
    with WidgetsBindingObserver
    implements LocationListener, LocationStatusListener {
  HereMapController? _hereMapController;

  final ConsentEngine _consentEngine = ConsentEngine();
  final LocationEngine _locationEngine = LocationEngine();
  late SearchEngine _searchEngine;
  final RoutingEngine _routingEngine = RoutingEngine();
  late Location _location;
  final double _distanceToEarthInMeters = 8000;
  final GeoCoordinates _defaultCoordinates =
      GeoCoordinates(20.97537, -89.61696);

  final _searchPlacesController = TextEditingController();
  final List<MapMarker> _mapMarkerList = [];
  int _selectedIndex = 0;

  final List<AddSuggestion> _suggestions = [];
  final List<AddLocation> _locations = [];
  final List<MapPolyline> _mapPolylines = [];

  GeoCoordinates? _valueSuggestion;

  bool _needSearch = false;

  String titlePage = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() => titlePage = '${widget.title} - Places');
  }

  @override
  void onFeaturesNotAvailable(List<LocationFeature> features) {
    for (var feature in features) {
      print("Feature not available: " + feature.toString());
    }
  }

  @override
  void onLocationUpdated(Location location) {
    _updateMyLocationOnMap(location);
  }

  @override
  void onStatusChanged(LocationEngineStatus locationEngineStatus) {
    setState(() {});
  }

  @override
  void release() {
    // TODO: implement release
  }

  @override
  void dispose() {
    _searchPlacesController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _clearAll(index);
    switch (index) {
      case 0:
        setState(() => titlePage = '${widget.title} - $places');
        Messages().toastMessage(placesDescription);
        break;
      case 1:
        setState(() => titlePage = '${widget.title} - $autoSuggestions');
        Messages().toastMessage(autoSuggestDescription);
        break;
      case 2:
        setState(() => titlePage = '${widget.title} - $revGeocode');
        Messages().toastMessage(revGeoDescription);
        break;
      case 3:
        setState(() => titlePage = '${widget.title} - $geocode');
        Messages().toastMessage(geoDescription);
        break;
      case 4:
        setState(() => titlePage = '${widget.title} - $alongRoute');
        Messages().toastMessage(alongRouteDescription);
        break;
    }
  }

  final FindPlaces _findPlaces = FindPlaces();
  final GetAutosuggestions _getAutosuggestions = GetAutosuggestions();
  final GeocodeAddress _geocodeAddress = GeocodeAddress();
  final ReverseGeocode _reverseGeocode = ReverseGeocode();
  final AlongRoute _alongRoute = AlongRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            titlePage,
            style: const TextStyle(color: general_color),
          ),
          backgroundColor: general_background_color,
        ),
        body: Center(
          child: Stack(
            children: [
              HereMap(onMapCreated: _onMapCreated),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _selectedIndex == 2 || _selectedIndex == 4
                      ? Container(
                          decoration: BoxDecoration(
                            color: general_background_color,
                            border: Border.all(
                                color: subgeneral_color, // set border color
                                width: 2.0), // set border width
                            borderRadius: BorderRadius.circular(
                                15.0), // set rounded corner radius
                          ),
                          margin: const EdgeInsets.all(10),
                          width: MediaQuery.of(context).size.width * 0.80,
                          child: ListTile(
                            leading: const Icon(
                              Icons.info,
                              color: description_color,
                            ),
                            contentPadding:
                                const EdgeInsets.fromLTRB(10.0, 5.0, 0.0, 10.0),
                            title: Transform(
                              transform:
                                  Matrix4.translationValues(-16, 0.0, 0.0),
                              child: const Text(
                                tapMessage,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: general_color,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.black, // set border color
                                width: 2.0), // set border width
                            borderRadius: BorderRadius.circular(
                                15.0), // set rounded corner radius
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                          margin: const EdgeInsets.all(20),
                          width: MediaQuery.of(context).size.width * 0.90,
                          child: TextField(
                            controller: _searchPlacesController,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(12.0),
                              suffixIcon: const Icon(Icons.search),
                              //label: Text('Search box'),
                              hintText: _selectedIndex == 0
                                  ? placeHint
                                  : _selectedIndex == 1
                                      ? autoSuggestHint
                                      : _selectedIndex == 3
                                          ? geocodeHint
                                          : '',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (enter) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            onChanged: (value) async {
                              _needSearch == false
                                  ? setState(() => _needSearch = !_needSearch)
                                  : null;

                              _selectedIndex == 0
                                  ? await _clearMap().whenComplete(() {
                                      _findPlaces
                                          .searchPlaces(
                                              _searchPlacesController,
                                              _hereMapController!,
                                              _location,
                                              _distanceToEarthInMeters,
                                              _needSearch,
                                              _searchEngine,
                                              _selectedIndex,
                                              _mapMarkerList,
                                              _suggestions)
                                          .whenComplete(() {
                                        setState(() => _needSearch = false);
                                      });
                                    })
                                  : _selectedIndex == 1
                                      ? await _clearMap().whenComplete(() {
                                          _getAutosuggestions
                                              .searchAutoSuggestion(
                                                  _hereMapController!,
                                                  _needSearch,
                                                  _searchEngine,
                                                  _searchPlacesController,
                                                  _suggestions,
                                                  _selectedIndex,
                                                  _mapMarkerList);
                                        })
                                      : _selectedIndex == 3
                                          ? await _clearMap().whenComplete(() {
                                              _geocodeAddress.searchLocations(
                                                  _hereMapController!,
                                                  _searchPlacesController,
                                                  _location.coordinates,
                                                  _searchEngine,
                                                  _locations,
                                                  _selectedIndex,
                                                  _mapMarkerList);
                                            })
                                          : null;

                            },
                            onEditingComplete: () {
                            },
                            onTap: () {
                              _searchPlacesController.text = '';
                              _clearMap();
                            },
                          ),
                        ),
                  _suggestions.isNotEmpty || _locations.isNotEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.black, // set border color
                                width: 2.0), // set border width
                            borderRadius: BorderRadius.circular(
                                15.0), // set rounded corner radius
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                          width: MediaQuery.of(context).size.width * 0.90,
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                            value: _valueSuggestion,
                            isDense: false,
                            isExpanded: true,
                            items: _suggestions.isNotEmpty
                                ? _suggestions.map((value) {
                                    return DropdownMenuItem(
                                      value: value.coordinates,
                                      child: Text(value.title),
                                    );
                                  }).toList()
                                : _locations.map((value) {
                                    return DropdownMenuItem(
                                      value: value.coordinates,
                                      child: Text(value.title),
                                    );
                                  }).toList(),
                            onChanged:
                                (GeoCoordinates? seeOtherGeoCoordinates) async {
                              // do other stuff with _category

                              setState(() {
                                _valueSuggestion = seeOtherGeoCoordinates;
                              });

                              _hereMapController!.camera
                                  .lookAtPointWithDistance(_valueSuggestion!,
                                      _distanceToEarthInMeters);
                            },
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                          )),
                        )
                      : Container(),
                ],
              )
            ],
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
        extendBody: true,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 15.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: const [
              BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BottomNavigationBar(
              iconSize: 26,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.place),
                  label: places,
                  backgroundColor: general_background_color,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.not_listed_location),
                  label: autoSuggestions,
                  backgroundColor: general_background_color,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.youtube_searched_for),
                  label: revGeocode,
                  backgroundColor: general_background_color,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.terrain),
                  label: geocode,
                  backgroundColor: general_background_color,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions),
                  label: alongRoute,
                  backgroundColor: general_background_color,
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: general_color,
              unselectedItemColor: description_color,
              backgroundColor: general_background_color,
              onTap: _onItemTapped,
            ),
          ),
        ));
  }

  void _onMapCreated(HereMapController hereMapController) {
    _requestPermissions().whenComplete(() {
      _hereMapController = hereMapController;
      hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
          (MapError? error) {
        if (error != null) {
          print('Map scene not loaded. MapError: ${error.toString()}');
          return;
        }

        try {
          _searchEngine = SearchEngine();

          _setTapGestureHandler();
        } on InstantiationException {
          throw Exception("Initialization of SearchEngine failed.");
        }
      });
    });
  }

  Future<void> _requestPermissions() async {
    Permission.location.request().then((status) {
      if (status != PermissionStatus.granted) {
        print("Location permission is needed for this example.");
        Navigator.pop(context);
      } else if (Platform.isAndroid) {
        Permission.activityRecognition
            .request()
            .then((_) => _ensureUserConsentRequested());
      } else {
        // A user consent request is not required on iOS.
        //_updateConsentInfo();
        _startLocating();
      }
    });
  }

  Future<void> _ensureUserConsentRequested() async {
    // Check if user consent has been handled.
    if (_consentEngine.userConsentState == ConsentUserReply.notHandled) {
      // Show dialog.
      await _consentEngine
          .requestUserConsent(context);

      _startLocating();
    } else {
      _startLocating();
    }
  }

  void _startLocating() {
    if (_locationEngine.lastKnownLocation != null) {
      _location = _locationEngine.lastKnownLocation!;

      print("Last known location: " +
          _location.coordinates.latitude.toString() +
          ", " +
          _location.coordinates.longitude.toString());
    } else {
      _location = Location.withCoordinates(_defaultCoordinates);
    }

    _addMyLocationToMap(_location);

    _locationEngine.addLocationListener(this);
    _locationEngine.addLocationStatusListener(this);
    _locationEngine.startWithLocationAccuracy(LocationAccuracy.bestAvailable);
  }

  void _addMyLocationToMap(Location myLocation) {
    _hereMapController?.camera.lookAtPointWithDistance(
      myLocation.coordinates,
      _distanceToEarthInMeters,
    );

    // Update state's location.
    setState(() {
      _location = myLocation;
    });
  }

  void _updateMyLocationOnMap(Location myLocation) {
    if (_location.coordinates == myLocation.coordinates) {
      return;
    } else {
      // Point camera at given location.
      _hereMapController!.camera.lookAtPoint(myLocation.coordinates);

      // Update state's location.
      setState(() {
        _location = myLocation;
      });
    }
  }

  void _setTapGestureHandler() async {
    _hereMapController!.gestures.tapListener =
        TapListener((Point2D touchPoint) async {
      //_selectedIndex <= 1 ? FocusManager.instance.primaryFocus?.unfocus() : setMarker(touchPoint);
      if (_selectedIndex <= 1 || _selectedIndex == 3) {
        FocusManager.instance.primaryFocus?.unfocus();
      } else {
        if (_selectedIndex == 2) {
          Messages().toastMessage("Getting information");
          await _reverseGeocode.setMarker(
              touchPoint, _hereMapController!, _searchEngine, context);
        } else {
          await _alongRoute.setRoute(touchPoint, _hereMapController!,
              _mapPolylines, _routingEngine, _searchEngine, _mapMarkerList);
        }
      }
    });
  }

  Future<void> _clearMap() async {
    /*for (var mapMarker in _mapMarkerList) {
      _hereMapController!.mapScene.removeMapMarker(mapMarker);
    }*/
    _hereMapController!.mapScene.removeMapMarkers(_mapMarkerList);
    setState(() {
      _mapMarkerList.clear();
      _valueSuggestion = null;
      _suggestions.clear();
      _locations.clear();
      _mapPolylines.isNotEmpty
          ? _hereMapController!.mapScene.removeMapPolyline(_mapPolylines[0])
          : null;
      _mapPolylines.clear();
    });
    _hereMapController!.camera
        .lookAtPointWithDistance(_location.coordinates, _distanceToEarthInMeters);
  }

  void _clearAll(index) {
    setState(() {
      _selectedIndex = index;
      _searchPlacesController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      _clearMap();
    });
  }
}

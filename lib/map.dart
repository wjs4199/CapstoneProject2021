import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'src/locations.dart' as locations;
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/src/enums/location_accuracy.dart';

var latitude;
var longitude;

class MapPage extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<MapPage> {
  Set<Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('id-1'),
          // position: LatLng(46.493882, 30.683254599999998)));
          position: LatLng(37.4219983, -122.084)));
    });
  }

  // var locationMessageLat;
  // var locationMessageLong;

  Future<Position> getCurrentLocation() async {
    var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    var lastPosition = await Geolocator.getLastKnownPosition();
    print(lastPosition);
    // var locationLat = position.latitude;
    // var locationLong = position.longitude;
    print(position);
    // setState(() {
    //   // locationMessage = "$locationLat, $locationLong";
    //   locationMessageLat = "$locationLat";
    //   locationMessageLong = "$locationLong";
    // });
    return position;
  }

  Future<Position> getLocation() async {
    var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    return position;
  }

  @override
  Widget build(BuildContext context) {
    // Position currentPosition = getLocation();
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Google Map'),
            backgroundColor: Colors.cyan,
          ),
          // body: GoogleMap(
          //   onMapCreated: _onMapCreated,
          //   markers: _markers,
          //   initialCameraPosition: CameraPosition(
          //     zoom: 15,
          //     target: LatLng(double.parse(locationMessageLat),
          //         double.parse(locationMessageLong)),
          //   ),
          // ),
          body: FutureBuilder(
              future: getCurrentLocation(),
              builder: (BuildContext context,
                  AsyncSnapshot<Position> currentPosition) {
                if (currentPosition.hasData) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: GoogleMap(
                      // onMapCreated: _onMapCreated,
                      // markers: _markers,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(currentPosition.data.latitude,
                            currentPosition.data.longitude),
                        zoom: 18,
                      ),
                    ),
                  );
                }
                return Center(child: CircularProgressIndicator());
              })),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:weather_app/components/weather_model.dart';

class WeatherComponent extends StatefulWidget {
  const WeatherComponent({Key? key}) : super(key: key);

  @override
  State<WeatherComponent> createState() => _WeatherComponentState();
}

class _WeatherComponentState extends State<WeatherComponent> {
  Position? _currentPosition;
  String? _currentAddress;

  var daily_weather = [];

  Future getWeatherProperty(lat, long) async {
    var response = await get(Uri.parse(
        "http://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$long&appid=30297cf67845e2e06a9b5fd69603e098&lang=tr&units=metric"));

    var res = json.decode(utf8.decode(response.bodyBytes));

    var weather_data = WeatherModel.fromJson(res);

    print(weather_data.list![9].weather![0].description);

    for (var item in weather_data.list!) {
      if (daily_weather.isNotEmpty) {
        if (daily_weather.last[1] != item.dtTxt!.substring(0, 10)) {
          var daily_weather_temp = [];
          daily_weather_temp.add(item.weather![0].description);
          daily_weather_temp.add(item.dtTxt!.substring(0, 10));
          daily_weather_temp.add(item.main!.temp);
          daily_weather_temp.add(item.weather![0].id);


          daily_weather.add(daily_weather_temp);
        }
      } else {
        var daily_weather_temp = [];
        daily_weather_temp.add(item.weather![0].description);
        daily_weather_temp.add(item.dtTxt!.substring(0, 10));
        daily_weather_temp.add(item.main!.temp);

        daily_weather.add(daily_weather_temp);
      }
    }

    print(daily_weather);
  }

  final Geolocator geolocator = Geolocator();

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    _getCurrentLocation();

    return await Geolocator.getCurrentPosition();
  }

  _getCurrentLocation() {
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        _getAddressFromLatLng();
        getWeatherProperty(
            _currentPosition!.latitude, _currentPosition!.longitude);
      });
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress =
            "${place.postalCode}, ${place.country}, ${place.administrativeArea}, ${place.street}";
      });

      print(_currentAddress);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 27.0, top: 29),
                        child: Text(
                          "Hava Durumu",
                          style:
                              TextStyle(color: Color(0xff253031), fontSize: 35),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Icon(
                              Icons.location_on,
                              size: 50,
                              color: Color(0xff253031),
                            ),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 11.0),
                            child: SizedBox(
                                width: 268,
                                height: 94,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  color: Color(0xff0957EB),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Text(
                                          " _currentAddress!",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20),
                                        ),
                                      )),
                                )),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 42.0),
                      child: Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 7.0),
                            child: SizedBox(
                                width: 102,
                                height: 101,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  color: Color(0xff0957EB),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Text(
                                          "_currentAddress",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20),
                                        ),
                                      )),
                                )),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 11.0),
                            child: SizedBox(
                                width: 223,
                                height: 69,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  color: Color(0xff0957EB),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Text(
                                          " _currentAddress!",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15),
                                        ),
                                      )),
                                )),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}

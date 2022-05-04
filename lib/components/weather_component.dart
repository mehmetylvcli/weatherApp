// ignore_for_file: non_constant_identifier_names, avoid_print

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

  var dailyWeather = [];

  Future getWeatherProperty(lat, long) async {
    var response = await get(Uri.parse(
        "http://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$long&appid=30297cf67845e2e06a9b5fd69603e098&lang=tr&units=metric"));

    var res = json.decode(utf8.decode(response.bodyBytes));

    var weatherData = WeatherModel.fromJson(res);

    // print(weatherData.list![9].weather![0].description);

    for (var item in weatherData.list!) {
      if (dailyWeather.isNotEmpty) {
        if (dailyWeather.last[1] != item.dtTxt!.substring(0, 10) &&
            dailyWeather.last[4] == item.dtTxt!.substring(11, 16)) {
          var dailyWeather_temp = [];
          dailyWeather_temp.add(item.weather![0].description);
          dailyWeather_temp.add(item.dtTxt!.substring(0, 10));
          dailyWeather_temp.add(item.main!.temp);
          dailyWeather_temp.add(
              "http://openweathermap.org/img/wn/${item.weather![0].icon}@2x.png");
          dailyWeather_temp.add(item.dtTxt!.substring(11, 16));

          setState(() {
            dailyWeather.add(dailyWeather_temp);
          });
        }
      } else {
        var dailyWeather_temp = [];

        dailyWeather_temp.add(item.weather![0].description);
        dailyWeather_temp.add(item.dtTxt!.substring(0, 10));
        dailyWeather_temp.add(item.main!.temp);
        dailyWeather_temp.add(
            "http://openweathermap.org/img/wn/${item.weather![0].icon}@2x.png");
        dailyWeather_temp.add(item.dtTxt!.substring(11, 16));

        setState(() {
          dailyWeather.add(dailyWeather_temp);
        });
      }
    }

    print(dailyWeather);

    return dailyWeather;
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
    super.initState();
    _determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE9EAE5),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                decoration: const BoxDecoration(
                  color: Color(0xffE9EAE5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 27.0, top: 29),
                        child: Row(
                          // ignore: prefer_const_literals_to_create_immutables
                          children: [
                            const Text(
                              "Hava Durumu",
                              style: TextStyle(
                                  color: Color(0xff253031), fontSize: 35),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 30.0),
                              child:  Icon(
                                Icons.cloudy_snowing,
                                size: 40,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Row(
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(left: 15.0),
                            child:  Icon(
                              Icons.location_on,
                              size: 50,
                              color:  Color(0xff253031),
                            ),
                          ),
                          const SizedBox(
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
                                  color: const Color(0xff0957EB),
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: (_currentAddress == null)
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : Text(
                                                _currentAddress!,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15),
                                              ),
                                      )),
                                )),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                        ],
                      ),
                    ),
                    // ignore: prefer_const_constructors
                    Align(
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 29),
                        child: Text(
                          "4 Günlük Hava Raporu",
                          style:
                              TextStyle(color:  Color(0xff253031), fontSize: 28),
                        ),
                      ),
                    ),
                    const Divider(
                      color: Colors.black,
                    ),
                    // test
                    Container(
                      transform: Matrix4.translationValues(0, -30, 0),
                      child: (dailyWeather.isEmpty)
                          ? const Padding(
                              padding: EdgeInsets.only(top: 208.0),
                              child:  CircularProgressIndicator(
                                color:  Color(0xff0957EB),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              itemCount: (dailyWeather.isNotEmpty)
                                  ? dailyWeather.length - 1
                                  : 0,
                              itemBuilder: (BuildContext context, int index) {
                                return Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 7.0),
                                      child: SizedBox(
                                          width: 102,
                                          height: 101,
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            color: const Color(0xff0957EB),
                                            child: Column(
                                              children: [
                                                Flexible(
                                                  flex: 1,
                                                  child: Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Align(
                                                          alignment:
                                                              Alignment.topLeft,
                                                          child: Text(
                                                            dailyWeather[index]
                                                                    [1]
                                                                .substring(
                                                                    5, 10)
                                                                .toString(),
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                left: 10,
                                                                top: 4.0),
                                                        child: Align(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: Text(
                                                            dailyWeather[index]
                                                                    [4]
                                                                .toString(),
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Flexible(
                                                  flex: 3,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Image.network(
                                                          dailyWeather[index]
                                                              [3])),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 11.0),
                                      child: SizedBox(
                                          width: 223,
                                          height: 69,
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            color: const Color(0xff0957EB),
                                            child: Row(
                                              children: [
                                                Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6.0),
                                                      child: Text(
                                                        dailyWeather[index][2]
                                                                .toStringAsFixed(
                                                                    1) +
                                                            "°C",
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15),
                                                      ),
                                                    )),
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              14.0),
                                                      child: Text(
                                                        dailyWeather[index][0]
                                                                .substring(0, 1)
                                                                .toUpperCase()
                                                                .toString() +
                                                            dailyWeather[index]
                                                                    [0]
                                                                .substring(1),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 17),
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          )),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                  ],
                                );
                              }),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}

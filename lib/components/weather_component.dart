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
        if (daily_weather.last[1] != item.dtTxt!.substring(0, 10) &&
            daily_weather.last[4] == item.dtTxt!.substring(11, 16)) {
          var daily_weather_temp = [];
          daily_weather_temp.add(item.weather![0].description);
          daily_weather_temp.add(item.dtTxt!.substring(0, 10));
          daily_weather_temp.add(item.main!.temp);
          daily_weather_temp.add(
              "http://openweathermap.org/img/wn/${item.weather![0].icon}@2x.png");
          daily_weather_temp.add(item.dtTxt!.substring(11, 16));

          setState(() {
            daily_weather.add(daily_weather_temp);
          });
        }
      } else {
        var daily_weather_temp = [];

        daily_weather_temp.add(item.weather![0].description);
        daily_weather_temp.add(item.dtTxt!.substring(0, 10));
        daily_weather_temp.add(item.main!.temp);
        daily_weather_temp.add(
            "http://openweathermap.org/img/wn/${item.weather![0].icon}@2x.png");
        daily_weather_temp.add(item.dtTxt!.substring(11, 16));

        setState(() {
          daily_weather.add(daily_weather_temp);
        });
      }
    }

    print(daily_weather);

    return daily_weather;
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
      backgroundColor: Color(0xffE9EAE5),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                decoration: BoxDecoration(
                  color: Color(0xffE9EAE5),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 27.0, top: 29),
                        child: Row(
                          children: [
                            Text(
                              "Hava Durumu",
                              style: TextStyle(
                                  color: Color(0xff253031), fontSize: 35),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 30.0),
                              child: Icon(
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
                                        child: (_currentAddress == null)
                                            ? CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : Text(
                                                _currentAddress!,
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
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 29),
                        child: Text(
                          "4 Günlük Hava Raporu",
                          style:
                              TextStyle(color: Color(0xff253031), fontSize: 28),
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.black,
                    ),
                    Container(
                      transform: Matrix4.translationValues(0, -30, 0),
                      child: (daily_weather.isEmpty)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 208.0),
                              child: CircularProgressIndicator(
                                color: Color(0xff0957EB),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              itemCount: (daily_weather.isNotEmpty)
                                  ? daily_weather.length - 1
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
                                            color: Color(0xff0957EB),
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
                                                            daily_weather[index]
                                                                    [1]
                                                                .substring(
                                                                    5, 10)
                                                                .toString(),
                                                            style: TextStyle(
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
                                                            daily_weather[index]
                                                                    [4]
                                                                .toString(),
                                                            style: TextStyle(
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
                                                          daily_weather[index]
                                                              [3])),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ),
                                    SizedBox(
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
                                            color: Color(0xff0957EB),
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
                                                        daily_weather[index][2]
                                                                .toStringAsFixed(
                                                                    1) +
                                                            "°C",
                                                        style: TextStyle(
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
                                                        daily_weather[index][0],
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 17),
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          )),
                                    ),
                                    SizedBox(
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

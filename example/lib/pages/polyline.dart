import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/drawer.dart';
import 'package:http/http.dart' as http;

class PolylinePage extends StatefulWidget {
  static const String route = 'polyline';

  const PolylinePage({Key? key}) : super(key: key);

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

Future<List<LatLng>> _getRoute(LatLng from, LatLng to,
    {String? profile = "driving",
    String? format = "json",
    bool? steps = true}) async {
  var headersList = {
    'Accept': '*/*',
    'User-Agent': 'dev.fleaflet.flutter_map.example'
  };
  var url = Uri.parse(
      'http://router.project-osrm.org/route/v1/$profile/${from.longitude},${from.latitude};${to.longitude},${to.latitude}.$format?overview=false&steps=$steps');
  print(url);

  var req = http.Request('GET', url);
  req.headers.addAll(headersList);

  var res = await req.send();
  final resBody = json.decode(await res.stream.bytesToString());
  var result = <LatLng>[];
  if (res.statusCode >= 200 && res.statusCode < 300) {
    // print(resBody);
    // For this request, by default, we want the fastest route,
    // so `legs` the set of routes contain one child
    var steps = resBody['routes']![0]!['legs']![0]!['steps'];
    if (steps is List) {
      // Each step is a graph (suit of intersections)
      // An Interaction is like a vertex(node)
      for (final step in steps) {
        final intersections = step['intersections'];
        for (final item in intersections) {
          final location = item['location'];
          if (location.length > 1) {
            result.add(LatLng(location[0] as double, location[1] as double));
          }
        }
      }
    }
  } else {
    print(resBody);
  }

  // print(result);
  return result;
}

class _PolylinePageState extends State<PolylinePage> {
  late Future<List<Polyline>> polylines;

  Future<List<Polyline>> getPolylines() async {
    var polyLines = [
      Polyline(
        points: [LatLng(12.612582, -8.0655536), LatLng(5.3484461, -4.0497056)],
        strokeWidth: 4.0,
        color: Colors.amber,
        isDotted: true,
      ),
      Polyline(
        points: await _getRoute(
            LatLng(12.612582, -8.0655536), LatLng(5.3484461, -4.0497056)),
        strokeWidth: 4.0,
        color: Colors.red,
      )
    ];
    // await Future.delayed(const Duration(seconds: 3));
    // print(polyLines.map((e) => e.points));
    return polyLines;
  }

  @override
  void initState() {
    polylines = getPolylines();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var points = <LatLng>[
      LatLng(51.5, -0.09),
      LatLng(53.3498, -6.2603),
      LatLng(48.8566, 2.3522),
    ];

    // var pointsGradient = <LatLng>[
    //   LatLng(55.5, -0.09),
    //   LatLng(54.3498, -6.2603),
    //   LatLng(52.8566, 2.3522),
    // ];

    return Scaffold(
        appBar: AppBar(title: const Text('Polylines')),
        drawer: buildDrawer(context, PolylinePage.route),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Polyline>>(
            future: polylines,
            builder:
                (BuildContext context, AsyncSnapshot<List<Polyline>> snapshot) {
              debugPrint('snapshot: ${snapshot.hasData}');
              if (snapshot.hasData) {
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text('Polylines'),
                    ),
                    Flexible(
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(7.4608434, -7.7921057),
                          zoom: 5.0,
                          onTap: (tapPosition, point) {
                            setState(() {
                              debugPrint('onTap');
                              polylines = getPolylines();
                            });
                          },
                        ),
                        layers: [
                          TileLayerOptions(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: ['a', 'b', 'c'],
                            userAgentPackageName:
                                'dev.fleaflet.flutter_map.example',
                          ),
                          PolylineLayerOptions(
                            polylines: [
                              Polyline(
                                  points: points,
                                  strokeWidth: 4.0,
                                  color: Colors.purple),
                            ],
                          ),
                          // PolylineLayerOptions(
                          //   polylines: [
                          //     Polyline(
                          //       points: pointsGradient,
                          //       strokeWidth: 4.0,
                          //       gradientColors: [
                          //         const Color(0xffE40203),
                          //         const Color(0xffFEED00),
                          //         const Color(0xff007E2D),
                          //       ],
                          //     ),
                          //   ],
                          // ),
                          PolylineLayerOptions(
                            polylines: snapshot.data!,
                            polylineCulling: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const Text(
                  'Getting map data...\n\nTap on map when complete to refresh map data.');
            },
          ),
        ));
  }
}

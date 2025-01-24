import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyetrainer',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: GraphScreen(),
    );
  }
}

class GraphScreen extends StatefulWidget {
  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  double _distanceBetweenEyes = 48.0;
  double _excenterPosition = 2.0;
  int _graphType = 0; // 0 for Paper, 1 for Trou, 2 for Lateral
  int _subType = 0;
  late double ppi; // Pixels per Inch (PPI)
  late double mmToPixel; // Conversion factor from mm to pixels

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved state
  }

  // Function to load saved state from SharedPreferences
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _distanceBetweenEyes = prefs.getDouble('distanceBetweenEyes') ?? 50.0;
      _excenterPosition = prefs.getDouble('excenterPosition') ?? 2.5;
      _graphType = prefs.getInt('graphType') ?? 0;
      _subType = prefs.getInt('subType') ?? 0;
    });
  }

  // Function to save current state to SharedPreferences
  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('distanceBetweenEyes', _distanceBetweenEyes);
    await prefs.setDouble('excenterPosition', _excenterPosition);
    await prefs.setInt('graphType', _graphType);
    await prefs.setInt('subType', _subType);
  }

  void _cycleSubtype() {
    List<int> subtypeOptions = _graphType == 2 ? [0, 1, 2] : [0, 1, 2, 3];
    int currentIndex = subtypeOptions.indexOf(_subType);
    // Cycle to the next subtype, or go back to the first option if it's the last one
    setState(() {
      _subType = subtypeOptions[(currentIndex + 1) % subtypeOptions.length];
    });
    _savePreferences(); // Save state
  }
  // Navigate to HelpScreen
  void _navigateToHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HelpScreen()),
    );
  }
  @override
  Widget build(BuildContext context) {
    List<int> subtypeOptions = _graphType == 2 ? [0, 1, 2] : [0, 1, 2, 3];

    if (kIsWeb) {
      double manualDpi = 96; // Adjust for your system's actual DPI
      mmToPixel = manualDpi * 0.0393701;
    }
    else  if (Platform.isAndroid || Platform.isIOS) {
      // For mobile platforms, use the devicePixelRatio from MediaQuery
      double dpi = MediaQuery.of(context).devicePixelRatio *
          45; // should be 160
      mmToPixel = dpi / 25.4; // Convert mm to pixels
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      // For desktop platforms, manually set the DPI (e.g., Linux = 96 DPI)
      double manualDpi = 107.5; // Adjust for your system's actual DPI
      mmToPixel = manualDpi * 0.0393701;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Train your screen eyes'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              _navigateToHelp(context); // Navigate to help when pressed
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Stretch sliders to the height of the screen
        children: <Widget>[
          // Left slider (rotated vertically)
          RotatedBox(
            quarterTurns: 3, // Rotates the slider 270 degrees
            child: Slider(
              min: 35,
              max: 60,
              divisions: 50,
              label: _distanceBetweenEyes.toStringAsFixed(2),
              value: _distanceBetweenEyes,
              onChanged: (double value) {
                setState(() {
                  _distanceBetweenEyes = value;
                });
                _savePreferences(); // Save state
              },
            ),
          ),

          // Middle section: Canvas and Buttons
          Expanded(
            child: Column(children: <Widget>[
              // Canvas
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth,
                        // Apply calculated width
                        height: constraints.maxHeight,
                        // Apply calculated height
                        color: Colors.white,
                        child: CustomPaint(
                          painter: CirclePainter(
                            graphType: _graphType,
                            distance: _distanceBetweenEyes,
                            excenter: _excenterPosition,
                            mmToPixels: mmToPixel,
                            subType: _subType,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 1.0),
                    // Add padding for left text
                    child: Text(
                      'Distance: ${_distanceBetweenEyes.toStringAsFixed(2)} mm', // Replace with desired left text
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  // ToggleButtons under the canvas
                  ToggleButtons(
                    children: <Widget>[
                      Text('Paper'),
                      Text('Hole'),
                      Text('Lateral'),
                    ],
                    isSelected: [
                      _graphType == 0,
                      _graphType == 1,
                      _graphType == 2
                    ],
                    onPressed: (int index) {
                      setState(() {
                        _graphType = index;
                      });
                      _savePreferences(); // Save state
                    },
                  ),
                  SizedBox(width: 16),
                  // Elevated button to cycle subtypes
                  ElevatedButton(
                    onPressed: _cycleSubtype,
                    child: Text('Subtype: $_subType'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 1.0),
                    // Add padding for right text
                    child: Text(
                      'Excenter: ${_excenterPosition.toStringAsFixed(2)} mm', // Replace with desired right text
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ]),
          ),

          // Right slider (rotated vertically)
          RotatedBox(
            quarterTurns: 3, // Rotates the slider 90 degrees
            child: Slider(
              min: -1,
              max: 6,
              divisions: 20,
              label: _excenterPosition.toStringAsFixed(2),
              value: _excenterPosition,
              onChanged: (double value) {
                setState(() {
                  if (_graphType == 1){
                    _excenterPosition = min(value,3);
                  }
                  else{
                    _excenterPosition = value;
                  }
                });
                _savePreferences(); // Save state
              },
            ),
          ),
        ],
      ),
    );
  }
}


class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & About'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Work in Convergence
              Text(
                'Work in Convergence',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'The work in convergence should be undertaken in the usual way. The main advantages of these stereograms are the calibration of the gap between the figures and the rigidity of the support.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Work in Divergence
              Text(
                'Work in Divergence',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Start with close-up divergence exercises, which are the easiest. For this close-up work, it is preferable to use the 45 mm stereogram.\n\n'
                    'With one hand, the patient holds the stereogram close to the face and places the two holes in front of the eyes. They look at the index finger of the other hand, held about 30 cm away. Then, gradually, the patient moves the stereogram away from their eyes while maintaining fixation on the index finger.\n\n'
                    'When the stereogram is moved about 6 cm away from the face, and the patient is binocularly fixating on the finger, they perceive three holes. The patient should then focus on the central hole and remove the finger while continuing to see the three holes. Later, they will move the stereogram closer and farther while maintaining fusion in divergence.\n\n'
                    'For distance work, the same maneuvers will be performed while focusing on a more distant object. The greater the distance, the larger the gap between the two holes should be. Beyond 5 meters, the 60 mm stereogram should be used.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Work with a Mirror
              Text(
                'Work with a Mirror',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'With the 60 mm stereogram, one can work by looking at a mirror placed behind the stereogram. The printed face of the stereogram should be turned toward the mirror, not toward the subject. Initially, the stereogram is pressed against the face. The patient sees the stereogram in the mirror. When moving it away from the face, there comes a point where only one hole is perceived in the mirror. This is when sagittal alignment is achieved. By moving the stereogram closer to the face, the two lateral holes reappear in the mirror.\n\n'
                    'If sagittal alignment is lost (i.e., the patient perceives only two holes), the stereogram should be moved away again until only one hole is perceived, and the previous maneuvers should be repeated.\n\n'
                    'When sagittal alignment is achieved and stable, one sees in the mirror, inside the central hole, a "cyclopean" eye resulting from the fusion of the images from both eyes. Closing one eye does not make the image of this eye disappear.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final int graphType; // 0 for Paper, 1 for Trou, 2 for Lateral
  final double distance;
  final double excenter;
  final int subType;
  final double mmToPixels;

  CirclePainter(
      {required this.graphType,
      required this.distance,
      required this.excenter,
      required this.mmToPixels,
      required this.subType});

  @override
  void paint(Canvas canvas, Size size) {
    switch (graphType) {
      case 0:
        _drawStereogramPaper(canvas, size, mmToPixels);
        break;
      case 1:
        _drawStereogramTrou(canvas, size, subType);
        break;
      case 2:
        _drawStereogramLateral(canvas, size, subType);
        break;
    }
  }

  void _drawStereogramTrou(Canvas canvas, Size size, int type) {
    var blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    var whiteOutline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * mmToPixels;

    var whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var smallCirclePaint = Paint();

    double centerX = size.width / 2 / mmToPixels;
    double centerY = size.height / 2 / mmToPixels;

    double largeCircleRadius = 20;
    if (distance <50){
      largeCircleRadius = 18;
    }
    double smallerCircle = 15;
    if (distance <50){
      smallerCircle = 12;
    }
    // Standard circles
    _myCircle( canvas, centerX - distance / 2 - excenter, centerY, smallerCircle, blackPaint);
    _myCircle(
        canvas, centerX + distance / 2 + excenter, centerY, smallerCircle, blackPaint);

    // Outlines

    _myCircle(canvas, centerX - distance / 2, centerY, largeCircleRadius, whiteOutline);
    _myCircle(canvas, centerX + distance / 2, centerY, largeCircleRadius, whiteOutline);

    if (type == 1 || type == 2 || type == 3) {
      // THREE_CIRCLES, FILLED, FILLED_TWO_COLORS
      smallCirclePaint
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      _myCircle(canvas, centerX - distance / 2 - excenter, centerY, 11,
          smallCirclePaint);
      _myCircle(canvas, centerX + distance / 2 + excenter, centerY, 11,
          smallCirclePaint);
    }

    if (type == 1) {
      // THREE_CIRCLES
      blackPaint.style = PaintingStyle.fill;
      _myCircle(canvas, centerX + distance / 2, centerY, 5, blackPaint);
      _myCircle(canvas, centerX - distance / 2, centerY, 5, blackPaint);
    }

    if (type == 2) {
      // FILLED
      smallCirclePaint.color = Colors.grey;
      _myCircle(canvas, centerX - distance / 2 - excenter, centerY, 11.5,
          smallCirclePaint);
      _myCircle(canvas, centerX + distance / 2 + excenter, centerY, 11.5,
          smallCirclePaint);
    }

    if (type == 3) {
      // FILLED_TWO_COLORS
      smallCirclePaint.color = Colors.green;
      _myCircle(canvas, centerX - distance / 2 - excenter, centerY, 11.5,
          smallCirclePaint);

      smallCirclePaint.color = Colors.red;
      _myCircle(canvas, centerX + distance / 2 + excenter, centerY, 11.5,
          smallCirclePaint);
    }
  }

  void _myCircle(
      Canvas canvas, double x, double y, double radius, Paint paint) {
    canvas.drawCircle(
        Offset(x * mmToPixels, y * mmToPixels), radius * mmToPixels, paint);
  }

  void _drawStereogramPaper(Canvas canvas, Size size, double mmToPixels) {
    var blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    var whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Converting given dimensions from mm to pixels using the conversion factor

    double centerX = size.width / 2 / mmToPixels;
    double centerY = size.height / 2 / mmToPixels;

    // Background rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), blackPaint);

    // Circles positioned based on the scaled distance
    _myCircle(canvas, centerX - distance / 2, centerY, 14, whitePaint);
    _myCircle(canvas, centerX + distance / 2, centerY, 14, whitePaint);

    // Small circles
    _myCircle(
        canvas, centerX - distance / 2 - excenter, centerY, 5, blackPaint);
    _myCircle(
        canvas, centerX + distance / 2 + excenter, centerY,5, blackPaint);

    // Rectangles adjacent to circles
    canvas.drawRect(
        Rect.fromLTWH((centerX - distance / 2 - (14 + 7)) * mmToPixels,
            (centerY - 1.5) * mmToPixels, 8 * mmToPixels, 3 * mmToPixels),
        whitePaint);
    canvas.drawRect(
        Rect.fromLTWH((centerX + distance / 2 + 13) * mmToPixels,
            (centerY - 1.5) * mmToPixels, 8 * mmToPixels, 3 * mmToPixels),
        whitePaint);

    // Calculate the bounding box for small circles

    // Small circles within defined bounds
    for (double y = centerY - 15; y <= centerY + 14; y += 3) {
      for (double x = centerX - distance / 2 - (14 + 8);
          x <= centerX - distance / 2 + (14 + 8);
          x += 3) {
        _myCircle(canvas, x, y, 1.1, blackPaint);
      }
    }

    for (double y = centerY - 15; y <= centerY + 14; y += 3) {
      for (double x = centerX + distance / 2 + (14 + 8);
          x >= centerX + distance / 2 - (14 + 8);
          x -= 3) {
        _myCircle(canvas, x, y, 1.1, blackPaint);
      }
    }
  }

  void _drawStereogramLateral(Canvas canvas, Size size, int type) {
    var blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    var whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    double shift = 2.5;
    double noShift = 0;
    double temp = 0;

    if (type != 0) {
      for (double y = 0; y < size.height / mmToPixels; y += 5) {
        if (type == 2) {
          temp = shift;
          shift = noShift;
          noShift = temp;
        }

        for (double x = 0; x < size.width / mmToPixels; x += 5) {
          _myCircle(canvas, x + shift, y, 1.0, blackPaint);
        }
      }
    }
    double centerX = size.width / 2 / mmToPixels;
    double centerY = size.height / 2 / mmToPixels;

    _myCircle(canvas, centerX - distance / 2, centerY, 15, blackPaint);
    _myCircle(canvas, centerX + distance / 2, centerY, 15, blackPaint);

    _myCircle(
        canvas, centerX - distance / 2 - excenter, centerY, 5, whitePaint);
    _myCircle(
        canvas, centerX + distance / 2 + excenter, centerY,5, whitePaint);

    canvas.drawRect(
        Rect.fromLTWH((centerX - distance / 2 - (14 + 7)) * mmToPixels,
            (centerY - 1.5) * mmToPixels, 8 * mmToPixels, 3 * mmToPixels),
        blackPaint);
    canvas.drawRect(
        Rect.fromLTWH((centerX + distance / 2 + 13) * mmToPixels,
            (centerY - 1.5) * mmToPixels, 8 * mmToPixels, 3 * mmToPixels),
        blackPaint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => true;
}

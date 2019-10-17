import 'package:flutter/material.dart';
import 'dart:math' as math;

class Roundabout extends StatefulWidget {
  /// The [Widget] children to display in the roundabout.
  /// The children do not have to be of the same type, as long as they are all of type [Widget].
  /// Updating the radius can be done more smoothly by calling [updateRadius()] after changing the radius.
  /// Otherwise the radius will only update when the component is scrolled again.
  final List<Widget> children;

  /// The radius of the roundabout.
  /// If updated [updateRadius()] should be called, otherwise the user will have to scroll before the radius updates properly.
  /// Consider assigning a key to the component to call the function.
  final double radius;

  /// The pitch of the roundabout.
  /// Can be any value between [-Pi/2] and [Pi/2].
  final double angle;

  /// Decides when the elements in the roundabout should stop rendering.
  /// When an element comes within this angle of the far point on the roundabout, it will not render.
  /// Can be any value between [0] and [Pi], not including [0].
  /// Value can also be null to never stop rendering elements on screen.
  final double visibilityThreshold;

  /// The horizontal offset of the roundabout.
  final double offsetX;

  /// The vertical offset of the roundabout.
  final double offsetY;

  /// How quickly the roundabout should stop rotating after swiping.
  /// Ideally a value around [5.0].
  final double deceleration;

  /// Set to [true] if scrolling via swiping should be disabled.
  final bool disableSwiping;

  /// Width of every element if they are uniform.
  /// Can't be used with [widthList].
  final num width;

  /// List of the width of every element. This is used when the elements in the list are not uniform.
  /// Can't be used with [width].
  final List<double> widthList;

  /// Weight of the roundabout. The heavier the roundabout, the more difficult it is to turn.
  /// The default weight is based on [radius].
  final double weight;

  /// If set to true, elements will be rotated in 3d as they go around
  final bool rotateElements;

  /// Decides if the roundabout should be vertical.
  final bool vertical;

  /// If set to true, elements will snap once scrolling finishes
  final bool snap;

  const Roundabout({
    Key key,
    @required this.children,
    this.radius = 128.0,
    this.angle = math.pi / 4,
    this.visibilityThreshold,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.deceleration = 5.0,
    this.disableSwiping = false,
    this.vertical = false,
    this.rotateElements = false,
    this.snap = false,
    this.width,
    this.widthList,
    this.weight,
  })  : assert(
            (width != null && widthList == null) ||
                (width == null && widthList != null) ||
                (width == null && widthList == null),
            'Define either width or widthList, not both'),
        assert(angle <= math.pi / 2 && angle >= -math.pi / 2,
            'Angle must lie in the interval [-Pi/2;Pi/2]'),
        assert(
            visibilityThreshold == null ||
                visibilityThreshold > 0 && visibilityThreshold <= math.pi,
            'Visibility thresholds must lie in the interval ]0;Pi]'),
        super(key: key);

  @override
  RoundaboutState createState() => RoundaboutState();
}

class RoundaboutState extends State<Roundabout> {
  List<double> _angles = [];
  List<double> _distX = [];
  List<double> _distY = [];
  int _currentlyScrolling = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.children.length; i++) {
      _angles.add((2 * math.pi) / widget.children.length * i);
      _distX.add((math.sin(_angles[i]) * widget.radius).roundToDouble());
      _distY.add((math.cos(_angles[i]) * widget.radius).roundToDouble());
    }
    print(_angles);
    print(_distX);
    print(_distY);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (t) => (widget.disableSwiping)
          ? () {}
          : _incrementPhysics((widget.vertical) ? t.delta.dy : t.delta.dx),
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: List.generate(
            widget.children.length,
            (index) {
              final element = widget.children[index];
              final width = widget.width != null
                  ? widget.width
                  : widget.widthList != null ? widget.widthList[index] : 0;
              return AnimatedPositioned(
                curve: Curves.linear,
                duration: Duration(milliseconds: 125),
                left: (widget.vertical)
                    ? (_distY[index]) * widget.angle +
                        widget.radius * widget.angle +
                        widget.offsetY
                    : _distX[index] +
                        widget.radius +
                        widget.offsetX -
                        (widget.rotateElements ? width / 4 : width / 2),
                top: (widget.vertical)
                    ? _distX[index] +
                        widget.radius +
                        widget.offsetX -
                        (widget.rotateElements ? width / 4 : width / 2)
                    : (_distY[index]) * widget.angle +
                        widget.radius * widget.angle +
                        widget.offsetY,
                child: Transform.scale(
                  alignment: Alignment.center,
                  scale: ((_distY[index] / (widget.radius * 2) + 0.5) *
                              (1 - widget.angle.abs() / (math.pi / 2)) +
                          (widget.angle.abs() / (math.pi / 2)))
                      .abs(),
                  child: Container(
                    child: Visibility(
                      visible: widget.visibilityThreshold == null
                          ? true
                          : (_angles[index] >= 0 &&
                                  _angles[index] <= math.pi &&
                                  _angles[index] <=
                                      math.pi - widget.visibilityThreshold) ||
                              (_angles[index] >= math.pi &&
                                  _angles[index] <= math.pi * 2 &&
                                  _angles[index] >=
                                      widget.visibilityThreshold + math.pi),
                      child: Transform(
                        transform: widget.rotateElements
                            ? (widget.vertical
                                ? (Matrix4.identity()..rotateX(_angles[index]))
                                : (Matrix4.identity()..rotateY(_angles[index])))
                            : Matrix4.identity(),
                        child: element,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _incrementPhysics(number) async {
    setState(() {
      _currentlyScrolling = _currentlyScrolling + 1;
    });
    final weight = widget.weight != null
        ? widget.weight * 100
        : (widget.radius * 2 * math.pi) / 2;
    if (number > 0) {
      while (number > 0) {
        for (int i = 0; i < widget.children.length; i++) {
          _angles[i] = (_angles[i] + number / weight) % (math.pi * 2);
          _distX[i] = ((math.sin(_angles[i]) * widget.radius).roundToDouble());
          _distY[i] = ((math.cos(_angles[i]) * widget.radius).roundToDouble());
        }
        setState(() {});
        await Future.delayed(Duration(milliseconds: 110));
        number = number - widget.deceleration;
      }
    } else {
      while (number < 0) {
        for (int i = 0; i < widget.children.length; i++) {
          _angles[i] = (_angles[i] + number / weight) % (math.pi * 2);
          _distX[i] = ((math.sin(_angles[i]) * widget.radius).roundToDouble());
          _distY[i] = ((math.cos(_angles[i]) * widget.radius).roundToDouble());
        }
        setState(() {});
        await Future.delayed(Duration(milliseconds: 110));
        number = number + widget.deceleration;
      }
    }
    setState(() {
      _currentlyScrolling = _currentlyScrolling - 1;
    });
    if (_currentlyScrolling == 0 && widget.snap) _snapElements();
  }

  void _snapElements() {
    final int baseIndex = getIndexAtAngle(0.0);
    double angleFromSnap = 0.0;
    if (_angles[baseIndex] <= (_angles[baseIndex] - 2 * math.pi).abs()) {
      angleFromSnap = _angles[baseIndex];
    } else {
      angleFromSnap = (_angles[baseIndex] - 2 * math.pi);
    }
    _incrementAngle(-angleFromSnap);
  }

  int getIndexAtAngle(double angle) {
    int index = 0;
    double angleDiff = double.maxFinite;
    for (int i = 0; i < _angles.length; i++) {
      double tempAngleDiff = (_angles[i] - angle).abs();
      double tempAngleDiff2 = (_angles[i] - 2 * math.pi + angle).abs();
      if (tempAngleDiff <= angleDiff && tempAngleDiff <= tempAngleDiff2) {
        index = i;
        angleDiff = tempAngleDiff;
      } else if (tempAngleDiff2 <= angleDiff) {
        index = i;
        angleDiff = tempAngleDiff2;
      }
    }
    return index;
  }

  void _incrementAngle(double angle) {
    for (int i = 0; i < widget.children.length; i++) {
      _angles[i] = (_angles[i] + angle) % (math.pi * 2);
      _distX[i] = ((math.sin(_angles[i]) * widget.radius).roundToDouble());
      _distY[i] = ((math.cos(_angles[i]) * widget.radius).roundToDouble());
    }
    setState(() {});
  }

  void _incrementIndex(int index) {
    for (int i = 0; i < widget.children.length; i++) {
      _angles[i] =
          (_angles[i] + index * (2 * math.pi) / widget.children.length) %
              (math.pi * 2);
      _distX[i] = ((math.sin(_angles[i]) * widget.radius).roundToDouble());
      _distY[i] = ((math.cos(_angles[i]) * widget.radius).roundToDouble());
    }
    setState(() {});
  }

  void scrollIndex(int index) {
    _incrementIndex(index);
  }

  void scrollList(num velocity) {
    _incrementPhysics(velocity);
  }

  void update() async {
    await Future.delayed(Duration(milliseconds: 100));
    for (int i = 0; i < widget.children.length; i++) {
      _angles[i] = (_angles[i] + double.minPositive) % (math.pi * 2);
      _distX[i] = ((math.sin(_angles[i]) * widget.radius).roundToDouble());
      _distY[i] = ((math.cos(_angles[i]) * widget.radius).roundToDouble());
    }
    if(widget.snap) _snapElements();
    setState(() {});
  }
}

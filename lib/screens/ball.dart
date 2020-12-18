import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ball.dart';

class BallCircle extends StatefulWidget {
  @override
  _BallCircleState createState() => _BallCircleState();
}

class _BallCircleState extends State<BallCircle> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Consumer<Ball>(
        builder: (context, ball, child) => CustomPaint(
          painter: CirclePainter(ball.x, ball.y),
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final double x;
  final double y;
  final double radius = 20;
  CirclePainter(this.x, this.y);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Color(0xff63aa65)
      ..style = PaintingStyle.fill;
    //a circle
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

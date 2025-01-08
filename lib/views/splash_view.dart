import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_store.dart';
import '../services/currency_service.dart';
import 'content_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  bool _isActive = false;
  double _opacity = 0.0;
  late AnimationController _sparkleScaleController;
  late AnimationController _sparkleRotationController;
  late Animation<double> _sparkleScaleAnimation;
  late Animation<double> _sparkleRadiusAnimation;
  late Animation<double> _sparkleSpinAnimation;

  final backgroundGradient = const LinearGradient(
    colors: [
      Color.fromRGBO(135, 206, 235, 1),
      Color.fromRGBO(51, 153, 204, 1),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final tealColor = const Color.fromRGBO(64, 224, 208, 1);
  final navyBlue = const Color.fromRGBO(28, 67, 110, 1);

  @override
  void initState() {
    super.initState();

    // Controller for the entire spiral-out animation
    _sparkleScaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animation for individual sparkle rotation
    _sparkleRotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create a curved animation for the radius expansion
    _sparkleRadiusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleScaleController,
      curve: Curves.easeOutBack,
    ));

    // Create a curved animation for the spin-out effect
    _sparkleSpinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // Two full rotations during spiral out
    ).animate(CurvedAnimation(
      parent: _sparkleScaleController,
      curve: Curves.easeOutCubic,
    ));

    // Scale animation for sparkle size
    _sparkleScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleScaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  @override
  void dispose() {
    _sparkleScaleController.dispose();
    _sparkleRotationController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _opacity = 1.0);
    });

    _sparkleScaleController.forward();
    _sparkleRotationController.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() => _isActive = true);
    });
  }

  Offset _sparklePosition(int index, double radiusProgress, double spinProgress) {
    const finalRadius = 120.0;
    final baseAngle = 2 * pi * index / 8;
    // Calculate the current angle including the spin progress
    final currentAngle = baseAngle + (spinProgress * 2 * pi);
    // Calculate the current radius based on the radius progress
    final currentRadius = finalRadius * radiusProgress;

    return Offset(
      cos(currentAngle) * currentRadius,
      sin(currentAngle) * currentRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive) {
      return const ContentView();
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeIn,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 150),
                  const Text(
                    'NewLedger',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Color(0x1A000000),
                          offset: Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 360,
                    height: 360,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                        ...List.generate(8, (index) {
                          return AnimatedBuilder(
                            animation: Listenable.merge([
                              _sparkleRadiusAnimation,
                              _sparkleSpinAnimation,
                              _sparkleScaleAnimation,
                              _sparkleRotationController,
                            ]),
                            builder: (context, child) {
                              final position = _sparklePosition(
                                index,
                                _sparkleRadiusAnimation.value,
                                _sparkleSpinAnimation.value,
                              );
                              return Positioned(
                                left: position.dx + 180,
                                top: position.dy + 180,
                                child: Transform.rotate(
                                  angle: _sparkleRotationController.value * 2 * pi,
                                  child: Transform.scale(
                                    scale: _sparkleScaleAnimation.value,
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 70),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Developed by',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fong-Yu (Yang) Lin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'YuYu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: tealColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
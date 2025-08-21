import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class BeautifulRatingDialog extends StatefulWidget {
  final Function(double rating)? onRatingSubmitted;
  final VoidCallback? onCancelled;

  const BeautifulRatingDialog({
    Key? key,
    this.onRatingSubmitted,
    this.onCancelled,
  }) : super(key: key);

  @override
  State<BeautifulRatingDialog> createState() => _BeautifulRatingDialogState();
}

class _BeautifulRatingDialogState extends State<BeautifulRatingDialog>
    with TickerProviderStateMixin {
  double _rating = 0;
  bool _showThankYou = false;
  late AnimationController _animationController;
  late AnimationController _starAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _starScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _starScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _starAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _starAnimationController.dispose();
    super.dispose();
  }

  void _onStarTapped(int starIndex) {
    setState(() {
      _rating = starIndex + 1.0;
    });
    
    _starAnimationController.forward().then((_) {
      _starAnimationController.reverse();
    });
    
    // Auto-submit after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_rating > 0) {
        _handleSubmit();
      }
    });
  }

  void _handleSubmit() {
    if (_rating >= 4.0) {
      // High rating - show thank you and redirect to store
      setState(() {
        _showThankYou = true;
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onRatingSubmitted?.call(_rating);
        Navigator.of(context).pop();
      });
    } else if (_rating > 0) {
      // Lower rating - show feedback message
      setState(() {
        _showThankYou = true;
      });
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        widget.onRatingSubmitted?.call(_rating);
        Navigator.of(context).pop();
      });
    }
  }

  Widget _buildStar(int index) {
    bool isFilled = index < _rating;
    
    return GestureDetector(
      onTap: () => _onStarTapped(index),
      child: AnimatedBuilder(
        animation: _starScaleAnimation,
        builder: (context, child) {
          double scale = index == _rating - 1 ? _starScaleAnimation.value : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: isFilled 
                  ? const Color(0xFFFFD700)
                  : Colors.grey[300],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getThankYouMessage() {
    if (_rating >= 5.0) {
      return "🎉 Amazing! Thank you so much!";
    } else if (_rating >= 4.0) {
      return "⭐ Thank you for your rating!";
    } else if (_rating >= 3.0) {
      return "💭 Thanks for your feedback!";
    } else {
      return "🔧 We'll work on improvements!";
    }
  }

  String _getSubMessage() {
    if (_rating >= 4.0) {
      return "Redirecting you to the app store...";
    } else {
      return "Your feedback helps us improve the app.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Icon with beautiful gradient
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF173F5A),
                            const Color(0xFF2E5A7A),
                            const Color(0xFF4A7BA7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF173F5A).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      _showThankYou ? _getThankYouMessage() : "Rate iSpeedScan",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF173F5A),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Message
                    Text(
                      _showThankYou 
                        ? _getSubMessage()
                        : "How would you rate your experience with our app?",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if (!_showThankYou) ...[
                      // Star Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) => _buildStar(index)),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                widget.onCancelled?.call();
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Maybe Later",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _rating > 0 ? _handleSubmit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF173F5A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF173F5A).withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                "Submit",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Thank you animation
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _rating >= 4.0 
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          _rating >= 4.0 ? Icons.favorite : Icons.feedback_outlined,
                          color: _rating >= 4.0 ? Colors.green : Colors.orange,
                          size: 40,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

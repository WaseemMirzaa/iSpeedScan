import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/internationalization.dart';

class CustomRatingDialog extends StatefulWidget {
  final VoidCallback? onDismissed;
  final Function(String)? onButtonPressed;

  const CustomRatingDialog({
    Key? key,
    this.onDismissed,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  State<CustomRatingDialog> createState() => _CustomRatingDialogState();
}

class _CustomRatingDialogState extends State<CustomRatingDialog>
    with TickerProviderStateMixin {
  double _rating = 0;
  bool _showRatingBar = true;
  bool _showThankYou = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openAppStore() async {
    final String appStoreUrl;
    final String playStoreUrl;
    
    if (Platform.isIOS) {
      appStoreUrl = 'https://apps.apple.com/app/id6627339270';
      if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
        await launchUrl(Uri.parse(appStoreUrl), mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isAndroid) {
      playStoreUrl = 'https://play.google.com/store/apps/details?id=com.tevineighdesigns.ispeedscan1';
      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rateMyApp_hasRated', true);
  }

  Future<void> _markAsLater() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('rateMyApp_lastReminder', now.toIso8601String());
  }

  void _onRatingChanged(double rating) {
    setState(() {
      _rating = rating;
    });
    
    if (rating >= 4.0) {
      // High rating - show thank you and redirect to store
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showRatingBar = false;
          _showThankYou = true;
        });
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          _openAppStore();
          _markAsRated();
          widget.onButtonPressed?.call('rate');
          Navigator.of(context).pop();
        });
      });
    } else if (rating > 0) {
      // Lower rating - show feedback option
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showRatingBar = false;
          _showThankYou = true;
        });
        
        Future.delayed(const Duration(milliseconds: 2000), () {
          _markAsRated();
          widget.onButtonPressed?.call('feedback');
          Navigator.of(context).pop();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Icon with glow effect
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF173F5A),
                            Color(0xFF2E5A7A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF173F5A).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      _showThankYou ? '🎉 ${t.thankYou ?? "Thank You!"}' : '⭐ ${t.rateThisApp}',
                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'Poppins',
                        color: Color(0xFF173F5A),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Message
                    Text(
                      _showThankYou 
                        ? (_rating >= 4.0 
                            ? '${t.redirectingToStore ?? "Redirecting you to the app store..."}'
                            : '${t.feedbackAppreciated ?? "Your feedback helps us improve!"}')
                        : t.ifYouUsingEnjoyThisApp,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Rating Bar or Thank You Content
                    if (_showRatingBar) ...[
                      RatingBar.builder(
                        initialRating: 0,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 45,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                        ),
                        onRatingUpdate: _onRatingChanged,
                        glow: true,
                        glowColor: Color(0xFFFFD700).withOpacity(0.3),
                        glowRadius: 2,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                widget.onButtonPressed?.call('no');
                                _markAsRated();
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                t.noThanks,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onButtonPressed?.call('later');
                                _markAsLater();
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF173F5A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                t.maybeLater,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_showThankYou) ...[
                      // Thank you animation
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                        ),
                        child: Icon(
                          _rating >= 4.0 ? Icons.favorite : Icons.feedback,
                          color: _rating >= 4.0 ? Colors.red : Colors.orange,
                          size: 30,
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

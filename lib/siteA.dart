import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:piratefish/api_services/service_api.dart';
import 'package:piratefish/home.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';

// Modèle pour les notifications
class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final String severity;
  final DateTime timestamp;
  final bool isNew;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.isNew,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
      timestamp: DateTime.parse(json['timestamp']),
      isNew: json['is_new'] ?? false,
    );
  }

  Color get severityColor {
    switch (severity) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData get severityIcon {
    switch (type) {
      case 'disease':
        return Icons.warning_amber_rounded;
      case 'leak':
        return Icons.warning_amber_rounded;
      case 'system':
        return Icons.settings;
      case 'detection':
        return Icons.visibility;
      default:
        return Icons.notifications;
    }
  }
}

// Widget pour le streaming MJPEG simple avec gestion d'erreur améliorée
class MjpegView extends StatefulWidget {
  final String streamUrl;

  const MjpegView({Key? key, required this.streamUrl}) : super(key: key);

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  String _timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  Timer? _refreshTimer;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && !_hasError) {
        setState(() {
          _timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        });
      }
    });
  }

  void _handleError() {
    setState(() {
      _hasError = true;
    });
    _refreshTimer?.cancel();
    
    // Retry after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        });
        _startRefreshTimer();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 50),
            const SizedBox(height: 10),
            const Text(
              "Flux vidéo non disponible",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                });
                _startRefreshTimer();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text('RÉESSAYER', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Image.network(
      "${widget.streamUrl}?t=$_timestamp",
      fit: BoxFit.cover,
      headers: const {
        'Cache-Control': 'no-cache, no-store',
        'Pragma': 'no-cache',
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return child;
      },
      errorBuilder: (context, error, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleError();
        });
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }
}

// Widget pour afficher une notification popup - FIXED
class NotificationPopup extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const NotificationPopup({
    Key? key,
    required this.notification,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

// FIXED: Added SingleTickerProviderStateMixin
class _NotificationPopupState extends State<NotificationPopup> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this, // Now this works because of the mixin
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto-dismiss après 8 secondes
    _autoHideTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _autoHideTimer?.cancel();
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.notification.severityColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.notification.severityIcon,
                          color: widget.notification.severityColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        // FIXED: Proper widget structure
                        Expanded(
                          child: Text(
                            widget.notification.title,
                            style: TextStyle(
                              color: widget.notification.severityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _dismiss,
                          icon: Icon(
                            Icons.close, 
                            color: widget.notification.severityColor,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notification.message,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(widget.notification.timestamp),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class Sitea extends StatefulWidget {
  final String userEmail;
  
  const Sitea({super.key, required this.userEmail});

  @override
  State<Sitea> createState() => _SiteaState();
}

class _SiteaState extends State<Sitea> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final String raspberryPiIP = "192.168.137.166"; // Raspberry Pi IP
  bool _isDetectionActive = false;
  bool _isDiseaseDetectionActive = false;
  bool _isLoading = false;
  bool _systemRunning = false;
  bool _leakDetected = false;
  bool _diseaseDetected = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _refreshTimer;
  Timer? _notificationTimer;
  bool _isStreamAvailable = false;
  
  // Notifications
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  final List<NotificationModel> _activePopups = [];
  
  // Sample data for Site A
  final Map<String, Map<String, dynamic>> siteSections = {
    "A1": {
      "status": "En marche",
      "temperature": "25°C",
      "phLevel": "7.2",
      "oxygenLevel": "6.5 mg/L",
      "isActive": true,
    },
    "A2": {
      "status": "En maintenance",
      "temperature": "23°C",
      "phLevel": "6.8",
      "oxygenLevel": "5.9 mg/L",
      "isActive": false,
    }
  };

  // Chart data
  List<FlSpot> temperatureData = [
    FlSpot(0, 22),
    FlSpot(1, 23),
    FlSpot(2, 25),
    FlSpot(3, 24.5),
    FlSpot(4, 25),
    FlSpot(5, 25.5),
    FlSpot(6, 25),
  ];
  
  List<FlSpot> phData = [
    FlSpot(0, 7.0),
    FlSpot(1, 7.1),
    FlSpot(2, 7.2),
    FlSpot(3, 7.1),
    FlSpot(4, 7.3),
    FlSpot(5, 7.2),
    FlSpot(6, 7.1),
  ];
  
  List<FlSpot> oxygenData = [
    FlSpot(0, 6.2),
    FlSpot(1, 6.3),
    FlSpot(2, 6.5),
    FlSpot(3, 6.4),
    FlSpot(4, 6.7),
    FlSpot(5, 6.5),
    FlSpot(6, 6.4),
  ];
  
  String _selectedChartType = "Température";
  
  double _screenWidth = 0;
  double _screenHeight = 0;
  
  double getResponsiveSize(double small, double medium, double large) {
    if (_screenWidth < 360) return small;
    if (_screenWidth < 600) return medium;
    return large;
  }
  
  EdgeInsets getResponsivePadding({
    double? horizontal, 
    double? vertical, 
    double? all,
    double? left,
    double? right,
    double? top,
    double? bottom
  }) {
    double factor = _screenWidth < 360 ? 0.7 : (_screenWidth < 600 ? 1.0 : 1.3);
    
    if (all != null) {
      return EdgeInsets.all(all * factor);
    }
    
    return EdgeInsets.fromLTRB(
      (left ?? horizontal ?? 0) * factor,
      (top ?? vertical ?? 0) * factor,
      (right ?? horizontal ?? 0) * factor,
      (bottom ?? vertical ?? 0) * factor,
    );
  }

  // Vérifier les nouvelles notifications - OPTIMIZED
  Future<void> _checkForNotifications() async {
    try {
      final url = Uri.parse("http://$raspberryPiIP:5000/notifications");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newNotifications = data['new_notifications'] as List;
        
        if (newNotifications.isNotEmpty) {
          for (var notificationData in newNotifications) {
            final notification = NotificationModel.fromJson(notificationData);
            _notifications.insert(0, notification);
            _showNotificationPopup(notification);
          }
          
          if (mounted) {
            setState(() {
              _unreadCount = data['unread_count'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification des notifications: $e");
    }
  }

  // Afficher une notification popup - OPTIMIZED
  void _showNotificationPopup(NotificationModel notification) {
    if (!mounted) return;
    
    // Limit number of active popups
    if (_activePopups.length >= 3) {
      return;
    }
    
    setState(() {
      _activePopups.add(notification);
    });
    
    // Auto remove after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _activePopups.removeWhere((n) => n.id == notification.id);
        });
      }
    });
  }

  // Récupérer l'historique des notifications
  Future<void> _loadNotificationHistory() async {
    try {
      final url = Uri.parse("http://$raspberryPiIP:5000/notifications/history");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = data['notifications'] as List;
        
        if (mounted) {
          setState(() {
            _notifications = notifications
                .map((notif) => NotificationModel.fromJson(notif))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement de l'historique: $e");
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> _markAllAsRead() async {
    try {
      final url = Uri.parse("http://$raspberryPiIP:5000/notifications/mark_read");
      final response = await http.post(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _unreadCount = 0;
          for (var notification in _notifications) {
            // Le serveur gère l'état réel
          }
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du marquage des notifications: $e");
    }
  }

  Future<bool> _checkStreamAvailability() async {
    try {
      final url = Uri.parse("http://$raspberryPiIP:5000/status");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Stream availability check failed: $e");
      return false;
    }
  }

  Future<void> _checkSystemStatus() async {
    try {
      final url = Uri.parse("http://$raspberryPiIP:5000/status");
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _isDetectionActive = data['detection_active'] ?? false;
            _isDiseaseDetectionActive = data['disease_detection_active'] ?? false;
            _systemRunning = data['system_running'] ?? false;
            _leakDetected = data['leak_detected'] ?? false;
            _diseaseDetected = data['disease_detected'] ?? false;
            _unreadCount = data['unread_notifications'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Could not connect to Raspberry Pi: $e");
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      await _checkSystemStatus();
      
      final isStreamAvailable = await _checkStreamAvailability();
      if (mounted) {
        setState(() {
          _isStreamAvailable = isStreamAvailable;
        });
      }
      
      final readings = await _apiService.getReadings();
      
      if (!mounted) return;
      setState(() {
        if (readings.isNotEmpty) {
          final latest = readings.last;
          
          temperatureData = [
            for (int i = 0; i < 6; i++) 
              temperatureData[i+1],
            FlSpot(6, latest['temperature'].toDouble())
          ];

          siteSections["A1"]?["temperature"] = "${latest['temperature']}°C";
          siteSections["A1"]?["phLevel"] = "${latest['ph']}";
          siteSections["A1"]?["oxygenLevel"] = "${latest['oxygen']} mg/L";
        }
      });

      _showSuccessSnackbar('Données actualisées');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: getResponsiveSize(8, 10, 12)),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getResponsiveSize(8, 10, 12))
        ),
        margin: getResponsivePadding(all: 10),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: getResponsiveSize(8, 10, 12)),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getResponsiveSize(8, 10, 12))
        ),
        margin: getResponsivePadding(all: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Fonctions de contrôle du système
  Future<void> _sendCommand(String endpoint, String successMessage) async {
    if (!mounted) return;
    
    try {
      final url = Uri.parse("http://$raspberryPiIP:5000$endpoint");
      setState(() => _isLoading = true);
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _showSuccessSnackbar(successMessage);
        await _checkSystemStatus();
      } else {
        _showErrorSnackbar("Erreur côté serveur");
      }
    } catch (e) {
      _showErrorSnackbar("Erreur de connexion : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      _loadNotificationHistory();
    });

    // OPTIMIZED: Reduced timer frequency
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshData());
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkForNotifications());
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient and waves
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF1E88E5),
                  Color(0xFF42A5F5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
            child: CustomPaint(
              painter: WavePainter(),
              child: Container(),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
          
          // Notifications popup - FIXED
          ..._activePopups.map((notification) => NotificationPopup(
            notification: notification,
            onDismiss: () {
              setState(() {
                _activePopups.removeWhere((n) => n.id == notification.id);
              });
            },
          )),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: getResponsivePadding(all: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: getResponsiveSize(40, 50, 60),
                        height: getResponsiveSize(40, 50, 60),
                        child: const CircularProgressIndicator(
                          color: Color(0xFF1A237E),
                          strokeWidth: 4,
                        ),
                      ),
                      SizedBox(height: getResponsiveSize(12, 16, 20)),
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A237E),
                          fontSize: getResponsiveSize(14, 16, 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: getResponsivePadding(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => 
                      Home(userEmail: widget.userEmail),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(-1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ),
              );
            },
            child: Container(
              padding: getResponsivePadding(all: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: getResponsiveSize(20, 24, 28),
              ),
            ),
          ),
          
          // Title
          Flexible(
            child: Column(
              children: [
                Text(
                  'SITE A',
                  style: TextStyle(
                    fontSize: getResponsiveSize(18, 22, 26),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: getResponsivePadding(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Surveillance intelligente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: getResponsiveSize(10, 12, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Notification button with badge
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildNotificationsSheet(),
              );
            },
            child: Container(
              padding: getResponsivePadding(all: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: getResponsiveSize(20, 24, 28),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: getResponsivePadding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemStatusCard(),
                  SizedBox(height: getResponsiveSize(16, 20, 24)),
                  _buildDetectionControlsCard(),
                  SizedBox(height: getResponsiveSize(16, 20, 24)),
                  _buildVideoStreamCard(),
                  SizedBox(height: getResponsiveSize(16, 20, 24)),
                  if (_leakDetected || _diseaseDetected) _buildAlertsCard(),
                  if (_leakDetected || _diseaseDetected) SizedBox(height: getResponsiveSize(16, 20, 24)),
                  ...siteSections.entries.map((entry) => _buildSiteSection(entry.key, entry.value)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemStatusCard() {
    final activeSectionsCount = siteSections.values.where((section) => section["isActive"] == true).length;
    
    return Container(
      padding: getResponsivePadding(all: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A237E),
            Color(0xFF3949AB),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut du système',
                      style: TextStyle(
                        fontSize: getResponsiveSize(14, 16, 18),
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: getResponsiveSize(5, 8, 10)),
                    Row(
                      children: [
                        Container(
                          width: getResponsiveSize(8, 10, 12),
                          height: getResponsiveSize(8, 10, 12),
                          decoration: BoxDecoration(
                            color: _systemRunning ? Colors.greenAccent : Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_systemRunning ? Colors.greenAccent : Colors.redAccent).withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: getResponsiveSize(4, 6, 8)),
                        Flexible(
                          child: Text(
                            _systemRunning ? 'En fonctionnement' : 'Arrêté',
                            style: TextStyle(
                              fontSize: getResponsiveSize(14, 16, 18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: getResponsivePadding(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$activeSectionsCount/${siteSections.length} sections actives',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: getResponsiveSize(11, 13, 15),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getResponsiveSize(16, 20, 24)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _buildStatusMetric('Température', '24.5°C', Icons.thermostat)),
              Flexible(child: _buildStatusMetric('pH', '7.1', Icons.science)),
              Flexible(child: _buildStatusMetric('Oxygène', '6.2 mg/L', Icons.air)),
            ],
          ),
          
          SizedBox(height: getResponsiveSize(12, 16, 20)),
          const Divider(
            color: Colors.white24,
            height: 1,
            thickness: 1,
          ),
          SizedBox(height: getResponsiveSize(12, 16, 20)),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickControlButton(
                  'Arrêter',
                  Icons.power_settings_new,
                  Colors.redAccent,
                  () => _sendCommand('/stop', 'Système arrêté avec succès'),
                ),
              ),
              SizedBox(width: getResponsiveSize(10, 16, 20)),
              Expanded(
                child: _buildQuickControlButton(
                  'Démarrer',
                  Icons.play_arrow,
                  Colors.greenAccent,
                  () => _sendCommand('/start', 'Système démarré avec succès'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionControlsCard() {
    return Container(
      padding: getResponsivePadding(all: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: Colors.blue, size: getResponsiveSize(18, 22, 26)),
              SizedBox(width: getResponsiveSize(8, 12, 16)),
              Text(
                'Contrôles de Détection IA',
                style: TextStyle(
                  fontSize: getResponsiveSize(16, 18, 20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: getResponsiveSize(16, 20, 24)),
          
          // Statut des détections
          Row(
            children: [
              Expanded(
                child: _buildDetectionStatus(
                  'Détection Fuites',
                  _isDetectionActive,
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
              SizedBox(width: getResponsiveSize(12, 16, 20)),
              Expanded(
                child: _buildDetectionStatus(
                  'Détection Maladies',
                  _isDiseaseDetectionActive,
                  Icons.warning_amber_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          SizedBox(height: getResponsiveSize(16, 20, 24)),
          
          // Boutons de contrôle
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  'Tout Démarrer',
                  Icons.play_arrow,
                  Colors.green,
                  () => _sendCommand('/start_detection', 'Détection générale activée'),
                ),
              ),
              SizedBox(width: getResponsiveSize(8, 10, 12)),
              Expanded(
                child: _buildControlButton(
                  'Maladies ON',
                  Icons.warning_amber_rounded,
                  Colors.orange,
                  () => _sendCommand('/start_disease_detection', 'Détection de maladies activée'),
                ),
              ),
            ],
          ),
          
          SizedBox(height: getResponsiveSize(8, 10, 12)),
          
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  'Tout Arrêter',
                  Icons.stop,
                  Colors.grey,
                  () => _sendCommand('/stop_detection', 'Détection arrêtée'),
                ),
              ),
              SizedBox(width: getResponsiveSize(8, 10, 12)),
              Expanded(
                child: _buildControlButton(
                  'Maladies OFF',
                  Icons.visibility_off,
                  Colors.grey,
                  () => _sendCommand('/stop_disease_detection', 'Détection de maladies désactivée'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionStatus(String title, bool isActive, IconData icon, Color color) {
    return Container(
      padding: getResponsivePadding(all: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? color : Colors.grey,
            size: getResponsiveSize(20, 24, 28),
          ),
          SizedBox(height: getResponsiveSize(4, 6, 8)),
          Text(
            title,
            style: TextStyle(
              fontSize: getResponsiveSize(11, 13, 15),
              fontWeight: FontWeight.w600,
              color: isActive ? color : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: getResponsiveSize(2, 4, 6)),
          Container(
            width: getResponsiveSize(6, 8, 10),
            height: getResponsiveSize(6, 8, 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      padding: getResponsivePadding(all: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: getResponsiveSize(18, 22, 26)),
              SizedBox(width: getResponsiveSize(8, 12, 16)),
              Text(
                'Alertes Actives',
                style: TextStyle(
                  fontSize: getResponsiveSize(16, 18, 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: getResponsiveSize(12, 16, 20)),
          
          if (_leakDetected || _diseaseDetected) ...[
            _buildAlertItem(
              _leakDetected ? '🚨 FUITE DÉTECTÉE' : '🐟 MALADIE DÉTECTÉE',
              _leakDetected 
                ? 'Une fuite a été détectée dans le système. Le moteur a été arrêté automatiquement pour éviter tout dommage.'
                : 'Une maladie a été détectée chez un ou plusieurs poissons. Intervention requise immédiatement.',
              _leakDetected ? Colors.red : Colors.orange,
              _leakDetected ? Icons.water_drop : Icons.warning_amber_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String message, Color color, IconData icon) {
    return Container(
      padding: getResponsivePadding(all: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: getResponsivePadding(all: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: getResponsiveSize(16, 20, 24)),
          ),
          SizedBox(width: getResponsiveSize(8, 12, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: getResponsiveSize(12, 14, 16),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: getResponsiveSize(2, 4, 6)),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: getResponsiveSize(10, 12, 14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: getResponsivePadding(all: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: getResponsiveSize(18, 22, 26),
          ),
        ),
        SizedBox(height: getResponsiveSize(6, 8, 10)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: getResponsiveSize(16, 18, 20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: getResponsiveSize(2, 4, 6)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: getResponsiveSize(12, 14, 16),
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickControlButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: getResponsivePadding(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: getResponsiveSize(18, 20, 22),
            ),
            SizedBox(width: getResponsiveSize(6, 8, 10)),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: getResponsiveSize(14, 16, 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteSection(String siteName, Map<String, dynamic> siteData) {
    final bool isActive = siteData["isActive"] ?? false;
    final Color statusColor = isActive ? Colors.green : Colors.orange;
    final String statusText = isActive ? "Actif" : "En maintenance";
    
    return Container(
      margin: EdgeInsets.only(bottom: getResponsiveSize(16, 20, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: getResponsivePadding(all: 16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: getResponsivePadding(all: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          siteName,
                          style: TextStyle(
                            fontSize: getResponsiveSize(14, 16, 18),
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      SizedBox(width: getResponsiveSize(8, 12, 16)),
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: getResponsiveSize(16, 18, 20),
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: getResponsivePadding(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        size: getResponsiveSize(14, 16, 18),
                        color: const Color(0xFF1A237E),
                      ),
                      SizedBox(width: getResponsiveSize(2, 4, 6)),
                      Text(
                        'Configurer',
                        style: TextStyle(
                          fontSize: getResponsiveSize(10, 12, 14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: getResponsivePadding(all: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: getResponsivePadding(all: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paramètres en temps réel',
                        style: TextStyle(
                          fontSize: getResponsiveSize(14, 16, 18),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: getResponsiveSize(12, 16, 20)),
                      _buildInfoRow("Température", siteData["temperature"], Icons.thermostat, Colors.orange),
                      _buildInfoRow("Niveau de pH", siteData["phLevel"], Icons.science, Colors.blue),
                      _buildInfoRow("Niveau d'oxygène", siteData["oxygenLevel"], Icons.air, Colors.green),
                    ],
                  ),
                ),
                
                SizedBox(height: getResponsiveSize(16, 20, 24)),
                
                Container(
                  padding: getResponsivePadding(all: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Évolution sur 7 jours",
                              style: TextStyle(
                                fontSize: getResponsiveSize(14, 16, 18),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: getResponsiveSize(8, 12, 16)),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: _screenWidth * 0.4,
                            ),
                            padding: getResponsivePadding(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedChartType,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: getResponsiveSize(14, 16, 18),
                                ),
                                isDense: true,
                                items: [
                                  "Température",
                                  "pH",
                                  "Oxygène",
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: getResponsiveSize(11, 13, 15),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedChartType = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getResponsiveSize(12, 16, 20)),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final aspectRatio = _screenWidth < 360 ? 1.2 : 1.5;
                          final chartHeight = math.min(
                            constraints.maxWidth / aspectRatio,
                            _screenHeight * 0.3,
                          );
                          
                          return SizedBox(
                            height: chartHeight,
                            child: _buildLineChart(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: getResponsivePadding(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: getResponsivePadding(all: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: getResponsiveSize(18, 22, 26)),
          ),
          SizedBox(width: getResponsiveSize(8, 12, 16)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: getResponsiveSize(14, 16, 18),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: getResponsivePadding(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: getResponsiveSize(14, 16, 18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: getResponsiveSize(18, 24, 28)),
      label: Text(
        label,
        style: TextStyle(fontSize: getResponsiveSize(12, 14, 16)),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: getResponsivePadding(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> chartData;
    Color chartColor;
    String yLabel;
    double minY, maxY;
    
    switch (_selectedChartType) {
      case "pH":
        chartData = phData;
        chartColor = Colors.blue;
        yLabel = "pH";
        minY = 6.5;
        maxY = 7.5;
        break;
      case "Oxygène":
        chartData = oxygenData;
        chartColor = Colors.green;
        yLabel = "mg/L";
        minY = 5.0;
        maxY = 7.0;
        break;
      case "Température":
      default:
        chartData = temperatureData;
        chartColor = Colors.orange;
        yLabel = "°C";
        minY = 20;
        maxY = 28;
    }

    double dataMinY = chartData.map((spot) => spot.y).reduce(math.min);
    double dataMaxY = chartData.map((spot) => spot.y).reduce(math.max);
    
    minY = math.min(minY, dataMinY - 0.5);
    maxY = math.max(maxY, dataMaxY + 0.5);

    return Padding(
      padding: getResponsivePadding(
        right: 12, 
        left: 8,
        top: 16,
        bottom: 12
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              tooltipRoundedRadius: 8,
              tooltipPadding: getResponsivePadding(all: 8),
              tooltipBorder: BorderSide(
                color: chartColor.withOpacity(0.2),
                width: 1,
              ),
              getTooltipItems: (List<LineBarSpot> spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} $yLabel',
                    TextStyle(
                      color: chartColor,
                      fontWeight: FontWeight.bold,
                      fontSize: getResponsiveSize(12, 14, 16),
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _selectedChartType == "pH" ? 0.2 : 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: getResponsiveSize(20, 30, 40),
                interval: _screenWidth < 360 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                  int index = value.toInt();
                  if (index >= 0 && index < days.length) {
                    if (_screenWidth < 360 && (index % 2 != 0) && index != 6) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: getResponsiveSize(6, 8, 10)),
                      child: Text(
                        days[index], 
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: getResponsiveSize(10, 12, 14), 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: getResponsiveSize(36, 46, 56),
                interval: _selectedChartType == "pH" ? 0.2 : 2,
                getTitlesWidget: (value, meta) {
                  if (_selectedChartType == "pH") {
                    if ((value * 10) % 2 == 0) {
                      return Padding(
                        padding: EdgeInsets.only(right: getResponsiveSize(4, 8, 12)),
                        child: Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: getResponsiveSize(10, 12, 14),
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      );
                    }
                  } else {
                    if (value % 2 == 0) {
                      return Padding(
                        padding: EdgeInsets.only(right: getResponsiveSize(4, 8, 12)),
                        child: Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: getResponsiveSize(10, 12, 14),
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              left: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          minX: 0,
          maxX: 6,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: chartData,
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: chartColor,
              barWidth: getResponsiveSize(2, 3, 4),
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: getResponsiveSize(3, 4, 5),
                    color: Colors.white,
                    strokeWidth: getResponsiveSize(1.5, 2, 2.5),
                    strokeColor: chartColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    chartColor.withOpacity(0.3),
                    chartColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: getResponsivePadding(bottom: 16, right: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _refreshData,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: getResponsivePadding(all: 16),
            child: Icon(Icons.refresh, color: Colors.white, size: getResponsiveSize(24, 26, 28)),
          ),
        ),
      ),
    );
  }
  
  Widget _buildVideoStreamCard() {
    return Container(
      padding: getResponsivePadding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam, color: Colors.blue, size: getResponsiveSize(18, 22, 26)),
              SizedBox(width: getResponsiveSize(8, 12, 16)),
              Text(
                'Flux vidéo avec IA',
                style: TextStyle(
                  fontSize: getResponsiveSize(14, 16, 18),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const Spacer(),
              Container(
                padding: getResponsivePadding(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isDetectionActive || _isDiseaseDetectionActive) ? 
                         Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: (_isDetectionActive || _isDiseaseDetectionActive) ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: getResponsiveSize(4, 6, 8)),
                    Text(
                      (_isDetectionActive || _isDiseaseDetectionActive) ? 'IA Active' : 'IA Inactive',
                      style: TextStyle(
                        fontSize: getResponsiveSize(10, 12, 14),
                        fontWeight: FontWeight.w600,
                        color: (_isDetectionActive || _isDiseaseDetectionActive) ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: getResponsiveSize(12, 16, 20)),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _isStreamAvailable
                  ? MjpegView(streamUrl: "http://$raspberryPiIP:5000/video_feed")
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off, color: Colors.grey[400], size: getResponsiveSize(40, 50, 60)),
                            SizedBox(height: getResponsiveSize(8, 12, 16)),
                            Text(
                              "Flux vidéo non disponible",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: getResponsiveSize(12, 14, 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Notifications sheet with proper overflow handling
  Widget _buildNotificationsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle and header
              Container(
                padding: getResponsivePadding(vertical: 16),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Padding(
                padding: getResponsivePadding(
                  horizontal: 20,
                  bottom: 16
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: const Color(0xFF1A237E),
                            size: getResponsiveSize(20, 24, 28),
                          ),
                          SizedBox(width: getResponsiveSize(8, 12, 16)),
                          Flexible(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: getResponsiveSize(18, 22, 26),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_unreadCount > 0) ...[
                            SizedBox(width: getResponsiveSize(8, 12, 16)),
                            Container(
                              padding: getResponsivePadding(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // FIXED: Overflow issue with proper layout
                    Flexible(
                      child: InkWell(
                        onTap: () {
                          _markAllAsRead();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: math.max(8.0, _screenWidth * 0.02),
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: getResponsiveSize(14, 16, 18),
                                color: const Color(0xFF1A237E),
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _screenWidth < 360 ? 'Lu' : 'Marquer lu',
                                  style: TextStyle(
                                    fontSize: getResponsiveSize(10, 12, 14),
                                    color: const Color(0xFF1A237E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: getResponsiveSize(60, 80, 100),
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: getResponsiveSize(16, 20, 24)),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                fontSize: getResponsiveSize(16, 18, 20),
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: getResponsiveSize(8, 12, 16)),
                            Text(
                              'Les alertes apparaîtront ici lors des détections',
                              style: TextStyle(
                                fontSize: getResponsiveSize(12, 14, 16),
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: getResponsivePadding(horizontal: 16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: getResponsivePadding(vertical: 6),
      padding: getResponsivePadding(all: 16),
      decoration: BoxDecoration(
        color: notification.isNew 
            ? notification.severityColor.withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isNew 
              ? notification.severityColor.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: notification.isNew ? [
          BoxShadow(
            color: notification.severityColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: getResponsivePadding(all: 10),
            decoration: BoxDecoration(
              color: notification.severityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.severityIcon,
              color: notification.severityColor,
              size: getResponsiveSize(18, 22, 26),
            ),
          ),
          SizedBox(width: getResponsiveSize(12, 16, 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: getResponsiveSize(14, 16, 18),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (notification.isNew)
                      Container(
                        width: getResponsiveSize(8, 10, 12),
                        height: getResponsiveSize(8, 10, 12),
                        decoration: BoxDecoration(
                          color: notification.severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: getResponsiveSize(4, 6, 8)),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: getResponsiveSize(12, 14, 16),
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: getResponsiveSize(6, 8, 10)),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: getResponsiveSize(12, 14, 16),
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: getResponsiveSize(4, 6, 8)),
                    Text(
                      _formatNotificationTime(notification.timestamp),
                      style: TextStyle(
                        fontSize: getResponsiveSize(10, 12, 14),
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    // FIXED: Proper layout for type label
                    Flexible(
                      child: Container(
                        padding: getResponsivePadding(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: notification.severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getNotificationTypeLabel(notification.type),
                          style: TextStyle(
                            fontSize: getResponsiveSize(8, 10, 12),
                            fontWeight: FontWeight.w600,
                            color: notification.severityColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'disease':
        return 'MALADIE';
      case 'leak':
        return 'FUITE';
      case 'system':
        return 'SYSTÈME';
      case 'detection':
        return 'DÉTECTION';
      default:
        return 'INFO';
    }
  }
}

// Wave painter for background decoration
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.7,
      size.width * 0.5, size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.9,
      size.width, size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
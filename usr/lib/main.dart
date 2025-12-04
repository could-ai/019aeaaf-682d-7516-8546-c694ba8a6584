import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inizializza la formattazione delle date per l'italiano
  await initializeDateFormatting('it_IT', null);
  
  // Imposta la status bar trasparente per un look più moderno
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meteo Galliera Veneta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4CFF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto', // Default flutter font, pulito
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WeatherHomePage(),
      },
    );
  }
}

// --- MODELLI DATI ---

enum WeatherCondition { sunny, cloudy, rain, storm, snow }

class DailyForecast {
  final DateTime date;
  final int minTemp;
  final int maxTemp;
  final WeatherCondition condition;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
  });
}

// --- SERVIZIO MOCK (Simulazione Dati) ---

class WeatherService {
  // Simula una chiamata API per ottenere i dati di Galliera Veneta
  Future<List<DailyForecast>> getForecast() async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simula latenza rete
    
    final now = DateTime.now();
    final random = Random();

    // Generiamo 5 giorni di dati realistici
    return List.generate(5, (index) {
      final date = now.add(Duration(days: index));
      
      // Logica semplice per variare il meteo
      WeatherCondition condition;
      int baseTemp = 20 - (index * 2); // Temperatura scende leggermente
      
      if (index == 0) {
        condition = WeatherCondition.sunny;
        baseTemp = 24;
      } else if (index == 1) {
        condition = WeatherCondition.cloudy;
        baseTemp = 22;
      } else if (index == 2) {
        condition = WeatherCondition.rain;
        baseTemp = 19;
      } else if (index == 3) {
        condition = WeatherCondition.storm;
        baseTemp = 18;
      } else {
        condition = WeatherCondition.sunny;
        baseTemp = 21;
      }

      return DailyForecast(
        date: date,
        minTemp: baseTemp - 8 + random.nextInt(3),
        maxTemp: baseTemp + random.nextInt(3),
        condition: condition,
      );
    });
  }
}

// --- UI PRINCIPALE ---

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> with SingleTickerProviderStateMixin {
  final WeatherService _service = WeatherService();
  List<DailyForecast>? _forecasts;
  bool _isLoading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await _service.getForecast();
    if (mounted) {
      setState(() {
        _forecasts = data;
        _isLoading = false;
      });
    }
  }

  // Helper per ottenere l'icona e il colore in base al meteo
  (IconData, Color, String) _getWeatherAssets(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return (Icons.wb_sunny_rounded, const Color(0xFFFFD54F), "Soleggiato");
      case WeatherCondition.cloudy:
        return (Icons.cloud_rounded, const Color(0xFF90A4AE), "Nuvoloso");
      case WeatherCondition.rain:
        return (Icons.water_drop_rounded, const Color(0xFF4FC3F7), "Pioggia");
      case WeatherCondition.storm:
        return (Icons.thunderstorm_rounded, const Color(0xFF9575CD), "Temporale");
      case WeatherCondition.snow:
        return (Icons.ac_unit_rounded, const Color(0xFFE0F7FA), "Neve");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sfondo gradiente dinamico
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 18, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              "Galliera Veneta, IT",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50), // Blu scuro notte
              Color(0xFF4CA1AF), // Blu petrolio
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final current = _forecasts!.first;
    final (icon, iconColor, label) = _getWeatherAssets(current.condition);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // --- SEZIONE METEO ATTUALE ---
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animazione Icona Meteo
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        icon,
                        size: 120,
                        color: iconColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Temperatura Grande
                Text(
                  "${current.maxTemp}°",
                  style: const TextStyle(
                    fontSize: 90,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("H: ${current.maxTemp}°", style: const TextStyle(color: Colors.white70)),
                    const SizedBox(width: 15),
                    Text("L: ${current.minTemp}°", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),

          // --- LISTA PREVISIONI 5 GIORNI ---
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Prossimi 5 Giorni",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _forecasts!.length,
                      itemBuilder: (context, index) {
                        final day = _forecasts![index];
                        final (dayIcon, dayColor, _) = _getWeatherAssets(day.condition);
                        
                        // Animazione ingresso lista
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeOutQuad,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Giorno
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    index == 0 
                                      ? "Oggi" 
                                      : DateFormat('EEEE', 'it_IT').format(day.date).capitalize(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Icona
                                Icon(dayIcon, color: dayColor, size: 28),
                                // Temperature
                                SizedBox(
                                  width: 100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${day.maxTemp}°",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "${day.minTemp}°",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}

// Extension per capitalizzare la prima lettera del giorno (es. "lunedì" -> "Lunedì")
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

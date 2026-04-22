import 'dart:async';
import 'package:flutter/material.dart';
import 'models/dog.dart';
import 'models/walk_record.dart';
import 'services/storage_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'services/location_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'models/route_point.dart';
import 'services/weather_service.dart';
import 'screens/calendar_screen.dart';
import 'services/reminder_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  // Initialize Flutter bindings and app services before launching the app.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await StorageService.init();
  await ReminderService.init();
  await ReminderService.requestPermission();
  runApp(const PawTrackApp());
}

// Root widget of the app, setting up theme and shared app state.
class PawTrackApp extends StatelessWidget {
  const PawTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateContainer(
      child: MaterialApp(
        title: 'PawTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// Shared app state wrapper used to access dogs and walk records across screens.
class AppData extends InheritedWidget {
  final _AppDataState state;

  const AppData({
    super.key,
    required this.state,
    required super.child,
  });

  static _AppDataState of(BuildContext context) {
    final AppData? result =
    context.dependOnInheritedWidgetOfExactType<AppData>();
    assert(result != null, 'No AppData found in context');
    return result!.state;
  }

  @override
  bool updateShouldNotify(AppData oldWidget) => true;
}

// Stateful container that stores and updates the app's shared data.
class AppStateContainer extends StatefulWidget {
  final Widget child;

  const AppStateContainer({super.key, required this.child});

  @override
  State<AppStateContainer> createState() => _AppDataState();
}

// Holds the main in-memory state for dogs and walking history, synced with local storage.
class _AppDataState extends State<AppStateContainer> {
  late List<Dog> dogs;
  late List<WalkRecord> records;

  // Load saved dogs and walk records when the app starts.
  @override
  void initState() {
    super.initState();

    dogs = StorageService.loadDogs();
    records = StorageService.loadWalkRecords();

    if (dogs.isEmpty) {
      dogs = [
        Dog(
          id: '1',
          name: 'Milo',
          breed: 'Corgi',
          age: 3,
          weightKg: 12.0,
          targetDistanceKm: 2.0,
          imagePath: null,
        ),
      ];
      StorageService.saveDogs(dogs);
    }
  }

  Future<void> addDog(Dog dog) async {
    // Add a new dog and always save locally first.
    setState(() {
      dogs.add(dog);
    });

    await StorageService.saveDogs(dogs);

    // Try cloud sync, but do not block the app if Firebase is not ready yet.
    try {
      await FirebaseService.syncDogs(dogs);
    } catch (e) {
      print('Firebase dog sync failed: $e');
    }
  }

  Future<void> updateDog(Dog updatedDog) async {
    // Update an existing dog's information and save changes locally first.
    setState(() {
      final index = dogs.indexWhere((dog) => dog.id == updatedDog.id);
      if (index != -1) {
        dogs[index] = updatedDog;
      }
    });

    await StorageService.saveDogs(dogs);

    // Try cloud sync, but do not block the app if Firebase is not ready yet.
    try {
      await FirebaseService.syncDogs(dogs);
    } catch (e) {
      print('Firebase dog update sync failed: $e');
    }
  }

  Future<void> addWalkRecord(WalkRecord record) async {
    // Save a completed walk record locally first.
    setState(() {
      records.add(record);
    });

    await StorageService.saveWalkRecords(records);

    // Try cloud sync, but do not block the app if Firebase is not ready yet.
    try {
      await FirebaseService.syncWalkRecords(records);
    } catch (e) {
      print('Firebase walk sync failed: $e');
    }
  }

  Future<void> deleteDog(String dogId) async {
    // Delete a dog and remove all related walk records locally first.
    setState(() {
      dogs.removeWhere((dog) => dog.id == dogId);
      records.removeWhere((record) => record.dogId == dogId);
    });

    await StorageService.saveDogs(dogs);
    await StorageService.saveWalkRecords(records);

    // Try cloud sync, but do not block the app if Firebase is not ready yet.
    try {
      await FirebaseService.syncDogs(dogs);
      await FirebaseService.syncWalkRecords(records);
    } catch (e) {
      print('Firebase dog delete sync failed: $e');
    }
  }

  Future<void> deleteWalkRecord(WalkRecord record) async {
    // Delete one walk record locally first.
    setState(() {
      records.remove(record);
    });

    await StorageService.saveWalkRecords(records);

    // Try cloud sync, but do not block the app if Firebase is not ready yet.
    try {
      await FirebaseService.syncWalkRecords(records);
    } catch (e) {
      print('Firebase walk delete sync failed: $e');
    }
  }

  // Return all walk records that belong to a specific dog.
  List<WalkRecord> recordsForDog(String dogId) {
    return records.where((r) => r.dogId == dogId).toList();
  }

  // Check whether a dog already has a walk recorded for today.
  bool walkedToday(String dogId) {
    final today = DateTime.now();
    return records.any((r) =>
    r.dogId == dogId &&
        r.endTime.year == today.year &&
        r.endTime.month == today.month &&
        r.endTime.day == today.day);
  }

  @override
  Widget build(BuildContext context) {
    return AppData(state: this, child: widget.child);
  }
}

// Intro splash screen shown briefly before entering the main dog list.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically move from the splash screen to the home screen after a short delay.
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DogListScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 96, color: Colors.teal.shade700),
            const SizedBox(height: 16),
            const Text(
              'PawTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Dog walking tracker'),
          ],
        ),
      ),
    );
  }
}

/// Home screen showing all dog profiles and their daily walking status.
class DogListScreen extends StatefulWidget {
  const DogListScreen({super.key});

  @override
  State<DogListScreen> createState() => _DogListScreenState();
}

class _DogListScreenState extends State<DogListScreen> {
  @override
  void initState() {
    super.initState();
    checkWalkReminder();
  }

  /// Show a reminder if it is evening and some dogs have not been walked today.
  Future<void> checkWalkReminder() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final appState = AppData.of(context);
    final now = DateTime.now();

    // Only show reminder in the evening.
    if (now.hour < 18) return;

    final unwalkedDogs = appState.dogs.where((dog) {
      return !appState.walkedToday(dog.id);
    }).toList();

    if (unwalkedDogs.isNotEmpty) {
      final names = unwalkedDogs.map((d) => d.name).join(', ');

      await ReminderService.showWalkReminder(
        title: 'Dog walk reminder',
        body: 'You have not walked $names today. Time for a walk?',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);
    final dogs = appState.dogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dogs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalendarScreen(records: appState.records),
                ),
              );
            },
          ),
        ],
      ),
      body: dogs.isEmpty
          ? const Center(
        child: Text('No dogs yet. Tap + to add one.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: dogs.length,
        itemBuilder: (context, index) {
          final dog = dogs[index];
          final walkedToday = appState.walkedToday(dog.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: dog.imagePath != null
                    ? FileImage(File(dog.imagePath!))
                    : null,
                child: dog.imagePath == null
                    ? const Icon(Icons.pets)
                    : null,
              ),
              title: Text(dog.name),
              subtitle: Text(
                '${dog.breed} • Goal ${dog.targetDistanceKm.toStringAsFixed(1)} km\n'
                    '${walkedToday ? "Walked today ✅" : "Not walked today ❗"}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Ask the user to confirm before permanently deleting data.
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete dog'),
                          content: Text(
                            'Delete ${dog.name} and all walk records?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await appState.deleteDog(dog.id);
                      }
                    },
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DogDetailScreen(dogId: dog.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Form screen used to create a new dog profile.
class AddDogScreen extends StatefulWidget {
  const AddDogScreen({super.key});

  @override
  State<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends State<AddDogScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final targetController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  File? selectedImage;

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    targetController.dispose();
    super.dispose();
    ageController.dispose();
    weightController.dispose();
  }

  // Open the device gallery and let the user choose a photo for the dog.
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Dog')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Dog name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the dog name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Choose Dog Photo'),
              ),
              const SizedBox(height: 12),
              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (selectedImage != null) const SizedBox(height: 12),
              TextFormField(
                controller: breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the breed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target distance (km)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a target distance';
                  }
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight in kg (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 20),
              FilledButton(
                // Validate the form, create a dog object, and save it to local storage.
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final dog = Dog(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      breed: breedController.text.trim(),
                      age: ageController.text.trim().isEmpty
                          ? null
                          : int.tryParse(ageController.text.trim()),
                      weightKg: weightController.text.trim().isEmpty
                          ? null
                          : double.tryParse(weightController.text.trim()),
                      targetDistanceKm: double.parse(targetController.text.trim()),
                      imagePath: selectedImage?.path,
                    );

                    await appState.addDog(dog);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Save Dog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Detail screen for one dog, showing profile info, weather advice, stats, and actions.
class DogDetailScreen extends StatefulWidget {
  final String dogId;

  const DogDetailScreen({super.key, required this.dogId});

  @override
  State<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends State<DogDetailScreen> {
  WeatherInfo? weatherInfo;
  bool isLoadingWeather = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  // Fetch current weather based on the user's location and generate a walking suggestion.
  Future<void> loadWeather() async {
    try {
      final permissionGranted =
      await LocationService.checkAndRequestPermission();

      if (!permissionGranted) {
        setState(() {
          isLoadingWeather = false;
          weatherError = 'Location permission denied or GPS is off.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final info = await WeatherService.fetchWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        weatherInfo = info;
        isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
        weatherError = 'Could not load weather information.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);
    final dog = appState.dogs.firstWhere((d) => d.id == widget.dogId);
    final dogRecords = appState.recordsForDog(widget.dogId);

    // Calculate simple walking statistics for the last 7 days.
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final recentRecords = dogRecords.where((record) {
      return record.endTime.isAfter(sevenDaysAgo);
    }).toList();

    final totalDistanceLast7Days = recentRecords.fold<double>(
      0,
          (sum, record) => sum + record.distanceKm,
    );

    final totalWalksLast7Days = recentRecords.length;
    final goalsReachedLast7Days = recentRecords.where((r) => r.goalReached).length;

    return Scaffold(
      appBar: AppBar(title: Text(dog.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          dog.imagePath != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(dog.imagePath!),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
              : Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: const Center(
              child: Icon(
                Icons.pets,
                size: 80,
                color: Colors.teal,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dog.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            dog.breed,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoadingWeather
                  ? const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading weather...'),
                ],
              )
                  : weatherError != null
                  ? Text(
                weatherError!,
                style: const TextStyle(color: Colors.red),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weather Advice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Condition: ${weatherInfo!.description}'),
                  Text(
                    'Temperature: ${weatherInfo!.temperature.toStringAsFixed(1)}°C',
                  ),
                  Text(
                    'Rain chance: ${weatherInfo!.precipitationProbability}%',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    weatherInfo!.advice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Target distance'),
              subtitle: Text('${dog.targetDistanceKm.toStringAsFixed(1)} km'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Walk records'),
              subtitle: Text('${dogRecords.length} total'),
            ),
          ),

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last 7 Days',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Walks',
                          value: '$totalWalksLast7Days',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Distance',
                          value: '${totalDistanceLast7Days.toStringAsFixed(2)} km',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryTile(
                    label: 'Goals reached',
                    value: '$goalsReachedLast7Days',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalkTrackingScreen(dogId: dog.id),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Walk'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalkHistoryScreen(dogId: dog.id),
                ),
              );
            },
            icon: const Icon(Icons.list),
            label: const Text('View Walk History'),
          ),
        ],
      ),
    );
  }
}

// Live walking screen that tracks time, GPS distance, route points, and progress toward the goal.
class WalkTrackingScreen extends StatefulWidget {
  final String dogId;

  const WalkTrackingScreen({super.key, required this.dogId});

  @override
  State<WalkTrackingScreen> createState() => _WalkTrackingScreenState();
}

class _WalkTrackingScreenState extends State<WalkTrackingScreen> {
  Timer? timer;
  StreamSubscription<Position>? positionSubscription;

  int elapsedSeconds = 0;
  double distanceKm = 0.0;
  bool isPaused = false;
  bool hasLocationPermission = false;
  String statusMessage = 'Preparing walk...';

  late DateTime startTime;
  Position? lastPosition;
  List<RoutePoint> routePoints = [];

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    startWalkTracking();
  }

  @override
  void dispose() {
    timer?.cancel();
    positionSubscription?.cancel();
    super.dispose();
  }

  // Start live walk tracking by requesting location access and listening for position updates.
  Future<void> startWalkTracking() async {
    final permissionGranted =
    await LocationService.checkAndRequestPermission();

    if (!permissionGranted) {
      setState(() {
        hasLocationPermission = false;
        statusMessage = 'Location permission denied or GPS is off.';
      });
      return;
    }

    setState(() {
      hasLocationPermission = true;
      statusMessage = 'Tracking your walk...';
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        setState(() {
          elapsedSeconds++;
        });
      }
    });

    // Listen to live GPS updates and build the route while accumulating walking distance.
    positionSubscription = LocationService.getPositionStream().listen((position) {
      if (isPaused) return;

      final newPoint = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      if (lastPosition != null) {
        final meters = LocationService.distanceBetween(lastPosition!, position);

        if (meters > 0 && meters < 100) {
          setState(() {
            distanceKm += meters / 1000;
            routePoints.add(newPoint);
          });
        }
      } else {
        setState(() {
          routePoints.add(newPoint);
        });
      }

      lastPosition = position;
    });
  }

  String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);
    final dog = appState.dogs.firstWhere((d) => d.id == widget.dogId);

    final calories = distanceKm * (dog.weightKg ?? 10) * 0.8;
    final remaining = (dog.targetDistanceKm - distanceKm).clamp(0, 9999);

    return Scaffold(
      appBar: AppBar(title: Text('Walking ${dog.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: routePoints.isNotEmpty
                    ? FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      routePoints.last.latitude,
                      routePoints.last.longitude,
                    ),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.pawtrack',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints
                              .map((point) => LatLng(point.latitude, point.longitude))
                              .toList(),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            routePoints.last.latitude,
                            routePoints.last.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasLocationPermission
                              ? Icons.location_on
                              : Icons.location_off,
                          size: 64,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusMessage,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (isPaused)
                          const Text(
                            'Walk paused',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Time',
                    value: formatTime(elapsedSeconds),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Distance',
                    value: '${distanceKm.toStringAsFixed(2)} km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Calories',
                    value: calories.toStringAsFixed(0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Remaining',
                    value: '${remaining.toStringAsFixed(2)} km',
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        isPaused = !isPaused;
                      });
                    },
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(isPaused ? 'Resume' : 'Pause'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    // Finish the walk, save the final record, and open the summary screen.
                    onPressed: () async {
                      timer?.cancel();

                      final endTime = DateTime.now();
                      final goalReached = distanceKm >= dog.targetDistanceKm;

                      await appState.addWalkRecord(
                        WalkRecord(
                          dogId: dog.id,
                          startTime: startTime,
                          endTime: endTime,
                          distanceKm: distanceKm,
                          calories: calories,
                          goalReached: goalReached,
                          routePoints: routePoints,
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WalkSummaryScreen(
                            dogId: dog.id,
                            startTime: startTime,
                            endTime: endTime,
                            distanceKm: distanceKm,
                            calories: calories,
                            goalReached: goalReached,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('End Walk'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Summary screen showing the result of one completed walk.
class WalkSummaryScreen extends StatelessWidget {
  final String dogId;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final double calories;
  final bool goalReached;

  const WalkSummaryScreen({
    super.key,
    required this.dogId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.calories,
    required this.goalReached,
  });

  String durationText() {
    final duration = endTime.difference(startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes} min ${seconds} sec';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);
    final dog = appState.dogs.firstWhere((d) => d.id == dogId);
    final difference = distanceKm - dog.targetDistanceKm;

    return Scaffold(
      appBar: AppBar(title: const Text('Walk Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: goalReached ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goalReached ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    goalReached ? Icons.celebration : Icons.pets,
                    size: 100,
                    color: goalReached ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${dog.name} finished the walk!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goalReached
                        ? 'Great job! The walking goal was reached.'
                        : 'Nice walk! The goal was not reached this time.',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    goalReached
                        ? 'Exceeded goal by ${difference.toStringAsFixed(2)} km'
                        : 'Short of goal by ${(-difference).toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SummaryTile(label: 'Duration', value: durationText()),
            _SummaryTile(
              label: 'Distance',
              value: '${distanceKm.toStringAsFixed(2)} km',
            ),
            _SummaryTile(
              label: 'Calories',
              value: calories.toStringAsFixed(0),
            ),
            _SummaryTile(
              label: 'Goal reached',
              value: goalReached ? 'Yes ✅' : 'No ❌',
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DogListScreen(),
                  ),
                      (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// History screen listing all saved walks for one dog.
class WalkHistoryScreen extends StatelessWidget {
  final String dogId;

  const WalkHistoryScreen({super.key, required this.dogId});

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);
    final records = appState.recordsForDog(dogId).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Walk History')),
      body: records.isEmpty
          ? const Center(child: Text('No walks recorded yet.'))
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final r = records[index];
          return ListTile(
            leading: Icon(
              r.goalReached ? Icons.check_circle : Icons.directions_walk,
              color: r.goalReached ? Colors.green : Colors.blue,
            ),
            title: Text('${r.distanceKm.toStringAsFixed(2)} km'),
            subtitle: Text(
              '${r.startTime.year}-${r.startTime.month.toString().padLeft(2, '0')}-${r.startTime.day.toString().padLeft(2, '0')}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.goalReached ? 'Goal met' : 'Not met'),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete walk record'),
                        content: const Text('Are you sure you want to delete this walk?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await appState.deleteWalkRecord(r);
                    }
                  },
                ),
              ],
            ),
            // Open the saved route replay screen for this walk record.
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteReplayScreen(record: r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 90,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Replay screen showing the saved route of a previous walk on the map.
class RouteReplayScreen extends StatelessWidget {
  final WalkRecord record;

  const RouteReplayScreen({super.key, required this.record});

  String durationText() {
    final duration = record.endTime.difference(record.startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes} min ${seconds} sec';
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = record.routePoints.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Walk Route Replay')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasRoute
                    ? FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      record.routePoints.last.latitude,
                      record.routePoints.last.longitude,
                    ),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.pawtrack',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: record.routePoints
                              .map((point) =>
                              LatLng(point.latitude, point.longitude))
                              .toList(),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            record.routePoints.first.latitude,
                            record.routePoints.first.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.flag,
                            color: Colors.green,
                            size: 36,
                          ),
                        ),
                        Marker(
                          point: LatLng(
                            record.routePoints.last.latitude,
                            record.routePoints.last.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    : Container(
                  color: Colors.teal.shade50,
                  child: const Center(
                    child: Text('No route data available'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SummaryTile(
              label: 'Distance',
              value: '${record.distanceKm.toStringAsFixed(2)} km',
            ),
            _SummaryTile(
              label: 'Duration',
              value: durationText(),
            ),
            _SummaryTile(
              label: 'Calories',
              value: record.calories.toStringAsFixed(0),
            ),
            _SummaryTile(
              label: 'Goal reached',
              value: record.goalReached ? 'Yes ✅' : 'No ❌',
            ),
          ],
        ),
      ),
    );
  }
}
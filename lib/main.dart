import 'dart:async';
import 'package:flutter/material.dart';
import 'models/dog.dart';
import 'models/walk_record.dart';
import 'services/storage_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const PawTrackApp());
}

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

class AppStateContainer extends StatefulWidget {
  final Widget child;

  const AppStateContainer({super.key, required this.child});

  @override
  State<AppStateContainer> createState() => _AppDataState();
}

class _AppDataState extends State<AppStateContainer> {
  late List<Dog> dogs;
  late List<WalkRecord> records;

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
    setState(() {
      dogs.add(dog);
    });
    await StorageService.saveDogs(dogs);
  }

  Future<void> updateDog(Dog updatedDog) async {
    setState(() {
      final index = dogs.indexWhere((dog) => dog.id == updatedDog.id);
      if (index != -1) {
        dogs[index] = updatedDog;
      }
    });
    await StorageService.saveDogs(dogs);
  }

  Future<void> addWalkRecord(WalkRecord record) async {
    setState(() {
      records.add(record);
    });
    await StorageService.saveWalkRecords(records);
  }

  List<WalkRecord> recordsForDog(String dogId) {
    return records.where((r) => r.dogId == dogId).toList();
  }

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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
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

class DogListScreen extends StatelessWidget {
  const DogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);
    final dogs = appState.dogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dogs'),
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
                child: dog.imagePath == null ? const Icon(Icons.pets) : null,
              ),
              title: Text(dog.name),
              subtitle: Text(
                '${dog.breed} • Goal ${dog.targetDistanceKm.toStringAsFixed(1)} km\n'
                    '${walkedToday ? "Walked today ✅" : "Not walked today ❗"}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
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

class DogDetailScreen extends StatelessWidget {
  final String dogId;

  const DogDetailScreen({super.key, required this.dogId});

  @override
  Widget build(BuildContext context) {
    final appState = AppData.of(context);
    final dog = appState.dogs.firstWhere((d) => d.id == dogId);
    final dogRecords = appState.recordsForDog(dogId);

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

    positionSubscription = LocationService.getPositionStream().listen((position) {
      if (isPaused) return;

      if (lastPosition != null) {
        final meters = LocationService.distanceBetween(lastPosition!, position);

        if (meters > 0 && meters < 100) {
          setState(() {
            distanceKm += meters / 1000;
          });
        }
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
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasLocationPermission ? Icons.location_on : Icons.location_off,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Walk Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              goalReached ? Icons.celebration : Icons.pets,
              size: 96,
              color: goalReached ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              '${dog.name} finished the walk!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
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
            FilledButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DogListScreen(),
                  ),
                      (route) => false,
                );
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

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
            trailing: Text(r.goalReached ? 'Goal met' : 'Not met'),
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
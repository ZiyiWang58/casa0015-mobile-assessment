import 'dart:async';
import 'package:flutter/material.dart';

void main() {
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

class Dog {
  String id;
  String name;
  String breed;
  double targetDistanceKm;
  String photoUrl;

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.targetDistanceKm,
    required this.photoUrl,
  });
}

class WalkRecord {
  String dogId;
  DateTime startTime;
  DateTime endTime;
  double distanceKm;
  double calories;
  bool goalReached;

  WalkRecord({
    required this.dogId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.calories,
    required this.goalReached,
  });
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
  final List<Dog> dogs = [
    Dog(
      id: '1',
      name: 'Milo',
      breed: 'Corgi',
      targetDistanceKm: 2.0,
      photoUrl:
      'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800',
    ),
  ];

  final List<WalkRecord> records = [];

  void addDog(Dog dog) {
    setState(() {
      dogs.add(dog);
    });
  }

  void updateDog(Dog updatedDog) {
    setState(() {
      final index = dogs.indexWhere((dog) => dog.id == updatedDog.id);
      if (index != -1) {
        dogs[index] = updatedDog;
      }
    });
  }

  void addWalkRecord(WalkRecord record) {
    setState(() {
      records.add(record);
    });
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
                backgroundImage: NetworkImage(dog.photoUrl),
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
  final photoController = TextEditingController(
    text:
    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800',
  );

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    targetController.dispose();
    photoController.dispose();
    super.dispose();
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
                controller: photoController,
                decoration: const InputDecoration(
                  labelText: 'Photo URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final dog = Dog(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      breed: breedController.text.trim(),
                      targetDistanceKm: double.parse(targetController.text.trim()),
                      photoUrl: photoController.text.trim().isEmpty
                          ? 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800'
                          : photoController.text.trim(),
                    );

                    appState.addDog(dog);
                    Navigator.pop(context);
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              dog.photoUrl,
              height: 220,
              fit: BoxFit.cover,
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
  int elapsedSeconds = 0;
  double distanceKm = 0.0;
  bool isPaused = false;
  late DateTime startTime;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        setState(() {
          elapsedSeconds++;
          distanceKm += 0.01;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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

    final calories = distanceKm * 50.0;
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: Colors.teal),
                    SizedBox(height: 8),
                    Text(
                      'Map will be added in the next version',
                      style: TextStyle(fontSize: 16),
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
                    onPressed: () {
                      timer?.cancel();

                      final endTime = DateTime.now();
                      final goalReached = distanceKm >= dog.targetDistanceKm;

                      appState.addWalkRecord(
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
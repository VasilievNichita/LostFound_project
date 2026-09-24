import 'package:flutter/material.dart';

void main() {
  runApp(const LostFoundApp());
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LostFound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const BoardScreen(),
    );
  }
}

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LostFound')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Объявления кампуса',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Потерянные и найденные вещи'),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              leading: Icon(Icons.key),
              title: Text('Ключи с синим брелоком'),
              subtitle: Text('Найдено • Библиотека\n25 сентября'),
              isThreeLine: true,
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.backpack_outlined),
              title: Text('Чёрный рюкзак'),
              subtitle: Text('Потеряно • Второй корпус\n24 сентября'),
              isThreeLine: true,
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.water_drop_outlined),
              title: Text('Бутылка для воды'),
              subtitle: Text('Найдено • Спортзал\n24 сентября'),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}

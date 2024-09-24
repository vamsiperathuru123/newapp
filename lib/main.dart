import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// Home Page with Toggle Menu
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List posts = [];
  List users = [];
  List filteredUsers = [];
  bool isSearching = false;

  // Fetch posts and users from JSONPlaceholder API
  Future<void> fetchData() async {
    final postsResponse = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    final usersResponse = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users'));

    if (postsResponse.statusCode == 200 && usersResponse.statusCode == 200) {
      setState(() {
        posts = json.decode(postsResponse.body);
        users = json.decode(usersResponse.body);
        filteredUsers = users;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Handle search query for users
  void updateSearch(String searchText) {
    setState(() {
      isSearching = searchText.isNotEmpty;
      filteredUsers = users
          .where((user) =>
      user['name'].toLowerCase().contains(searchText.toLowerCase()) ||
          user['email'].toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  // Navigation Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.lightBlue),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: updateSearch,
              decoration: const InputDecoration(
                labelText: 'Search for users by name or email',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                suffixIcon: Icon(Icons.search),
              ),
              style: const TextStyle(fontSize: 14), // Reduced font size of search bar
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 8.0), // Left alignment for "All Posts"
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All Posts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          isSearching
              ? Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  leading: UserAvatar(name: user['name']),
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userId: user['id']),
                      ),
                    );
                  },
                );
              },
            ),
          )
              : Expanded(
            child: posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final user = users.firstWhere((u) => u['id'] == post['userId'], orElse: () => null);

                return user != null
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display user avatar and name like in Instagram
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Navigate to profile page when avatar is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(userId: user['id']),
                                ),
                              );
                            },
                            child: UserAvatar(name: user['name'], radius: 25),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              // Navigate to profile page when username is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(userId: user['id']),
                                ),
                              );
                            },
                            child: Text(
                              user['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Display post title and body
                    ListTile(
                      title: Text(post['title']),
                      subtitle: Text(post['body']),
                      onTap: () {
                        final userId = post['userId'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(userId: userId),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                )
                    : Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Users Page
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List users = [];

  // Fetch users from JSONPlaceholder API
  Future<void> fetchUsers() async {
    final usersResponse = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users'));

    if (usersResponse.statusCode == 200) {
      setState(() {
        users = json.decode(usersResponse.body);
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: UserAvatar(name: user['name']),
            title: Text(user['name']),
            subtitle: Text(user['email']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(userId: user['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// User Profile Page
class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? user;
  List posts = [];

  // Fetch user details and posts by userId
  Future<void> fetchUserData() async {
    final userResponse =
    await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users/${widget.userId}'));
    final postsResponse =
    await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts?userId=${widget.userId}'));

    if (userResponse.statusCode == 200 && postsResponse.statusCode == 200) {
      setState(() {
        user = json.decode(userResponse.body);
        posts = json.decode(postsResponse.body);
      });
    } else {
      throw Exception('Failed to load user data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  UserAvatar(name: user!['name'], radius: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user!['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user!['email'],
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Posts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post['title']),
                  subtitle: Text(post['body']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// UserAvatar widget to display first letter of user name
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const UserAvatar({Key? key, required this.name, this.radius = 20}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.lightBlue,
      child: Text(
        name[0].toUpperCase(), // Display first letter of the user's name
        style: TextStyle(
          fontSize: radius, // Adjust font size according to the avatar size
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
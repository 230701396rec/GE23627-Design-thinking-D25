import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  List<String> categories = [];
  List<String> authors = [];
  String? selectedCategory;
  String? selectedAuthor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilters();
  }

  void _loadFilters() async {
    final categorySnapshot = await FirebaseFirestore.instance.collection('categories').get();
    final authorSnapshot = await FirebaseFirestore.instance.collection('authors').get();
    setState(() {
      categories = categorySnapshot.docs.map((doc) => doc['name'].toString()).toList();
      authors = authorSnapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addPhysicalBook() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty || _stockController.text.isEmpty || _priceController.text.isEmpty) {
      _showSnackbar("⚠ Please enter all book details");
      return;
    }

    int stock = int.tryParse(_stockController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 0.0;

    if (stock <= 0 || price <= 0) {
      _showSnackbar("⚠ Stock and Price must be greater than zero");
      return;
    }

    await FirebaseFirestore.instance.collection('physical_books').add({
      "title": _titleController.text,
      "author": _authorController.text,
      "category": selectedCategory ?? '',
      "stock": stock,
      "price": price,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _showSnackbar("✅ Physical Book Added!");
    _clearFields();
  }

  Future<void> _addEBook() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty || _urlController.text.isEmpty) {
      _showSnackbar("⚠ Please enter all book details");
      return;
    }

    await FirebaseFirestore.instance.collection('ebooks').add({
      "title": _titleController.text,
      "author": _authorController.text,
      "category": selectedCategory ?? '',
      "url": _urlController.text,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _showSnackbar("✅ E-Book Added!");
    _clearFields();
  }

  void _clearFields() {
    _titleController.clear();
    _authorController.clear();
    _stockController.clear();
    _priceController.clear();
    _urlController.clear();
    selectedCategory = null;
    selectedAuthor = null;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("📚 Admin Dashboard"),
          backgroundColor: const Color.fromARGB(255, 103, 58, 183),
          elevation: 5,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color.fromARGB(255, 103, 58,183),
            tabs: [
              Tab(icon: Icon(Icons.book, color: const Color.fromARGB(255, 14, 0, 0)), text: "Physical Books"),
              Tab(icon: Icon(Icons.cloud, color: const Color.fromARGB(255, 14, 0, 0)), text: "E-Books"),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade100, Colors.blue.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookForm(isPhysical: true),
              _buildBookForm(isPhysical: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookForm({required bool isPhysical}) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTextField(_titleController, "📖 Book Title"),
          _buildTextField(_authorController, "✍ Author"),
          if (isPhysical) _buildTextField(_stockController, "📦 Stock Quantity", isNumber: true),
          if (isPhysical) _buildTextField(_priceController, "💰 Price (₹)", isNumber: true),
          if (!isPhysical) _buildTextField(_urlController, "🔗 Book URL"),

          DropdownButtonFormField<String>(
            value: selectedCategory,
            hint: Text("Select Category"),
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),

          SizedBox(height: 10),

          SizedBox(height: 10),
          ElevatedButton(
            onPressed: isPhysical ? _addPhysicalBook : _addEBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isPhysical ? "➕ Add Physical Book" : "➕ Add E-Book"),
          ),
          Expanded(child: _buildBookList(isPhysical)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBookList(bool isPhysical) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(isPhysical ? 'physical_books' : 'ebooks').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text("🚫 No books available", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>?; 
            if (data == null) return SizedBox(); 

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              color: Colors.white,
              elevation: 5,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade300,
                  child: Icon(Icons.book, color: Colors.white),
                ),
                title: Text(data['title'] ?? 'Unknown Title', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Author: ${data['author'] ?? 'Unknown'}"),
                    if (data['category'] != null && data['category'] != '')
                      Text("Category: ${data['category']}", style: TextStyle(color: Colors.blue)),
                    if (isPhysical)
                      Text("Price: ₹${data.containsKey('price') ? data['price'] : 'Not Set'}",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: isPhysical
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.red),
                            onPressed: () {
                              if (data.containsKey('stock')) {
                                int currentStock = data['stock'] ?? 0;
                                if (currentStock > 0) {
                                  FirebaseFirestore.instance
                                      .collection('physical_books')
                                      .doc(doc.id)
                                      .update({'stock': currentStock - 1});
                                }
                              }
                            },
                          ),
                          Text(
                            data.containsKey('stock') ? "${data['stock']}" : "N/A",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () {
                              if (data.containsKey('stock')) {
                                int currentStock = data['stock'] ?? 0;
                                FirebaseFirestore.instance
                                    .collection('physical_books')
                                    .doc(doc.id)
                                    .update({'stock': currentStock + 1});
                              }
                            },
                          ),
                        ],
                      )
                    : Icon(Icons.open_in_new, color: Colors.blue),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class AdminFiltersPage extends StatefulWidget {
  @override
  _AdminFiltersPageState createState() => _AdminFiltersPageState();
}

class _AdminFiltersPageState extends State<AdminFiltersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  String selectedFilterType = 'categories';

  void _addFilter() async {
    if (_controller.text.isNotEmpty) {
      await _firestore.collection(selectedFilterType).add({'name': _controller.text});
      _controller.clear();
      setState(() {});
    }
  }

  void _deleteFilter(String id) async {
    await _firestore.collection(selectedFilterType).doc(id).delete();
    setState(() {});
  }

  @override
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Manage Filters"),
      backgroundColor: Colors.deepPurple,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Filter Type Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['categories', 'authors', 'editions'].map((type) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(type.toUpperCase()),
                    selected: selectedFilterType == type,
                    selectedColor: Colors.deepPurpleAccent,
                    onSelected: (selected) {
                      setState(() {
                        selectedFilterType = type;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // TextField to Add Filter
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: "Enter ${selectedFilterType.capitalize()} Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          // Add Button
          ElevatedButton.icon(
            onPressed: _addFilter,
            icon: Icon(Icons.add),
            label: Text("Add ${selectedFilterType.capitalize()}"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 20),

          // List of Filter Items
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection(selectedFilterType).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("❌ Error loading data"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "⚠ No ${selectedFilterType.capitalize()} found",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final items = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final data = items[index].data() as Map<String, dynamic>?;
                    if (data == null || !data.containsKey('name')) {
                      return SizedBox();
                    }

                    return Card(
                      child: ListTile(
                        title: Text(data['name']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFilter(items[index].id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

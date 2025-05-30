import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EbookListPage extends StatefulWidget {
  @override
  _EbookListPageState createState() => _EbookListPageState();
}

class _EbookListPageState extends State<EbookListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> ebooks = [];
  List<DocumentSnapshot> filteredEbooks = [];
  String selectedAuthor = 'All';
  String selectedCategory = 'All';
  List<String> authors = ['All'];
  List<String> categories = ['All'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEbooks);
  }

  void _filterEbooks() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredEbooks = ebooks.where((ebook) {
        final data = ebook.data() as Map<String, dynamic>;
        final title = data['title']?.toLowerCase() ?? '';
        final author = data['author'] ?? 'Unknown';
        final category = data['category'] ?? 'General';

        final matchesSearch = title.contains(query) || author.toLowerCase().contains(query);
        final matchesAuthor = selectedAuthor == 'All' || author == selectedAuthor;
        final matchesCategory = selectedCategory == 'All' || category == selectedCategory;

        return matchesSearch && matchesAuthor && matchesCategory;
      }).toList();
    });
  }

  void _openEbook(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("❌ Could not open URL: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📖 Available Ebooks", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '🔍 Search by title or author...',
                    prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Category",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: categories.map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                          _filterEbooks();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedAuthor,
                      decoration: InputDecoration(
                        labelText: "Author",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: authors.map((author) => DropdownMenuItem<String>(
                        value: author,
                        child: Text(author),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAuthor = value!;
                          _filterEbooks();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ebooks').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.purple));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No ebooks available.",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    );
                  }

                  if (ebooks.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        ebooks = snapshot.data!.docs;

                        Set<String> authorSet = {'All'};
                        Set<String> categorySet = {'All'};
                        for (var ebook in ebooks) {
                          final data = ebook.data() as Map<String, dynamic>;
                          authorSet.add(data['author'] ?? 'Unknown');
                          categorySet.add(data['category'] ?? 'General');
                        }

                        authors = authorSet.toList();
                        categories = categorySet.toList();

                        filteredEbooks = ebooks;
                        _filterEbooks();
                      });
                    });
                  }

                  return ListView.builder(
                    itemCount: filteredEbooks.length,
                    itemBuilder: (context, index) {
                      var ebook = filteredEbooks[index];
                      String title = ebook['title'] ?? 'Untitled';
                      String author = ebook['author'] ?? 'Unknown';
                      String url = ebook['url'] ?? '';

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        color: Colors.white,
                        elevation: 5,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.deepPurple,
                            ),
                          ),
                          subtitle: Text(
                            "Author: $author",
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _openEbook(url),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text("View", style: TextStyle(color: Colors.white)),
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
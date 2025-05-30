import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_page.dart';

class PhysicalBooksPage extends StatefulWidget {
  @override
  _PhysicalBooksPageState createState() => _PhysicalBooksPageState();
}

class _PhysicalBooksPageState extends State<PhysicalBooksPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> filteredBooks = [];
  Map<String, int> selectedQuantities = {};
  List<Map<String, dynamic>> cart = [];
  String selectedCategory = 'All';
  String selectedAuthor = 'All';
  List<String> categories = ['All'];
  List<String> authors = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _searchController.addListener(_filterBooks);
  }

  void _fetchBooks() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('physical_books').get();
      List<Map<String, dynamic>> bookList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'author': data['author'] ?? 'Unknown',
          'stock': data['stock'] ?? 0,
          'price': data['price'] ?? 0.0,
          'category': data['category'] ?? 'General',
        };
      }).toList();

      Set<String> categorySet = {'All'};
      Set<String> authorSet = {'All'};
      for (var book in bookList) {
        categorySet.add(book['category']);
        authorSet.add(book['author']);
      }

      setState(() {
        books = bookList;
        filteredBooks = books;
        categories = categorySet.toList();
        authors = authorSet.toList();
        for (var book in books) {
          selectedQuantities[book['id']] = 0;
        }
      });
    } catch (e) {
      print("Error fetching books: $e");
    }
  }

  void _filterBooks() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredBooks = books.where((book) {
        final matchesSearch = book['title'].toLowerCase().contains(query) ||
            book['author'].toLowerCase().contains(query);
        final matchesCategory = selectedCategory == 'All' || book['category'] == selectedCategory;
        final matchesAuthor = selectedAuthor == 'All' || book['author'] == selectedAuthor;
        return matchesSearch && matchesCategory && matchesAuthor;
      }).toList();
    });
  }

  void _updateSelectedQuantity(String bookId, int change, int maxStock) {
    setState(() {
      int newQuantity = (selectedQuantities[bookId] ?? 0) + change;
      if (newQuantity >= 0 && newQuantity <= maxStock) {
        selectedQuantities[bookId] = newQuantity;
      }
    });
  }

  void _confirmBorrow(String bookId, String title, String author, double price, int quantity, int currentStock) async {
    if (quantity > 0 && quantity <= currentStock) {
      try {
        await _firestore.collection('physical_books').doc(bookId).update({
          'stock': currentStock - quantity,
        });

        setState(() {
          cart.add({'id': bookId, 'title': title, 'author': author, 'price': price, 'quantity': quantity});
          selectedQuantities[bookId] = 0;
          _fetchBooks();
        });
      } catch (e) {
        print("Error updating stock: $e");
      }
    }
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(cartItems: List.from(cart)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Books", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: _goToCart,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.purple.shade400],
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
                          _filterBooks();
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
                          _filterBooks();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  String title = filteredBooks[index]['title'];
                  String author = filteredBooks[index]['author'];
                  int stock = filteredBooks[index]['stock'];
                  String bookId = filteredBooks[index]['id'];
                  double price = filteredBooks[index]['price'];
                  int selectedQuantity = selectedQuantities[bookId] ?? 0;

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.deepPurple.shade100),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.book, color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text("Author: $author", style: TextStyle(color: Colors.deepPurple)),
                          Text("Stock: $stock", style: TextStyle(color: Colors.blueGrey)),
                          Text("Price: Rs.$price", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: selectedQuantity > 0 ? () => _updateSelectedQuantity(bookId, -1, stock) : null,
                                  ),
                                  Text("$selectedQuantity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: selectedQuantity < stock ? () => _updateSelectedQuantity(bookId, 1, stock) : null,
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: selectedQuantity > 0 ? () => _confirmBorrow(bookId, title, author, price, selectedQuantity, stock) : null,
                                icon: Icon(Icons.add_shopping_cart),
                                label: Text("Add to Cart", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart_checkout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _goToCart,
                  label: Text("Proceed to Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CartPage({required this.cartItems});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.cartItems);
  }

  double getTotalPrice() {
    return _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  void _proceedToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          totalAmount: getTotalPrice(),
          cartItems: _cartItems, // Passing cart items to PaymentPage
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🛒 Your Cart", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _cartItems.isEmpty
            ? Center(child: Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.black)))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          color: Colors.deepPurple.shade200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 6,
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                      ),
                                      SizedBox(height: 5),
                                      Text("Quantity: ${item['quantity']}", style: TextStyle(color: Colors.white70)),
                                      Text(
                                        "Total: Rs.${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _cartItems.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _proceedToPayment,
                      child: Text("Proceed to Payment", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

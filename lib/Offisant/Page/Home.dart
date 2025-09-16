import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'dart:io';
import 'dart:async';
import '../../Admin/Page/Stollarni_joylashuv.dart';
import '../../Global/Api_global.dart';
import '../../Global/Klavish.dart';
import '../Controller/TokenCOntroller.dart';
import '../Controller/usersCOntroller.dart';
import '../Model/Ovqat_model.dart';
import 'Ranglar.dart';
import 'Yopilgan_zakaz_page.dart';

class Order {
  final String id;
  final String tableId;
  final String userId;
  final String firstName;
  final List<OrderItem> items;
  final num totalPrice;
  final String status;
  final String createdAt;
  bool isProcessing;
  final String formatted_order_number;

  Order({
    required this.id,
    required this.tableId,
    required this.userId,
    required this.firstName,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.formatted_order_number,
    this.isProcessing = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      tableId: json['table_id']?.toString() ?? '',
      formatted_order_number: json['formatted_order_number']?.toString() ?? '',
      userId: json['user_id'] ?? '',
      firstName: json['waiter_name'] ?? json['first_name'] ?? '',
      items:
      (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ??
          [],
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class OrderItem {
  final String foodId;
  final String? name;
  final num quantity;
  final num? price; // int emas, double bo‘ldi
  final String? categoryName;

  OrderItem({
    required this.foodId,
    required this.quantity,
    this.name,
    this.price,
    this.categoryName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['food_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      name: json['name'],
      price:
      json['price'] != null
          ? (json['price'] as num).toDouble()
          : null, // int/double ikkalasini qamrab oladi
      categoryName: json['category_name'],
    );
  }
}

class Category {
  final String id;
  final String title;
  final String printerId;
  final String printerName;
  final String printerIp;
  final List<String> subcategories;

  Category({
    required this.id,
    required this.title,
    required this.printerId,
    required this.printerName,
    required this.printerIp,
    required this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final printer = json['printer_id'];

    // Debug uchun
    print('Debug - Category: ${json['title']}, printer_id: $printer');

    String printerId = '';
    String printerName = '';
    String printerIp = '';

    if (printer != null && printer is Map<String, dynamic>) {
      printerId = printer['_id']?.toString() ?? '';
      printerName = printer['name']?.toString() ?? '';
      printerIp = printer['ip']?.toString() ?? '';

    }

    return Category(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      printerId: printerId,
      printerName: printerName,
      printerIp: printerIp,
      subcategories: (json['subcategories'] is List)
          ? (json['subcategories'] as List)
          .map((e) => e['title']?.toString() ?? '')
          .toList()
          : [],
    );
  }}

// ===== MODEL =====
class TableModel {
  final String id;
  final String name;
  final String status;
  final int guestCount;
  final int capacity;

  TableModel({
    required this.id,
    required this.name,
    required this.status,
    required this.guestCount,
    required this.capacity,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      guestCount: json['guest_count'] ?? 0,
      capacity: json['capacity'] ?? 0,
    );
  }
}

class HallModel {
  final String id;
  final String name;
  final List<TableModel> tables;

  HallModel({required this.id, required this.name, required this.tables});

  factory HallModel.fromJson(Map<String, dynamic> json) {
    return HallModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      tables:
      (json['tables'] as List<dynamic>? ?? [])
          .map((t) => TableModel.fromJson(t))
          .toList(),
    );
  }
}

// ===== CONTROLLER =====
class HallController {
  static const String baseUrl = "${ApiConfig.baseUrl}";

  // Hamma hallarni olish
  static Future<List<HallModel>> getHalls(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/halls/list"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => HallModel.fromJson(e)).toList();
    } else {
      throw Exception("Hallarni olishda xatolik: ${response.statusCode}");
    }
  }

  // Hall qo'shish
  static Future<void> createHall(String token, String name) async {
    final response = await http.post(
      Uri.parse("$baseUrl/halls/create"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({"name": name, "is_active": true}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Yangi hall qo'shildi");
    } else {
      throw Exception("Hall qo'shishda xatolik: ${response.body}");
    }
  }

  // Hallni yangilash
  static Future<void> updateHall(
      String token,
      String hallId,
      String newName,
      ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/halls/update/$hallId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({"name": newName}),
    );

    if (response.statusCode == 200) {
      print("✅ Hall yangilandi");
    } else {
      throw Exception("Hall yangilashda xatolik: ${response.body}");
    }
  }

  // Hallni o'chirish
  static Future<void> deleteHall(String token, String hallId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/halls/delete/$hallId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Hall o'chirildi");
    } else {
      throw Exception("Hall o'chirishda xatolik: ${response.body}");
    }
  }

  // Stol qo'shish
  static Future<void> addTableToHall(
      String token,
      String hallId,
      String name,
      int capacity,
      ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/tables/create"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        "hall": hallId,
        "name": name,
        "capacity": capacity,
        "is_active": true,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Stol qo'shildi");
    } else {
      throw Exception("Stol qo'shishda xatolik: ${response.body}");
    }
  }

  // Stol yangilash
  static Future<void> updateTable(
      String token,
      String tableId,
      String newName,
      int newCapacity,
      ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/tables/update/$tableId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({"name": newName, "capacity": newCapacity}),
    );

    if (response.statusCode == 200) {
      print("✅ Stol yangilandi");
    } else {
      throw Exception("Stol yangilashda xatolik: ${response.body}");
    }
  }

  // Stolni o'chirish
  static Future<void> deleteTable(String token, String tableId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/tables/delete/$tableId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Stol o'chirildi");
    } else {
      throw Exception("Stol o'chirishda xatolik: ${response.body}");
    }
  }
}

class PosScreen extends StatefulWidget {
  final User user;
  final token;
  const PosScreen({super.key, required this.user, required this.token});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String? _selectedTableName;
  String? _selectedTableId;
  List<Order> _selectedTableOrders = [];
  bool _isLoadingOrders = false;
  String? _token;

  Timer? _realTimeTimer;
  Map<String, bool> _tableOccupiedStatus = {};
  Map<String, String> _tableOwners = {};
  Map<String, List<Order>> _ordersCache = {}; // Zakazlar keshi
  bool _isLoadingTables = false;
  List<HallModel> _halls = [];
  String? _selectedHallId;

  // Yangi o'zgaruvchilar qo'shildi
  List<Ovqat> _allProducts = [];
  List<Category> _categories = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _initializeToken();
    _startRealTimeUpdates();
    _loadProductsAndCategories();
  }


  @override
  void dispose() {
    _realTimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialHalls() async {
    if (mounted) setState(() => _isLoadingTables = true);

    try {
      final halls = await fetchHalls();
      if (mounted) {
        setState(() {
          _halls = halls;
          _isLoadingTables = false;
        });
        _checkTableStatuses();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTables = false);
      print("Halls loading error: $e");
    }
  }

  Future<List<HallModel>> fetchHalls() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/halls/list");
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> hallsJson = json.decode(response.body);
      return hallsJson.map((json) => HallModel.fromJson(json)).toList();
    } else {
      throw Exception("Hallarni olishda xatolik: ${response.statusCode}");
    }
  }

  List<TableModel> _getSelectedHallTables() {
    if (_selectedHallId == null) return [];
    final selectedHall = _halls.firstWhere(
          (hall) => hall.id == _selectedHallId,
      orElse: () => HallModel(id: '', name: '', tables: []),
    );
    return selectedHall.tables;
  }

  Future<void> _fetchOrdersForTable(String tableId) async {
    if (_token == null) return;

    setState(() => _isLoadingOrders = true);

    try {
      print("🔄 Stolga zakazlarni olish: $tableId");

      final response = await http
          .get(
        Uri.parse("${ApiConfig.baseUrl}/orders/table/$tableId"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 10)); // Timeout oshirildi

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("📦 Olingan ma'lumotlar soni: ${data.length}");

        // Faqat pending holatidagi zakazlarni olish
        final orders =
        data
            .map((json) => Order.fromJson(json))
            .where((order) => order.status == 'pending')
            .toList();

        // Zakazlarni id bo'yicha sort qilish (tartibni mustahkamlash uchun)
        orders.sort((a, b) => a.id.compareTo(b.id));

        print("✅ Pending zakazlar soni: ${orders.length}");

        // Cache'ni yangilash
        _ordersCache[tableId] = orders;

        if (mounted && _selectedTableId == tableId) {
          setState(() {
            _selectedTableOrders = orders;
            _isLoadingOrders = false;
          });
          print("🎯 UI yangilandi: ${orders.length} zakaz ko'rsatilmoqda");
        }
      } else {
        print("❌ Server xatosi: ${response.statusCode}");
        _ordersCache[tableId] = [];
        if (mounted && _selectedTableId == tableId) {
          setState(() {
            _selectedTableOrders = [];
            _isLoadingOrders = false;
          });
        }
      }
    } catch (e) {
      print("💥 Zakazlarni olishda xatolik: $e");
      if (mounted && _selectedTableId == tableId) {
        setState(() {
          _selectedTableOrders = [];
          _isLoadingOrders = false;
        });
      }
    }
  }

  Future<void> _moveOrderToTable(String orderId, String newTableId) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/orders/move-table"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "orderId": orderId,
          "newTableId": newTableId,
          "force": false, // kerak bo‘lsa true qilib jo‘natasiz
        }),
      );

      if (response.statusCode == 200) {
        showCenterSnackBar(context, "Zakaz ko'chirildi", color: Colors.green);
        _clearCacheAndRefresh(); // yangilash
      } else {
        showCenterSnackBar(
          context,
          "Xatolik: ${response.statusCode}",
          color: Colors.red,
        );
      }
    } catch (e) {
      showCenterSnackBar(context, "Ko'chirishda xatolik: $e", color: Colors.red);
    }
  }


  void _handleTableTap(String tableName, String tableId) {
    print("🖱️ Stol tanlandi: $tableName (ID: $tableId)");

    setState(() {
      _selectedTableName = tableName;
      _selectedTableId = tableId;

      // 🚀 Avval cache’dan zakazlarni ko‘rsatamiz
      _selectedTableOrders = _ordersCache[tableId] ?? [];
    });

    // Keyin fon rejimida API’dan yangisini olib kelamiz
    _fetchOrdersForTableSilently(tableId);
  }

  void _startRealTimeUpdates() {
    _realTimeTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _checkTableStatusesRealTime();
      if (_selectedTableId != null) {
        _fetchOrdersForTableSilently(_selectedTableId!);
      }
    });
  }

  Future<void> _checkTableStatusesRealTime() async {
    try {
      Map<String, bool> newStatus = {};
      Map<String, String> newOwners = {};

      // Parallel requests bilan barcha stollarni tekshirish (tezroq)
      final futures = _getSelectedHallTables().map((table) async {
        try {
          final response = await http
              .get(
            Uri.parse('${ApiConfig.baseUrl}/orders/table/${table.id}'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'Content-Type': 'application/json',
            },
          )
              .timeout(const Duration(seconds: 2));

          if (response.statusCode == 200) {
            final List<dynamic> orders = jsonDecode(response.body);
            final pendingOrders =
            orders.where((o) => o['status'] == 'pending').toList();

            newStatus[table.id] = pendingOrders.isNotEmpty;
            if (pendingOrders.isNotEmpty) {
              newOwners[table.id] =
                  pendingOrders.first['user_id']?.toString() ?? '';
            } else {
              newOwners.remove(
                table.id,
              ); // Bo'sh stollar uchun owner ni olib tashlash
            }

            // Cache faqat tanlangan stol bo'lmasa yangilanadi
            if (_selectedTableId != table.id) {
              final orderObjects =
              orders
                  .map((json) => Order.fromJson(json))
                  .where((order) => order.status == 'pending')
                  .toList();

              // Zakazlarni sort qilish
              orderObjects.sort((a, b) => a.id.compareTo(b.id));

              if (orderObjects.isNotEmpty ||
                  _ordersCache.containsKey(table.id)) {
                _ordersCache[table.id] = orderObjects;
              }
            }
          } else {
            newStatus[table.id] = false;
            newOwners.remove(table.id);
          }
        } catch (e) {
          // Real-time da xatolikni ignore qilamiz, eski holatni saqlaymiz
          newStatus[table.id] = _tableOccupiedStatus[table.id] ?? false;
          if (_tableOwners.containsKey(table.id)) {
            newOwners[table.id] = _tableOwners[table.id]!;
          }
        }
      });

      await Future.wait(futures);

      if (mounted) {
        // Faqat haqiqatdan ham o'zgarish bo'lsa UI ni yangilash
        bool statusChanged = !_mapsEqual(newStatus, _tableOccupiedStatus);
        bool ownerChanged = !_mapsEqualString(newOwners, _tableOwners);

        if (statusChanged || ownerChanged) {
          setState(() {
            _tableOccupiedStatus = newStatus;
            _tableOwners = newOwners;

            // Agar tanlangan stol bo'sh bo'lib qolgan bo'lsa, zakazlar ro'yxatini tozalash
            if (_selectedTableId != null && !newStatus[_selectedTableId!]!) {
              _selectedTableOrders = [];
            }
          });
        }
      }
    } catch (e) {
      // Real-time da umumiy xatolikni ham ignore qilamiz
    }
  }

  Future<void> _fetchOrdersForTableSilently(String tableId) async {
    if (_token == null) return;

    try {
      final response = await http
          .get(
        Uri.parse("${ApiConfig.baseUrl}/orders/table/$tableId"),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final orders = data
            .map((json) => Order.fromJson(json))
            .where((order) => order.status == 'pending')
            .toList();

        orders.sort((a, b) => a.id.compareTo(b.id));

        _ordersCache[tableId] = orders;

        if (mounted && _selectedTableId == tableId) {
          setState(() {
            _selectedTableOrders = orders;
          });
        }
      }
    } catch (e) {
      print("❌ Silent fetch error: $e");
    }
  }


  void _clearCacheAndRefresh() {
    if (_selectedTableId != null) {
      _ordersCache.remove(_selectedTableId!);
    }

    // Darhol yangilash
    Future.microtask(() {
      if (_selectedTableId != null) {
        _fetchOrdersForTable(_selectedTableId!);
      }
      _checkTableStatusesRealTime();
    });
  }

  void _showOrderScreenDialog(String tableId) {
    bool isOccupied = _tableOccupiedStatus[tableId] ?? false;
    String? tableOwner = _tableOwners[tableId];

    if (isOccupied && tableOwner != null && tableOwner != widget.user.id) {
      showCenterSnackBar(
        context,
        'Bu stol boshqa ofitsiantga tegishli!',
        color: Colors.green,
      );
      return;
    }

    String? formattedOrderNumber =
    _selectedTableOrders.isNotEmpty
        ? _selectedTableOrders.first.formatted_order_number
        : '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: OrderScreenContent(
            formatted_order_number: formattedOrderNumber,
            tableId: tableId,
            tableName: _selectedTableName,
            user: widget.user,
            onOrderCreated: () async {
              _clearCacheAndRefresh();
            },
            token: widget.token,
          ),
        );
      },
    );
  }

  Future<void> _closeOrder(Order order) async {
    if (order.userId != widget.user.id) {
      showCenterSnackBar(
        context,
        'Faqat o\'zingiz yaratgan zakazni yopa olasiz!',
        color: Colors.green,
      );
      return;
    }

    try {
      setState(() => order.isProcessing = true);

      bool success = await closeOrder(order.id);

      if (success) {
        print("✅ Zakaz yopildi: ${order.id}");

        setState(() {
          _selectedTableOrders.removeWhere((o) => o.id == order.id);

          // Agar zakazlar qolmagan bo'lsa, stolni bo'sh qilib qo'yish
          if (_selectedTableOrders.isEmpty && _selectedTableId != null) {
            _tableOccupiedStatus[_selectedTableId!] = false;
            _tableOwners.remove(_selectedTableId!);
          }
        });

        // Cache ni tozalash
        if (_selectedTableId != null) {
          _ordersCache[_selectedTableId!] = _selectedTableOrders;
        }

        // Real-time statusni yangilash (background da)
        Future.microtask(() => _checkTableStatusesRealTime());

        showCenterSnackBar(context, 'Zakaz yopildi', color: Colors.green);
      } else {
        showCenterSnackBar(context, 'Xatolik yuz berdi');
      }
    } catch (e) {
      showCenterSnackBar(context, 'Xatolik: $e');
    } finally {
      if (mounted) setState(() => order.isProcessing = false);
    }
  }

  Future<void> _checkTableStatuses() async {
    try {
      Map<String, bool> newStatus = {};
      Map<String, String> newOwners = {};

      // Parallel requests bilan barcha stollarni tekshirish
      final futures = _getSelectedHallTables().map((table) async {
        try {
          final response = await http
              .get(
            Uri.parse('${ApiConfig.baseUrl}/orders/table/${table.id}'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'Content-Type': 'application/json',
            },
          )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final List<dynamic> orders = jsonDecode(response.body);
            final pendingOrders =
            orders.where((o) => o['status'] == 'pending').toList();

            newStatus[table.id] = pendingOrders.isNotEmpty;
            if (pendingOrders.isNotEmpty) {
              newOwners[table.id] = pendingOrders.first['user_id'] ?? '';
            }

            // Cache yangilanishi faqat tanlangan stol bo'lmasa
            if (_selectedTableId != table.id) {
              final orderObjects =
              orders
                  .map((json) => Order.fromJson(json))
                  .where((order) => order.status == 'pending')
                  .toList();

              // Sort qilish
              orderObjects.sort((a, b) => a.id.compareTo(b.id));

              _ordersCache[table.id] = orderObjects;
            }
          } else {
            newStatus[table.id] = false;
          }
        } catch (e) {
          print("Stol ${table.id} uchun xatolik: $e");
          newStatus[table.id] = _tableOccupiedStatus[table.id] ?? false;
        }
      });

      await Future.wait(futures);

      if (mounted) {
        bool statusChanged = !_mapsEqual(newStatus, _tableOccupiedStatus);
        bool ownerChanged = !_mapsEqualString(newOwners, _tableOwners);

        if (statusChanged || ownerChanged) {
          setState(() {
            _tableOccupiedStatus = newStatus;
            _tableOwners = newOwners;
          });
        }
      }
    } catch (e) {
      print("Status check error: $e");
    }
  }

  Future<void> _loadProductsAndCategories() async {
    setState(() => _isLoadingProducts = true);

    try {
      // ✅ Mahsulotlarni olish
      Future<List<Ovqat>> fetchProducts() async {
        final url = Uri.parse("${ApiConfig.baseUrl}/foods/list"); // <-- yo‘lni tekshiring

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          final data = decoded['foods'] ?? decoded['data'] ?? decoded;
          if (data is List) {
            return data.map((e) => Ovqat.fromJson(e)).toList();
          }
          throw Exception("API javobida mahsulotlar ro'yxati topilmadi");
        } else {
          throw Exception("Mahsulotlar olishda xatolik: ${response.statusCode}");
        }
      }

      Future<List<Category>> fetchCategories() async {
        final url = Uri.parse("${ApiConfig.baseUrl}/categories/list");

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          try {
            final decoded = json.decode(response.body);

            // API javobini to'g'ri parse qilish
            List<dynamic> categoriesList;
            if (decoded is List) {
              categoriesList = decoded;
            } else if (decoded is Map && decoded.containsKey('categories')) {
              categoriesList = decoded['categories'];
            } else {
              return [];
            }

            final categories = categoriesList.map((json) {
              return Category.fromJson(json);
            }).toList();

            return categories;
          } catch (e) {
            return [];
          }
        } else {
          return [];
        }
      }
      final results = await Future.wait([
        fetchCategories(),
        fetchProducts(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _allProducts = results[1] as List<Ovqat>;
          _isLoadingProducts = false;
        });
      }

      for (var c in _categories) {
      }

    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _printToSocket(String ip, List<int> data) async {
    try {
      final socket = await Socket.connect(
        ip,
        9100,
        timeout: const Duration(seconds: 2),
      );
      socket.add(data);
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 300));
      socket.destroy();
      debugPrint('$ip ga muvaffaqiyatli yuborildi');
    } catch (e) {
      debugPrint('$ip ga yuborishda xatolik: $e');
    }
  }

  List<int> _encodeText(String text) {
    return latin1.encode(text); // CP866 yoki UTF-8 kodlash
  }

  // Bekor qilingan mahsulotni printerga yuborish
  Future<void> _printCancelledItem(
      OrderItem item,
      int cancelQuantity,
      String reason,
      Order order,
      ) async {
    try {
      debugPrint('🖨️ Bekor qilingan mahsulot print qilinmoqda');
      debugPrint("🟢 Categories IDs: ${_categories.map((c) => c.id).toList()}");

      // Mahsulotning kategoriyasini topish
      final product = _allProducts.firstWhere(
            (p) => p.id == item.foodId,
        orElse: () => Ovqat(
          id: '',
          name: 'Noma\'lum',
          price: 0,
          categoryId: '',
          subcategory: null,
          categoryName: '',
          subcategories: [],
        ),
      );

      final category = _categories.firstWhere(
            (cat) => cat.id == product.categoryId,
        orElse: () => Category(
          id: '',
          title: '',
          printerId: '',
          printerName: '',
          printerIp: '',
          subcategories: [],
        ),
      );


      // Printer IP borligini tekshirish
      if (category.printerIp.isNotEmpty && category.printerIp != 'null') {
        final printData = {
          'orderNumber': order.formatted_order_number,
          'waiter_name': widget.user.firstName ?? 'Noma\'lum',
          'table_name': _selectedTableName ?? 'N/A',
          'item_name': item.name ?? 'Noma\'lum mahsulot',
          'cancel_quantity': cancelQuantity,
          'reason': reason,
          'time': DateTime.now().toString().substring(11, 16),
        };

        debugPrint("📡 ${category.title} => printerIp: ${category.printerIp}");

        final printBytes = _createCancelPrintData(printData);
        await _printToSocket(category.printerIp, printBytes);

        debugPrint('✅ Bekor qilingan mahsulot ${category.printerIp} ga yuborildi');
      } else {
        debugPrint("📡 ${category.title} => printerIp: ${category.printerIp}");
        debugPrint('⚠️ Kategoriya printeri topilmadi');
      }
    } catch (e) {
      debugPrint('❌ Cancel print error: $e');
    }
  }

  static const String baseUrl = "${ApiConfig.baseUrl}";

  bool _mapsEqual(Map<String, bool> map1, Map<String, bool> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  bool _mapsEqualString(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  Future<void> _initializeToken() async {
    try {
      _token = await AuthService.getToken();
      if (_token == null) {
        await AuthService.loginAndPrintToken();
        _token = await AuthService.getToken();
      }
      if (_token != null) {
        _loadInitialHalls();
      }
    } catch (e) {
      print("Token error: $e");
    }
  }

  bool _ordersAreEqual(List<Order> orders1, List<Order> orders2) {
    if (orders1.length != orders2.length) return false;
    for (int i = 0; i < orders1.length; i++) {
      if (orders1[i].id != orders2[i].id) return false;
    }
    return true;
  }

  Future<bool> closeOrder(String orderId) async {
    const String apiUrl = "${ApiConfig.baseUrl}/orders/close/";
    try {
      final response = await http.put(
        Uri.parse("$apiUrl$orderId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Close order failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Close order error: $e");
      return false;
    }
  }

  void showCenterSnackBar(
      BuildContext context,
      String message, {
        Color color = Colors.green,
      }) {
    showTopSnackBar(
      Overlay.of(context),
      Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              minWidth: 100,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      animationDuration: const Duration(milliseconds: 50),
      reverseAnimationDuration: const Duration(milliseconds: 50),
    );
  }

  // Sabablar ro'yxati
  final List<String> reasons = [
    "Mijoz bekor qildi",
    "Klient shikoyat qildi",
    "Noto‘g‘ri tayyorlangan",
    "Mahsulot tugagan",
    "Xizmat sifati past",
    "Boshqa",
  ];

  Future<void> showCancelDialog(
      String orderId,
      String foodId,
      int itemIndex,
      Order order,
      ) async {
    String reason = reasons[0]; // Default sabab
    String notes = "ixtiyor"; // API uchun izoh
    int cancelQuantity = 1; // Default miqdor
    final item = order.items[itemIndex];
    final TextEditingController quantityController = TextEditingController(
      text: "1",
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                "${item.name ?? 'Mahsulot'} ni bekor qilish",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Umumiy soni: ${item.quantity}"),
                  if (item.price != null)
                    Text(
                      "Narxi: ${NumberFormat('#,##0', 'uz').format(item.price! * item.quantity)} so'm",
                      style: TextStyle(color: Colors.green),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    "Bekor qilish sababi:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: reason,
                    items:
                    reasons.map((String r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          reason = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Bekor qilinadigan miqdor:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: "Miqdorni kiriting",
                    ),
                    onChanged: (value) {
                      setState(() {
                        cancelQuantity = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Bekor qilish",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (cancelQuantity <= 0 || cancelQuantity > item.quantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Noto'g'ri miqdor kiritildi!")),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _deleteItem(
                      orderId,
                      foodId,
                      itemIndex,
                      reason,
                      notes,
                      cancelQuantity,
                      order,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Tasdiqlash",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // _deleteItem funksiyasini yangilash
  Future<void> _deleteItem(
      String orderId,
      String foodId,
      int itemIndex,
      String reason,
      String notes,
      int cancelQuantity,
      Order order,
      ) async {
    setState(() => order.isProcessing = true);

    final result = await cancelOrderItemFast(
      orderId: orderId,
      foodId: foodId,
      cancelQuantity: cancelQuantity,
      reason: reason,
      notes: notes,
    );

    setState(() {
      order.isProcessing = false;
      if (result['success'] == true) {
        final item = order.items[itemIndex];
        final currentQuantity = item.quantity;
        final newQuantity = currentQuantity - cancelQuantity;

        if (newQuantity <= 0) {
          order.items.removeAt(itemIndex);
        } else {
          order.items[itemIndex] = OrderItem(
            foodId: item.foodId,
            name: item.name,
            quantity: newQuantity,
            price: item.price,
            categoryName: item.categoryName,
          );
        }

        if (order.items.isEmpty) {
          _selectedTableOrders.removeWhere((o) => o.id == orderId);
          _ordersCache[_selectedTableId!]!.removeWhere((o) => o.id == orderId);
          if (_selectedTableOrders.isEmpty) {
            _tableOccupiedStatus[_selectedTableId!] = false;
            _tableOwners.remove(_selectedTableId!);
          }
        }

        // YANGI: Bekor qilingan mahsulotni printerga yuborish
        _printCancelledItem(item, cancelQuantity, reason, order);

        showCenterSnackBar(
          context,
          "✅ Mahsulot bekor qilindi!",
          color: Colors.green,
        );
        _fetchOrdersForTable(_selectedTableId!);
        _checkTableStatuses();
      } else {
        showCenterSnackBar(
          context,
          result['message']?.toString() ?? 'Mahsulotni bekor qilishda xatolik!',
          color: AppColors.error,
        );
      }
    });
  }

  // YANGI: Bekor qilingan mahsulot uchun print ma'lumotini yaratish
  List<int> _createCancelPrintData(Map<String, dynamic> data) {
    final bytes = <int>[];
    const printerWidth = 32;

    bytes.addAll([0x1B, 0x40]); // Reset
    bytes.addAll([0x1B, 0x74, 17]); // CP866

    // Markazlash
    bytes.addAll([0x1B, 0x61, 1]); // Center alignment

    // Sarlavha
    bytes.addAll(_encodeText('MAHSULOT BEKOR QILINDI\r\n'));
    bytes.addAll(_encodeText('=' * printerWidth + '\r\n'));

    // Asosiy ma'lumotlar
    bytes.addAll(_encodeText('Zakaz: ${data['orderNumber']}\r\n'));
    bytes.addAll(_encodeText('Ofitsiant: ${data['waiter_name']}\r\n'));
    bytes.addAll(_encodeText('Stol: ${data['table_name']}\r\n'));
    bytes.addAll(_encodeText('Vaqt: ${data['time']}\r\n'));
    bytes.addAll(_encodeText('-' * printerWidth + '\r\n'));

    // Bekor qilingan mahsulot ma'lumotlari
    bytes.addAll(_encodeText('MAHSULOT:\r\n'));
    bytes.addAll(_encodeText('${data['item_name']}\r\n'));
    bytes.addAll(_encodeText('MIQDOR: ${data['cancel_quantity']}\r\n'));
    bytes.addAll(_encodeText('-' * printerWidth + '\r\n'));

    // Sabab
    bytes.addAll(_encodeText('SABAB:\r\n'));
    bytes.addAll(_encodeText('${data['reason']}\r\n'));
    bytes.addAll(_encodeText('=' * printerWidth + '\r\n'));

    // Bo'sh joy qoldirish va kesish
    bytes.addAll(_encodeText('\r\n\r\n\r\n\r\n\r\n'));
    bytes.addAll([0x1D, 0x56, 0]); // Cut

    return bytes;
  }

  // API orqali taomni bekor qilish
  Future<Map<String, dynamic>> cancelOrderItemFast({
    required String orderId,
    required String foodId,
    required int cancelQuantity,
    required String reason,
    required String notes,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/orders/$orderId/cancel-item'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'food_id': foodId,
          'cancel_quantity': cancelQuantity,
          'reason': reason,
          'notes': notes,
        }),
      )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _ordersCache.clear(); // Keshni tozalash
        return {
          'success': true,
          'message': data['message']?.toString() ?? 'Mahsulot bekor qilindi',
        };
      }

      return {
        'success': false,
        'message':
        data['message']?.toString() ?? 'Mahsulotni bekor qilishda xatolik',
      };
    } catch (e) {
      debugPrint('Mahsulotni bekor qilishda xatolik: $e');
      return {'success': false, 'message': 'Xatolik: $e'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth >= 600 && screenWidth <= 1200;

    return Scaffold(
      backgroundColor: Color(0xFFDFF3E3),
      appBar: _buildAppBar(),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: _buildTablesGrid(isDesktop, isTablet),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: _buildOrderDetails(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFDFF3E3),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.user.firstName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildHeaderButton(
                onPressed: () {
                  if (_selectedTableId != null) {
                    _showOrderScreenDialog(_selectedTableId!);
                  } else {
                    showCenterSnackBar(
                      context,
                      'Stolni tanlang!',
                      color: Colors.green,
                    );
                  }
                },
                icon: Icons.add_circle_outline,
                label:
                _selectedTableName != null
                    ? "Yangi hisob: $_selectedTableName"
                    : "Yangi hisob",
                isPrimary: true,
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OrderTablePage(
                        waiterName: widget.user.firstName,
                        token: widget.token,
                      ),
                    ),
                  );
                },
                icon: Icons.check_circle_outline,
                label: "Yopilgan hisoblar",
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTablesGrid(bool isDesktop, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔼 Tepada header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.table_restaurant, color: AppColors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Zallar va Stollar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Hall tanlash uchun tugmalar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: _halls.map((hall) {
                  final isSelected = _selectedHallId == hall.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedHallId = hall.id;
                          _selectedTableId = null;
                          _selectedTableName = null;
                          _selectedTableOrders = [];
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isSelected ? AppColors.primary : AppColors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(hall.name),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 🔽 Pastda tanlangan zalning stollari chiqadi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoadingTables
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              )
                  : _halls.isEmpty
                  ? const Center(child: Text("Zallar topilmadi", style: TextStyle(color: AppColors.grey)))
                  : _selectedHallId == null
                  ? const Center(child: Text("Iltimos, zalni tanlang", style: TextStyle(color: AppColors.grey)))
                  : _getSelectedHallTables().isEmpty
                  ? const Center(child: Text("Bu zalda stollar yo'q", style: TextStyle(color: AppColors.grey)))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _getSelectedHallTables().length,
                itemBuilder: (_, index) {
                  final table = _getSelectedHallTables()[index];
                  final isSelected = _selectedTableId == table.id;
                  final isOccupied = _tableOccupiedStatus[table.id] ?? false;
                  final isOwnTable = _tableOwners[table.id] == widget.user.id;

                  return GestureDetector(
                    onTap: () {
                      if (_selectedTableId == table.id &&
                          (!isOccupied || isOwnTable)) {
                        _showOrderScreenDialog(table.id);
                      } else {
                        _handleTableTap(table.name, table.id);
                      }
                    },
                    child: _buildTableCard(
                      table,       // ✅ TableModel sifatida uzatiladi
                      isSelected,
                      isOccupied,
                      isOwnTable,
                    ),
                  );
                },
              ),
            ),
          )

        ],
      ),
    );
  }

  Widget _buildTableCard(
      TableModel table,
      bool isSelected,
      bool isOccupied,
      bool isOwnTable,
      ) {
    Color cardColor;
    Color textColor;
    String statusText;
    Color borderColor;

    if (isOccupied && !isOwnTable) {
      cardColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      statusText = "Boshqa ofitsiant";
      borderColor = AppColors.error;
    } else if (isOccupied && isOwnTable) {
      cardColor = AppColors.accent.withOpacity(0.1);
      textColor = AppColors.accent;
      statusText = "Mening stolim";
      borderColor = AppColors.accent;
    } else if (isSelected) {
      cardColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      statusText = "Tanlangan";
      borderColor = Colors.green;
    } else {
      cardColor = Colors.green.withOpacity(0.05);
      textColor = Colors.green;
      statusText = "Bo'sh";
      borderColor = Colors.green;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.table_bar,
                size: 28,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              table.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: textColor, width: 1),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildOrderDetails() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔼 Tepada "Zakazlar" header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  "Zakazlar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),

          // 🔽 Kontent qismi
          Expanded(
            child: _selectedTableId == null
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale, size: 64, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Stolni tanlang",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.grey),
                  ),
                ],
              ),
            )
                : _selectedTableOrders.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 48, color: AppColors.grey),
                  SizedBox(height: 12),
                  Text(
                    "Zakazlar yo'q",
                    style: TextStyle(
                        fontSize: 16, color: AppColors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _selectedTableOrders.length,
              itemBuilder: (context, index) {
                final order = _selectedTableOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildOrderCard(order, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    final isOwnOrder = order.userId == widget.user.id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${order.formatted_order_number}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Kutilmoqda',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (isOwnOrder) ...[
              const SizedBox(height: 8),
              Text(
                "Ofitsiant: ${order.firstName}",
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              Text(
                "Vaqt: ${_formatDateTime(order.createdAt)}",
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                "Mahsulotlar:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                    (item) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${item.name ?? 'Mahsulot'} x${item.quantity}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (item.price != null)
                        Text(
                          "${NumberFormat('#,##0', 'uz').format(item.price! * item.quantity)} so'm",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      const SizedBox(width: 8),
                      // IconButton(
                      //   icon: const Icon(
                      //     Icons.delete,
                      //     color: AppColors.error,
                      //     size: 20,
                      //   ),
                      //   onPressed:
                      //   isOwnOrder
                      //       ? () => showCancelDialog(
                      //     order.id,
                      //     item.foodId,
                      //     order.items.indexOf(item),
                      //     order,
                      //   )
                      //       : null,
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments, color: AppColors.accent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Jami:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${NumberFormat('#,##0', 'uz').format(order.totalPrice)} so'm",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // YANGI: Mahsulot qo'shish va Zakazni yopish tugmalari
              Row(
                children: [
                  // Mahsulot qo'shish tugmasi
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child:
                      order.isProcessing
                          ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                          : ElevatedButton.icon(
                        onPressed: () => _showAddItemsDialog(order),
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          size: 18,
                        ),
                        label: const Text(
                          "Qo'shish",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Zakazni yopish tugmasi
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child:
                      order.isProcessing
                          ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                          : ElevatedButton.icon(
                        onPressed: () => _closeOrder(order),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text(
                          "Yopish",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 🆕 Ko‘chirish tugmasi
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMoveTableDialog(order),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text("Ko'chirish"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Bu zakaz boshqa ofitsiantga tegishli",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveTableDialog(Order order) async {
    // Faqat tanlangan zalning stollari ichidan bo'shlarini olish
    final emptyTables = _getSelectedHallTables()
        .where((t) => !(_tableOccupiedStatus[t.id] ?? false))
        .toList();

    if (emptyTables.isEmpty) {
      showCenterSnackBar(context, "Bo'sh stollar yo'q", color: Colors.red);
      return;
    }

    String? selectedTableId;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Zakazni boshqa stolga ko'chirish"),
          content: DropdownButtonFormField<String>(
            value: selectedTableId,
            items: emptyTables.map((table) {
              return DropdownMenuItem(
                value: table.id,
                child: Text("Stol ${table.name}"), // 🔹 TableModel.name ishlatildi
              );
            }).toList(),
            onChanged: (value) {
              selectedTableId = value;
            },
            decoration: const InputDecoration(
              labelText: "Stol tanlang",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Bekor qilish"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Ko'chirish"),
              onPressed: () async {
                if (selectedTableId != null) {
                  Navigator.pop(context);
                  await _moveOrderToTable(order.id, selectedTableId!);
                }
              },
            ),
          ],
        );
      },
    );
  }


  // Mahsulot qo'shish dialogini ko'rsatish metodi
  void _showAddItemsDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: OrderScreenContent(
            formatted_order_number:
            order.formatted_order_number, // YANGI qo'shildi
            tableId: order.tableId,
            tableName: _selectedTableName,
            user: widget.user,
            token: widget.token,
            isAddingToExistingOrder: true, // YANGI parametr
            existingOrderId: order.id, // YANGI parametr
            onOrderCreated: () async {
              _fetchOrdersForTable(_selectedTableId!);
              _checkTableStatuses();
            },
          ),
        );
      },
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }
}


class OrderScreenContent extends StatefulWidget {
  final User user;
  final String? tableId;
  final VoidCallback? onOrderCreated;
  final String? tableName;
  final token;
  final bool isAddingToExistingOrder;
  final String? existingOrderId;
  final String formatted_order_number;

  const OrderScreenContent({
    super.key,
    this.tableId,
    required this.user,
    this.onOrderCreated,
    this.tableName,
    required this.token,
    this.isAddingToExistingOrder = false,
    this.existingOrderId,
    required this.formatted_order_number,
  });

  @override
  State<OrderScreenContent> createState() => _OrderScreenContentState();
}

class _OrderScreenContentState extends State<OrderScreenContent> {
  String? _selectedCategoryId;
  String _selectedCategoryName = '';
  String? _selectedSubcategory;
  List<Category> _categories = [];
  List<Ovqat> _allProducts = [];
  List<Ovqat> _filteredProducts = [];
  bool _isLoading = true;
  bool _categoriesLoaded = false; // Kategoriyalar alohida loading
  String? _token;
  bool _isSubmitting = false;
  String _searchQuery = '';

  final Map<String, Map<String, dynamic>> _cart = {};
  final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'uz_UZ');

  // Yangi cache tizimi
  static Map<String, dynamic>? _memoryCache;
  static DateTime? _lastCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _initializeAppFast();
  }

  void _updateCart(String productId, int change, {double? kg}) {
    setState(() {
      final product = _findProductById(productId);
      if (product == null) {
        debugPrint('Xatolik: Mahsulot topilmadi, ID: $productId');
        return;
      }

      final currentEntry = _cart[productId] ?? {'quantity': 0.0, 'kg': 1.0};

      if (product.unit == 'kg') {
        final newKg = kg ?? currentEntry['kg'];
        if (change > 0 && newKg > 0) {
          _cart[productId] = {'quantity': newKg, 'kg': newKg};
          debugPrint('Kg mahsulot qo‘shildi: ${product.name}, kg: $newKg');
        } else {
          _cart.remove(productId);
          debugPrint('Mahsulot o‘chirildi: ${product.name}');
        }
      } else {
        // Oddiy mahsulotlar uchun
        final newQty = currentEntry['quantity'] + change;
        if (newQty <= 0) {
          _cart.remove(productId);
          debugPrint('Mahsulot o‘chirildi: ${product.name}');
        } else {
          _cart[productId] = {
            'quantity': newQty,
            'kg': currentEntry['kg'],
            'note': currentEntry['note'] ?? '', // ✏️ izohni saqlash
          };
          debugPrint(
            'Oddiy mahsulot qo‘shildi: ${product.name}, soni: $newQty',
          );
        }
      }
    });
  }

  Future<void> _initializeAppFast() async {
    // Token va kategoriyalarni parallel yuklash
    await Future.wait([_initializeToken(), _loadCategoriesFast()]);

    // Mahsulotlarni background da yuklash
    _loadProductsInBackground();
  }

  Future<void> _initializeToken() async {
    try {
      _token = widget.token ?? await AuthService.getToken();
      if (_token == null) {
        await AuthService.loginAndPrintToken();
        _token = await AuthService.getToken();
      }
    } catch (e) {
      debugPrint("Token error: $e");
    }
  }

  bool _isCacheValid() {
    return _memoryCache != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheExpiry;
  }

  // Kategoriyalarni tezkor yuklash
  Future<void> _loadCategoriesFast() async {
    try {
      // Cache dan kategoriyalarni olish
      if (_isCacheValid() && _memoryCache!['categories'] != null) {
        _categories = List<Category>.from(_memoryCache!['categories']);
        setState(() {
          _categoriesLoaded = true;
        });
        return;
      }

      // API dan kategoriyalarni olish
      final url = Uri.parse("${ApiConfig.baseUrl}/categories/list");

      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_token ?? widget.token}',
        },
      )
          .timeout(Duration(seconds: 2)); // Qisqa timeout
      print(response.body);
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        List<Category> categories = [];
        if (decoded is Map<String, dynamic>) {
          final data = decoded['categories'] ?? decoded['data'] ?? decoded;
          if (data is List) {
            categories = data.map((e) => Category.fromJson(e)).toList();
          }
        } else if (decoded is List) {
          categories = decoded.map((e) => Category.fromJson(e)).toList();
        }

        // Cache ga saqlash
        _memoryCache ??= {};
        _memoryCache!['categories'] = categories;
        _lastCacheTime = DateTime.now();

        if (mounted) {
          setState(() {
            _categories = categories;
            _categoriesLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Kategoriyalar yuklashda xatolik: $e");
      if (mounted) {
        setState(() => _categoriesLoaded = true);
      }
    }
  }

  // Mahsulotlarni background da yuklash
  void _loadProductsInBackground() async {
    try {
      // Cache dan mahsulotlarni olish
      if (_isCacheValid() && _memoryCache!['products'] != null) {
        _allProducts = List<Ovqat>.from(_memoryCache!['products']);
        setState(() {
          _isLoading = false;
        });
        _filterProductsByCategory();
        return;
      }

      // API dan mahsulotlarni olish
      final url = Uri.parse("${ApiConfig.baseUrl}/foods/list");

      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_token ?? widget.token}',
        },
      )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        List<Ovqat> products = [];
        if (decoded is Map<String, dynamic>) {
          final data =
              decoded['foods'] ??
                  decoded['data'] ??
                  decoded['products'] ??
                  decoded;
          if (data is List) {
            products = data.map((e) => Ovqat.fromJson(e)).toList();
          }
        } else if (decoded is List) {
          products = decoded.map((e) => Ovqat.fromJson(e)).toList();
        }

        // Cache ga saqlash
        _memoryCache ??= {};
        _memoryCache!['products'] = products;
        _lastCacheTime = DateTime.now();

        if (mounted) {
          setState(() {
            _allProducts = products;
            _isLoading = false;
          });
          _filterProductsByCategory();
        }
      }
    } catch (e) {
      debugPrint("Mahsulotlar yuklashda xatolik: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProductsByCategory() {
    List<Ovqat> filtered = _allProducts;

    // Global qidiruv - qidiruv so'rovi bo'lsa
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();

      // Mahsulot nomi bo'yicha global qidiruv
      filtered =
          _allProducts.where((product) {
            final productName = product.name.toLowerCase();
            final productSub = product.subcategory?.toLowerCase() ?? '';

            // Mahsulot nomi yoki subkategoriya nomi bilan mos kelishi
            return productName.contains(query) || productSub.contains(query);
          }).toList();

      if (filtered.isNotEmpty && _selectedCategoryId == null) {
        final firstProduct = filtered.first;
        final matchedCategory = _categories.firstWhere(
              (cat) => cat.id == firstProduct.categoryId,
          orElse:
              () => Category(
            id: '',
            title: '',
            subcategories: [],
            printerName: '',
            printerIp: '',
            printerId: '',
          ),
        );

        if (matchedCategory.id.isNotEmpty) {
          _selectedCategoryId = matchedCategory.id;
          _selectedCategoryName = matchedCategory.title;

          // Agar mahsulotda subkategoriya bo'lsa, uni ham tanlash
          if (firstProduct.subcategory != null &&
              firstProduct.subcategory!.isNotEmpty) {
            _selectedSubcategory = firstProduct.subcategory;
          }
        }
      }
    }
    // Qidiruv bo'sh bo'lsa, kategoriya tanlangan bo'lsa
    else if (_selectedCategoryId != null) {
      // Faqat kategoriya tanlangan - kategoriya bo'yicha filterlash
      filtered =
          _allProducts.where((product) {
            if (product.categoryId != _selectedCategoryId) return false;

            // Agar subkategoriya tanlangan bo'lsa
            if (_selectedSubcategory != null &&
                _selectedSubcategory!.isNotEmpty) {
              return product.subcategory?.toLowerCase() ==
                  _selectedSubcategory!.toLowerCase();
            }

            return true;
          }).toList();
    }
    // Hech narsa tanlangmagan va qidiruv bo'sh - barcha mahsulotlar
    else {
      filtered = _allProducts;
    }

    // Natijani yangilash
    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _selectCategory(
      String categoryId,
      String categoryTitle, {
        String? subcategory,
      }) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryTitle;
      _selectedSubcategory = subcategory;
    });
    _filterProductsByCategory();
  }

  double _calculateTotal() {
    if (_cart.isEmpty) {
      return 0.0;
    }
    if (_allProducts.isEmpty) {
      return 0.0;
    }

    double total = 0;
    for (final entry in _cart.entries) {
      final product = _findProductById(entry.key);
      if (product != null) {
        if (product.unit == 'kg') {
          final itemPrice = product.price * entry.value['quantity'];
          total += itemPrice;
        } else {
          final itemPrice = product.price * entry.value['quantity'];
          total += itemPrice;
        }
      } else {
        debugPrint('Xatolik: Mahsulot topilmadi, food_id: ${entry.key}');
      }
    }
    return total;
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ichimliklar':
        return Icons.local_bar;
      case 'shirinliklar':
        return Icons.bakery_dining;
      case 'taomlar':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  Future<void> _createOrderUltraFast() async {
    if (_isSubmitting || _cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _sendOrderInBackground();

      if (result['success'] == true) {
        if (mounted) {
          _showSuccess(result['message'] ?? 'Zakaz muvaffaqiyatli yuborildi!');
          widget.onOrderCreated?.call();
          Navigator.of(context).pop(); // ✅ darhol yopiladi
        }
      } else {
        if (mounted) {
          _showError(result['message'] ?? 'Zakaz yuborishda xatolik');
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 🔹 Zakazni serverga yuborish
  Future<Map<String, dynamic>> _sendOrderInBackground() async {
    try {
      if (_cart.isEmpty) {
        return {'success': false, 'message': 'Savat bo‘sh'};
      }
      if (_token == null) {
        return {'success': false, 'message': 'Token topilmadi'};
      }

      final orderItems = _cart.entries.map((e) {
        final product = _findProductById(e.key);
        if (product == null) return null;

        final quantity = product.unit == 'kg'
            ? e.value['quantity']
            : (e.value['quantity'] as num).toInt();

        if (quantity <= 0) return null;
        return {'food_id': e.key, 'quantity': quantity};
      }).where((item) => item != null).toList();

      final orderData = {
        'table_id': widget.tableId,
        'user_id': widget.user.id,
        'first_name': widget.user.firstName ?? 'Noma\'lum',
        'items': orderItems,
        'total_price': _calculateTotal(),
        'kassir_workflow': true,
        'table_number': widget.tableName ?? 'N/A',
      };

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/orders/create"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(orderData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Printerni backgroundda yuboramiz
        Future.microtask(() => _printOrderAsync(data));
        return {'success': true, 'message': 'Zakaz muvaffaqiyatli yuborildi!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Server xatosi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Xatolik: $e'};
    }
  }

  void showCenterSnackBar(
      BuildContext context,
      String message, {
        Color color = Colors.green,
      }) {
    showTopSnackBar(
      Overlay.of(context),
      Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              minWidth: 100,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      animationDuration: const Duration(milliseconds: 50),
      reverseAnimationDuration: const Duration(milliseconds: 50),
    );
  }

  Future<Map<String, dynamic>> _sendAddItemsInBackground() async {
    try {
      final orderItems = _cart.entries.map((e) {
        final product = _findProductById(e.key);
        if (product == null) return null;

        final quantity = product.unit == 'kg'
            ? e.value['quantity']
            : (e.value['quantity'] as num).toInt();

        if (quantity <= 0) return null;
        return {'food_id': e.key, 'quantity': quantity};
      }).where((item) => item != null).toList();

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/orders/${widget.existingOrderId}/add-items"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'items': orderItems}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Future.microtask(() => _printAddedItemsOptimized(data));
        return {'success': true, 'message': 'Mahsulotlar qo‘shildi!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Server xatosi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Xatolik: $e'};
    }
  }

  Future<void> _printOrderAsync(Map<String, dynamic> responseData) async {
    try {
      final Map<String, List<Map<String, dynamic>>> printerGroups = {};
      for (final entry in _cart.entries) {
        final product = _findProductById(entry.key);
        if (product != null) {
          final category = _categories.firstWhere(
                (cat) => cat.id == product.categoryId,
            orElse: () => Category(id: '', title: '', subcategories: [], printerName: '', printerIp: '', printerId: ''),
          );
          if (category.printerIp.isNotEmpty && category.printerIp != 'null') {
            printerGroups.putIfAbsent(category.printerIp, () => []);
            printerGroups[category.printerIp]!.add({
              'name': product.name,
              'qty': entry.value['quantity'],
              'kg': product.unit == 'kg' ? entry.value['kg'] : null,
            });
          }
        }
      }

      // Fire-and-forget → kutilmaydi
      printerGroups.forEach((ip, items) {
        final printData = {
          'orderNumber': responseData['order']?['orderNumber']?.toString() ?? '',
          'waiter_name': widget.user.firstName ?? 'Noma\'lum',
          'table_name': widget.tableName ?? 'N/A',
          'items': items,
        };
        final bytes = _createPrintData(printData);
        _printToSocket(ip, bytes).catchError((e) {
          debugPrint("⚠️ Printer $ip ga yuborishda xato: $e");
        });
      });
    } catch (e) {
      debugPrint("❌ Print error: $e");
    }
  }

  Future<void> _printAddedItemsOptimized(Map<String, dynamic> responseData) async {
    try {
      final Map<String, List<Map<String, dynamic>>> printerGroups = {};
      for (final entry in _cart.entries) {
        final product = _findProductById(entry.key);
        if (product != null) {
          final category = _categories.firstWhere(
                (cat) => cat.id == product.categoryId,
            orElse: () => Category(id: '', title: '', subcategories: [], printerName: '', printerIp: '', printerId: ''),
          );
          if (category.printerIp.isNotEmpty && category.printerIp != 'null') {
            printerGroups.putIfAbsent(category.printerIp, () => []);
            printerGroups[category.printerIp]!.add({
              'name': product.name,
              'qty': entry.value['quantity'],
              'kg': product.unit == 'kg' ? entry.value['kg'] : null,
            });
          }
        }
      }

      printerGroups.forEach((ip, items) {
        final printData = {
          'orderNumber': widget.existingOrderId?.substring(0, 8) ?? '',
          'waiter_name': widget.user.firstName ?? 'Noma\'lum',
          'table_name': widget.tableName ?? 'N/A',
          'items': items,
          'isAddition': true,
        };
        final bytes = _createPrintDataForAddition(printData);
        _printToSocket(ip, bytes).catchError((e) {
          debugPrint("⚠️ Qo‘shimcha $ip ga yuborishda xato: $e");
        });
      });
    } catch (e) {
      debugPrint("❌ Print error: $e");
    }
  }
  // Muvaffaqiyat xabarini ko‘rsatish uchun yangi metod
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Ovqat? _findProductById(String id) {
    for (final product in _allProducts) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> _printToSocket(String ip, List<int> data) async {
    try {
      print('Printerga ulanmoqda: $ip:9100');

      final socket = await Socket.connect(ip, 9100, timeout: Duration(milliseconds: 500));
      socket.add(data);
      await socket.flush();

      socket.destroy();

      print('$ip ga muvaffaqiyatli yuborildi');
    } catch (e) {
      print('$ip ga yuborishda xatolik: $e');
    }
  }

  List<int> _createPrintData(Map<String, dynamic> data) {
    final bytes = <int>[];

    bytes.addAll([0x1B, 0x40]); // Reset
    bytes.addAll([0x1B, 0x74, 17]); // CP866 kodirovka

    bytes.addAll([0x1B, 0x61, 1]); // Markaz
    final waiter = data['waiter_name'];
    final table = data['table_name'];

    bytes.addAll(_encodeText('ZAKAZ : ${widget.formatted_order_number}\r\n'));
    bytes.addAll(_encodeText('Ofitsiant: $waiter\r\n'));
    bytes.addAll(_encodeText('Stol: $table\r\n'));
    bytes.addAll(_encodeText(
        '${DateTime.now().toString().substring(11, 16)}\r\n'));
    bytes.addAll(_encodeText('=' * 32 + '\r\n'));

    final header = 'Nomi'.padRight(20) + 'Soni';
    bytes.addAll([0x1B, 0x61, 1]); // Markaz
    bytes.addAll(_encodeText(header + '\r\n'));
    bytes.addAll(_encodeText('-' * 32 + '\r\n'));

    for (final item in data['items']) {
      final name = item['name'].toString();
      final qty = item['qty'].toString();
      final line = name.padRight(20) + qty;

      bytes.addAll([0x1B, 0x61, 0]); // Chapga
      bytes.addAll(_encodeText(line + '\r\n'));

      // ✏️ Agar izoh mavjud bo‘lsa, uni chiqaramiz
      final note = _cart[item['id']]?['note'] ?? '';
      if (note.isNotEmpty) {
        bytes.addAll([0x1B, 0x61, 0]); // Chapga
        bytes.addAll(_encodeText('  -> $note\r\n'));
      }
    }

    bytes.addAll(_encodeText('=' * 32 + '\r\n\r\n\r\n\r\n\r\n'));
    bytes.addAll([0x1D, 0x56, 0]); // Kesish

    return bytes;
  }

  List<int> _encodeText(String text) {
    return latin1.encode(text);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth >= 600 && screenWidth <= 1200;

    final selectedCategory =
        _categories.cast<Category?>().firstWhere(
              (cat) => cat?.id == _selectedCategoryId,
          orElse: () => null,
        ) ??
            Category(
              id: '',
              title: 'Kategoriyani tanlang',
              subcategories: [],
              printerName: '',
              printerIp: '', printerId: '',
            );

    return Scaffold(
      backgroundColor: Color(0xFFDFF3E3),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDesktop),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: isDesktop ? 280 : (isTablet ? 250 : 200),
                    child: _buildCategoriesSection(isDesktop),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProductsSection(
                      isDesktop,
                      isTablet,
                      selectedCategory,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildBottomActions(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 10 : 8,
        horizontal: isDesktop ? 16 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  widget.isAddingToExistingOrder
                      ? Icons.add_shopping_cart
                      : Icons.shopping_cart,
                  color: AppColors.white,
                  size: isDesktop ? 24 : 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isAddingToExistingOrder
                            ? "Mahsulot qo'shish"
                            : "Yangi hisob",
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.isAddingToExistingOrder
                            ? "Zakaz: ${widget.existingOrderId?.substring(0, 8) ?? ''}"
                            : "Hodim: ${widget.user.firstName}",
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 10,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 200 : 150),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Qidirish...',
                    hintStyle: TextStyle(
                      color: Colors.white70,
                      fontSize: isDesktop ? 12 : 10,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.white,
                      size: isDesktop ? 18 : 16,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 8 : 6,
                      horizontal: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: isDesktop ? 12 : 10,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterProductsByCategory();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppColors.white,
                  size: isDesktop ? 24 : 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Color(0xFFDFF3E3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.category, color: AppColors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Kategoriyalar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
            _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  color: Color(0xFF144D37),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color:
                      _selectedCategoryId == category.id
                          ? AppColors.primary
                          : AppColors.lightGrey,
                      width: _selectedCategoryId == category.id ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      _getCategoryIcon(category.title),
                      size: 18,
                      color: Colors.white,
                    ),
                    title: Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap:
                        () => _selectCategory(
                      category.id,
                      category.title,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(
      bool isDesktop,
      bool isTablet,
      Category selectedCategory,
      ) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white60,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategoryName.isNotEmpty
                      ? '$_selectedCategoryName${_selectedSubcategory != null ? " ($_selectedSubcategory)" : ""}'
                      : 'Mahsulotlar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          if (selectedCategory.subcategories != null &&
              selectedCategory.subcategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSubcategoryChip(null, 'Barchasi'),
                        const SizedBox(width: 8),
                        ...selectedCategory.subcategories
                            .map(
                              (sub) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildSubcategoryChip(sub, sub),
                          ),
                        )
                            .toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
              _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : _filteredProducts.isEmpty
                  ? Center(
                child: Text(
                  _selectedCategoryId == null && _searchQuery.isEmpty
                      ? 'Kategoriyani tanlang'
                      : 'Mahsulot topilmadi',
                  style: const TextStyle(color: AppColors.grey),
                ),
              )
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 5 : (isTablet ? 4 : 3),
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return _buildProductCard(product, isDesktop);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryChip(String? subcategory, String label) {
    final isActive = _selectedSubcategory == subcategory;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        _selectCategory(
          _selectedCategoryId!,
          _selectedCategoryName,
          subcategory: selected ? subcategory : null,
        );
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isActive ? Colors.white : Colors.black),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.lightGrey,
        ),
      ),
    );
  }

  Widget _buildProductCard(Ovqat product, bool isDesktop) {
    final cartEntry = _cart[product.id];
    final int quantityInCart = cartEntry?['quantity']?.toInt() ?? 0;
    final double kgInCart =
    product.unit == 'kg'
        ? (cartEntry?['quantity']?.toDouble() ?? 1.0)
        : 1.0;
    final double totalPrice =
    product.unit == 'kg'
        ? product.price * kgInCart
        : product.price * quantityInCart;

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxCardWidth = isDesktop ? 220 : constraints.maxWidth * 0.5;

        return GestureDetector(
          onTap: () {
            if (product.unit == 'kg') {
              _showKgInputModal(context, product);
            } else {
              _updateCart(product.id, 1);
            }
          },
          child: Container(
            constraints: BoxConstraints(maxWidth: maxCardWidth, maxHeight: 180),
            decoration: BoxDecoration(
              color: const Color(0xFF144D37),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                quantityInCart > 0 || kgInCart > 0
                    ? Colors.white
                    : Colors.grey[400]!,
                width: quantityInCart > 0 || kgInCart > 0 ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    product.unit == 'kg'
                        ? '${_currencyFormatter.format(product.price)} so\'m/kg'
                        : '${_currencyFormatter.format(product.price)} ${product.unit} so\'m',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: AutoSizeText(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 3,
                      minFontSize: 8,
                      maxFontSize: 15,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (product.unit == 'kg' && kgInCart > 0) ...[
                      GestureDetector(
                        onTap: () => _updateCart(product.id, -1),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.remove,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (product.unit == 'kg') {
                            _showKgInputModal(context, product);
                          } else {
                            _updateCart(product.id, 1);
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: const Color(0xFF144D37),
                          ),
                        ),
                      ),
                    ] else if (product.unit != 'kg' && quantityInCart > 0) ...[
                      GestureDetector(
                        onTap: () => _updateCart(product.id, -1),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.remove,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$quantityInCart',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (product.unit == 'kg') {
                            _showKgInputModal(context, product);
                          } else {
                            _updateCart(product.id, 1);
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: const Color(0xFF144D37),
                          ),
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () {
                          if (product.unit == 'kg') {
                            _showKgInputModal(context, product);
                          } else {
                            _updateCart(product.id, 1);
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: const Color(0xFF144D37),
                          ),
                        ),
                      ),
                      SizedBox(width: 15,),
                      GestureDetector(
                        onTap: () => _showNoteInputModal(context, product),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    ],
                  ],
                ),
                if ((product.unit == 'kg' && kgInCart > 0) ||
                    (product.unit != 'kg' && quantityInCart > 0))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Jami: ${_currencyFormatter.format(totalPrice)} so\'m',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNoteInputModal(BuildContext context, Ovqat product) {
    final currentNote = _cart[product.id]?['note'] ?? '';
    final TextEditingController noteController =
    TextEditingController(text: currentNote);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Izoh qo‘shish - ${product.name}"),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Izoh qo‘shish ...",
              border: OutlineInputBorder(),
            ),
            onTap: (){
              KeyboardManager.showKeyboard(context, noteController);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Bekor qilish"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_cart.containsKey(product.id)) {
                    _cart[product.id]!['note'] = noteController.text;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text("Saqlash"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomActions(bool isDesktop) {
    final double total = _calculateTotal();
    final bool isCartEmpty = _cart.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFDFF3E3),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 200 : 150),
            child: OutlinedButton.icon(
              onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text(
                'Bekor qilish',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                side: const BorderSide(color: AppColors.grey),
                foregroundColor: AppColors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 300 : 250),
            child: ElevatedButton.icon(
              onPressed:
              (isCartEmpty || _isSubmitting)
                  ? null
                  : (widget.isAddingToExistingOrder
                  ? _addItemsToExistingOrder
                  : _createOrderUltraFast),
              icon:
              _isSubmitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
                  : Icon(
                widget.isAddingToExistingOrder
                    ? Icons.add_shopping_cart
                    : Icons.restaurant_menu,
                size: 18,
              ),
              label: Text(
                _isSubmitting
                    ? (widget.isAddingToExistingOrder
                    ? 'Qo\'shilmoqda...'
                    : 'Yuborilmoqda...')
                    : (widget.isAddingToExistingOrder
                    ? 'Mahsulot qo\'shish (${_currencyFormatter.format(total)} so\'m)'
                    : 'Zakaz berish (${_currencyFormatter.format(total)} so\'m)'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                (isCartEmpty || _isSubmitting)
                    ? AppColors.grey
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showKgInputModal(BuildContext context, Ovqat product) {
    double kg = _cart[product.id]?['quantity']?.toDouble() ?? 1.0;
    double price = product.price * kg;
    TextEditingController kgController = TextEditingController(
      text: kg.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(6), // Yanada kichik padding
              titlePadding: const EdgeInsets.only(top: 6, left: 6, right: 6),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // Kichikroq
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.scale,
                          color: Colors.white,
                          size: 14,
                        ), // Kichik ikonka
                        const SizedBox(width: 4),
                        const Text(
                          'AFITSANT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12, // Kichik font
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ), // Kichik font
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Narxi: ${_currencyFormatter.format(product.price)} so\'m/kg',
                    style: const TextStyle(
                      fontSize: 14, // Kichik font
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: 220, // Yanada kichik kenglik
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ), // Kichik
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        kgController.text.isEmpty
                            ? '0 kg'
                            : '${kgController.text} kg',
                        style: const TextStyle(
                          fontSize: 14, // Kichik font
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 1.4, // Kichikroq tugmalar
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                      children: [
                        for (int i = 1; i <= 9; i++)
                          _buildNumberButton(i.toString(), () {
                            setState(() {
                              kgController.text += i.toString();
                              kg = double.tryParse(kgController.text) ?? 0.0;
                              price = product.price * kg;
                            });
                          }),
                        _buildNumberButton('0', () {
                          setState(() {
                            kgController.text += '0';
                            kg = double.tryParse(kgController.text) ?? 0.0;
                            price = product.price * kg;
                          });
                        }),
                        _buildNumberButton('.', () {
                          setState(() {
                            if (!kgController.text.contains('.')) {
                              kgController.text += '.';
                            }
                          });
                        }),
                        _buildNumberButton('←', () {
                          // Backspace
                          setState(() {
                            if (kgController.text.isNotEmpty) {
                              kgController.text = kgController.text.substring(
                                0,
                                kgController.text.length - 1,
                              );
                              kg = double.tryParse(kgController.text) ?? 0.0;
                              price = product.price * kg;
                            }
                          });
                        }, isSpecial: true),
                        _buildNumberButton('C', () {
                          // Clear
                          setState(() {
                            kgController.text = '';
                            kg = 0.0;
                            price = 0.0;
                          });
                        }, isSpecial: true),
                      ],
                    ),

                    const SizedBox(height: 6),
                    // Tan narxi va yangi narxi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Yangi narxi: ${_currencyFormatter.format(price)} so\'m',
                          style: const TextStyle(
                            fontSize: 11, // Kichik font
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ), // Kichik
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            'Qaytish',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ), // Kichik font
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                          kg > 0
                              ? () {
                            _updateCart(product.id, 1, kg: kg);
                            Navigator.of(context).pop();
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ), // Kichik
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                          ),
                          child: const Text(
                            'Saqlash',
                            style: TextStyle(
                              fontSize: 10, // Kichik font
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Tugma funksiyasi (eski _buildNumberButton ni almashtiring)
  Widget _buildNumberButton(
      String text,
      VoidCallback onTap, {
        bool isSelected = false,
        bool isSpecial = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSpecial ? 12 : 14, // Kichikroq font
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addItemsToExistingOrder() async {
    if (_isSubmitting || _cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      showCenterSnackBar(
        context,
        'Mahsulotlar qo\'shilmoqda...',
        color: Colors.blue,
      );

      _sendAddItemsInBackground();

      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          showCenterSnackBar(
            context,
            'Mahsulotlar qo\'shildi!',
            color: Colors.green,
          );
          widget.onOrderCreated?.call();
          Navigator.of(context).pop();
        }
      });
    } finally {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) setState(() => _isSubmitting = false);
      });
    }
  }
  List<int> _createPrintDataForAddition(Map<String, dynamic> data) {
    final bytes = <int>[];
    const printerWidth = 32;

    bytes.addAll([0x1B, 0x40]); // Reset
    bytes.addAll([0x1B, 0x74, 17]); // CP866

    bytes.addAll([0x1B, 0x61, 1]); // Center
    bytes.addAll(_encodeText('QO\'SHIMCHA MAHSULOT\r\n'));
    bytes.addAll(
        _encodeText('Zakaz : ${widget.formatted_order_number}\r\n'));
    bytes.addAll(_encodeText('Ofitsiant: ${data['waiter_name']}\r\n'));

    final tableLine =
        '${data['table_name']}'.padRight(15) +
            DateTime.now().toString().substring(11, 16);
    bytes.addAll(_encodeText(tableLine + '\r\n'));

    bytes.addAll(_encodeText('=' * printerWidth + '\r\n'));

    for (final item in data['items']) {
      final name = item['name'].toString();
      final qty = item['qty'].toString();
      final line = name.padRight(20) + qty;

      bytes.addAll([0x1B, 0x61, 0]); // Left
      bytes.addAll(_encodeText(line + '\r\n'));

      // ✏️ Qo‘shimcha izohni chiqarish
      final note = _cart[item['id']]?['note'] ?? '';
      if (note.isNotEmpty) {
        bytes.addAll(_encodeText('  -> $note\r\n'));
      }
    }

    bytes.addAll(_encodeText('=' * printerWidth + '\r\n'));
    bytes.addAll(_encodeText('\r\n\r\n\r\n\r\n\r\n'));
    bytes.addAll([0x1D, 0x56, 0]); // Cut

    return bytes;
  }
}
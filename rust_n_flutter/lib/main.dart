import 'package:flutter/material.dart';
//import 'package:rust_n_flutter/src/rust/api/simple.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rust_n_flutter/src/rust/api/cryptotran.dart';
import 'package:rust_n_flutter/src/rust/frb_generated.dart';
import 'package:rust_n_flutter/keymanager.dart';
import 'database_helper.dart';

Future<void> main(List<String> args) async {
  String userId = args.isNotEmpty ? args[0] : 'default_user';
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await RustLib.init();
  runApp(MyApp(userId: userId));
}

class MyApp extends StatelessWidget {

  final String userId;

  MyApp({required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(userId: userId),
    );
  }
}

class HomePage extends StatefulWidget {
  final String userId;
  HomePage({required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _data = [];
  late String _userId;
  RsaKeyPair? _rsaKeyPair;
  Map<String, String>? _retrievedKeys;
  final KeyManager keyManager = getKeyManager();

  @override
  void initState() {
    super.initState();
    _userId = widget.userId; // 전달받은 userId 사용
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _dbHelper.fetchData();
    setState(() {
      _data = data;
    });
  }

  Future<void> _insertData(String recipientId, double amount) async {
    await _dbHelper.insertData(_userId, recipientId, amount);
    _fetchData();
  }

  Future<void> _updateData(int id, String recipientId, double amount) async {
    await _dbHelper.updateData(id, recipientId, amount);
    _fetchData();
  }

  Future<void> _deleteData(int id) async {
    await _dbHelper.deleteData(id);
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final recipientController = TextEditingController();
    final amountController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter & SQLite with Rust'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 기존 Flutter SQLite CRUD 영역
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text('SQLite CRUD Example', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              enabled: false,
                              controller: TextEditingController(text: _userId), // 변경: controller에 _userId 설정
                              decoration: InputDecoration(
                                labelText: 'Sender ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: recipientController,
                              decoration: InputDecoration(
                                labelText: 'Recipient ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(width: 10),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final recipientId = recipientController.text;
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (recipientId.isNotEmpty && amount > 0) {
                        _insertData(recipientId, amount);
                      }
                    },
                    child: Text('Add Transaction'),
                  ),
                  Divider(height: 30, thickness: 2),
                ],
              ),
            ),
            // Rust Integration 영역
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Rust Integration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final rsaKeyPair = await generateRsaKeyPair();

                        await writePemFile(
                          path: "rsa_private_key.pem",
                          pem: rsaKeyPair.privateKeyPem,
                        );

                        await writePemFile(
                          path: "rsa_public_key.pem",
                          pem: rsaKeyPair.publicKeyPem,
                        );

                        setState(() {
                          _rsaKeyPair = rsaKeyPair;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Keys saved successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text("Generate and Save RSA Keys"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_rsaKeyPair != null) {
                        try {
                          await keyManager.saveKeys(
                            "rsaKey_$_userId",
                            _rsaKeyPair!.privateKeyPem,
                            _rsaKeyPair!.publicKeyPem,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Keys saved to platform successfully!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No keys generated yet!')),
                        );
                      }
                    },
                    child: const Text("Save Keys to Platform"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final keys = await keyManager.readKeys("rsaKey_$_userId");

                        setState(() {
                          _retrievedKeys = keys;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Keys retrieved successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text("Read Keys from Platform"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Generate symmetric key
                        final key = await generateSymmetricKey();

                        // Encrypt data
                        const plainText = "Hello, Flutter!";
                        final encrypted = await encrypt(
                          plainText: plainText,
                          key: key,
                        );

                        // Decrypt data
                        final decrypted = await decrypt(
                          encryptedData: encrypted.$1,
                          key: key,
                          iv: encrypted.$2,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Decrypted: $decrypted')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text("Test Encryption/Decryption"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final privateKey = _retrievedKeys!['privateKey'] ?? '';
                        final publicKey = _retrievedKeys!['publicKey'] ?? '';
                        const message = "Sample Transaction";

                        // Sign the message
                        final signature = await sign(origText: message, privateKey: privateKey);

                        // Verify the signature
                        final isValid = await verifySignature(
                          signature: signature,
                          origText: message,
                          publicKeyPem: publicKey,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Signature Valid: $isValid')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text("Sign and Verify Transaction"),
                  ),

                  if (_retrievedKeys != null)
                    Column(
                      children: [
                        Text('Retrieved Private Key:\n${_retrievedKeys!['privateKey']}'),
                        Text('Retrieved Public Key:\n${_retrievedKeys!['publicKey']}'),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

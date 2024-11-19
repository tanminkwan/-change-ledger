import 'package:flutter/material.dart';
//import 'package:rust_n_flutter/src/rust/api/simple.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rust_n_flutter/src/rust/api/cryptotran.dart';
import 'package:rust_n_flutter/src/rust/frb_generated.dart';
import 'dart:convert';
import 'keymanager.dart';
import 'database_helper.dart';
import 'config.dart';

//import 'rtc_network.dart';

Future<void> main(List<String> args) async {
  String userId = args.isNotEmpty ? args[0] : 'default_user';

  // Binding 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await Config.loadConfig(userId);
  
  // Print the loaded configuration
  //log('Loaded Configuration:');
  //log('DHT Servers: ${Config.dhtServers}');
  //log('Database Connection: ${Config.dbConnection}');

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // 데이터베이스 초기화
  //DatabaseHelper.getInstance('chained-$userId.db');

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

  final DatabaseHelper _dbHelper = DatabaseHelper(dbName: Config.dbConnection);

  Map<String, dynamic> _data = {};
  late String _userId;
  RsaKeyPair? _rsaKeyPair;
  Map<String, String>? _retrievedKeys;
  //late RTCNetwork _rtcNetwork;

  final KeyManager keyManager = getKeyManager();

  @override
  void initState() {
    
    super.initState();

    _userId = widget.userId; // 전달받은 userId 사용
    //_fetchData();

    /*
    _rtcNetwork = RTCNetwork(userId: _userId);
    _rtcNetwork.messages.listen((message) {
      setState(() {
        print("Received: $message");
      });
    });
    */
  }

  @override
  void dispose() {
    //_rtcNetwork.dispose();
    super.dispose();
  }

  Future<void> _fetchData(String transactionId) async {
    final data = await _dbHelper.fetchData(transactionId);
    setState(() {
      _data = data ?? {}; // null일 경우 빈 맵으로 대체
    });
  }

  Future<EncryptedMessage> _encrypData(String recipientId, double amount) async {
    final privateKey = _retrievedKeys!['privateKey'] ?? '';
    final recipientkey = await keyManager.readKey("stamp_$recipientId");

    final transactionId = await _dbHelper.insertData(_userId, recipientId, amount);
    await _fetchData(transactionId);

    // 1. _data를 JSON으로 직렬화
    final text = jsonEncode({
      "transaction_id": _data["transaction_id"],
      "sender_id": _data["sender_id"],
      "recipient_id": _data["recipient_id"],
      "amount": _data["amount"],
      "timestamp": _data["timestamp"],
    });

    print("text 1 : $text");
    print("transaction_id 1 : $transactionId");
    
    // 2. Rust 함수 호출
    final encryptedMessage = await createSecurePayload(
      text: text,
      privateKeyPem: privateKey,
      publicKeyPem: recipientkey,
    );
    
    // 3. 결과 처리
    print("Encrypted Payload: ${encryptedMessage.encryptedPayload}");
    print("IV: ${encryptedMessage.iv}");
    print("Encrypted Symmetric Key: ${encryptedMessage.symmetricKey}");

    // 3. EncryptedMessage 반환
    return encryptedMessage;

  }

  Future<Map<String, dynamic>> _decryptData(
      EncryptedMessage encryptedMessage,
      String senderId,
  ) async {

    final privateKey = _retrievedKeys!['privateKey'] ?? '';
    final senderKey = await keyManager.readKey("stamp_$senderId");

    // Rust 함수 호출
    final decryptedText = await verifyAndDecryptPayload(
      encryptedMessage: encryptedMessage,
      recipientPrivateKeyPem: privateKey,
      senderPublicKeyPem: senderKey,
    );

    // JSON 디시리얼라이즈
    final Map<String, dynamic> deserializedData = jsonDecode(decryptedText);

    return deserializedData;
    
  }

  Future<void> _updateData(int id, String recipientId, double amount) async {
    await _dbHelper.updateData(id, recipientId, amount);
  }

  Future<void> _deleteData(int id) async {
    await _dbHelper.deleteData(id);
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
                    onPressed: () async {
                      final recipientId = recipientController.text;
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (recipientId.isNotEmpty && amount > 0) {

                        final encryptedMessage = await _encrypData(recipientId, amount);
                        print("Encrypted Payload: ${encryptedMessage.encryptedPayload}");
                        print("IV: ${encryptedMessage.iv}");
                        print("Encrypted Symmetric Key: ${encryptedMessage.symmetricKey}");

                      }
                    },
                    child: Text('Send Transaction'),
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
                          await keyManager.saveKeyPair(
                            "sealstamp_$_userId",
                            _rsaKeyPair!.privateKeyPem,
                            _rsaKeyPair!.publicKeyPem,
                          );

                          await keyManager.saveKey(
                            "stamp_$_userId",
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
                        final keys = await keyManager.readKeyPair("sealstamp_$_userId");

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

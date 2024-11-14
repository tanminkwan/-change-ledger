import 'package:flutter/material.dart';
import 'package:rust_n_flutter/src/rust/api/simple.dart';
import 'package:rust_n_flutter/src/rust/api/cryptotran.dart';
import 'package:rust_n_flutter/src/rust/frb_generated.dart';
import 'package:rust_n_flutter/keymanager.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

const String userId = "tiffanie"; // Define global user ID

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RsaKeyPair? _rsaKeyPair;
  Map<String, String>? _retrievedKeys;
  final KeyManager keyManager = getKeyManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(title: const Text('flutter_rust_bridge Test')),
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Action: Call Rust `greet("$userId")`\nResult: `${greet(name: userId)}`'),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final rsaKeyPair = await generateRsaKeyPair();

                          // Save private key
                          await writePemFile(
                            path: "rsa_private_key.pem",
                            pem: rsaKeyPair.privateKeyPem,
                          );

                          // Save public key
                          await writePemFile(
                            path: "rsa_public_key.pem",
                            pem: rsaKeyPair.publicKeyPem,
                          );

                          setState(() {
                            _rsaKeyPair = rsaKeyPair;
                          });

                          if (!mounted) return;
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
                    ElevatedButton(
                      onPressed: () async {
                        if (_rsaKeyPair != null) {
                          try {
                            await keyManager.saveKeys(
                              "rsaKey_$userId",
                              _rsaKeyPair!.privateKeyPem,
                              _rsaKeyPair!.publicKeyPem,
                            );

                            if (!mounted) return;
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
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final keys = await keyManager.readKeys("rsaKey_$userId");
                          
                          setState(() {
                            _retrievedKeys = keys;
                          });

                          if (!mounted) return;
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

                          if (!mounted) return;
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
            ),
          );
        },
      ),
    );
  }
}
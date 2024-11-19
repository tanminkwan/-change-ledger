//keymanager.dart
import 'package:platform/platform.dart';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:convert';
import 'dart:developer';

const platform = LocalPlatform();

Future<void> saveToCredentialManager(
    String keyName, String key) async {
  // 데이터 준비
  final data = utf8.encode(key);

  // CREDENTIAL 구조체 생성
  final credential = calloc<CREDENTIAL>();
  credential.ref
    ..Type = CRED_TYPE.CRED_TYPE_GENERIC
    ..TargetName = TEXT(keyName)
    ..CredentialBlob = calloc<Uint8>(data.length)
    ..CredentialBlobSize = data.length
    ..Persist = CRED_PERSIST.CRED_PERSIST_LOCAL_MACHINE
    ..AttributeCount = 0;

  // 데이터 복사
  final blob = credential.ref.CredentialBlob.asTypedList(data.length);
  blob.setAll(0, data);

  // Credential 저장
  if (CredWrite(credential, 0) == 0) {
    final errorCode = GetLastError();
    log('Failed to write to Credential Manager: $errorCode');
  } else {
    log('Successfully saved to Credential Manager.');
  }

  // 메모리 해제
  calloc.free(credential.ref.CredentialBlob);
  calloc.free(credential.ref.TargetName);
  calloc.free(credential);

}

Future<String> readFromCredentialManager(String keyName) async {
  final pCredential = calloc<Pointer<CREDENTIAL>>();

  try {
    // CredRead 호출
    if (CredRead(TEXT(keyName), CRED_TYPE.CRED_TYPE_GENERIC, 0, pCredential) == 0) {
      final errorCode = GetLastError();
      throw Exception('Failed to read from Credential Manager: $errorCode');
    }

    // CREDENTIAL 구조체 읽기
    final credential = pCredential.value.ref;

    // 데이터 추출
    final blob = credential.CredentialBlob.asTypedList(credential.CredentialBlobSize);
    final decodedData = String.fromCharCodes(blob);

    return decodedData;

  } finally {
    // 메모리 해제
    CredFree(pCredential.value);
    calloc.free(pCredential);
  }

}

Future<Map<String, String>> readRsaKeypair(String keyName) async {
  final key = await readFromCredentialManager(keyName);
  final parts = key.split('\n|\n');

    return {
      'privateKey': parts.isNotEmpty ? parts[0] : '',
      'publicKey': parts.length > 1 ? parts[1] : '',
    };

}

abstract class KeyManager {
  Future<void> saveKeyPair(String keyName, String privateKey, String publicKey);
  Future<Map<String, String>> readKeyPair(String keyName);
  Future<void> saveKey(String keyName, String Key);
  Future<String> readKey(String keyName);
}

// Extend the WindowsKeyManager to include the readKeys method
class WindowsKeyManager implements KeyManager {
  @override
  Future<void> saveKeyPair(String keyName, String privateKey, String publicKey) async {
    await saveToCredentialManager(keyName, '$privateKey\n|\n$publicKey');
  }

  @override
  Future<Map<String, String>> readKeyPair(String keyName) async {
    return await readRsaKeypair(keyName);
  }

  @override
  Future<void> saveKey(String keyName, String key) async {
    await saveToCredentialManager(keyName, key);
  }

  @override
  Future<String> readKey(String keyName) async {
    return await readFromCredentialManager(keyName);
  }

}

// Ensure AndroidKeyManager implements readKeys
class AndroidKeyManager implements KeyManager {
  @override
  Future<void> saveKeyPair(String keyName, String privateKey, String publicKey) async {
    // await saveToAndroidKeystore(privateKey, publicKey);
  }

  @override
  Future<Map<String, String>> readKeyPair(String keyName) async {
    // Implement reading keys from Android Keystore
    return {'privateKey': '', 'publicKey': ''};
  }

  @override
  Future<void> saveKey(String keyName, String key) async {
    // await saveToAndroidKeystore(yey);
  }

  @override
  Future<String> readKey(String keyName) async {
    // Implement reading keys from Android Keystore
    return '';
  }


}

KeyManager getKeyManager() {
  if (platform.isWindows) {
    return WindowsKeyManager();
  } else if (platform.isAndroid) {
    return AndroidKeyManager();
  } else {
    throw UnsupportedError('Unsupported platform');
  }
}

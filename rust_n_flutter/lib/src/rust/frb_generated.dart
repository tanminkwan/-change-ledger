// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.6.0.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api/cryptotran.dart';
import 'api/simple.dart';
import 'dart:async';
import 'dart:convert';
import 'frb_generated.dart';
import 'frb_generated.io.dart' if (dart.library.js_interop) 'frb_generated.web.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';


                /// Main entrypoint of the Rust API
                class RustLib extends BaseEntrypoint<RustLibApi, RustLibApiImpl, RustLibWire> {
                  @internal
                  static final instance = RustLib._();

                  RustLib._();

                  /// Initialize flutter_rust_bridge
                  static Future<void> init({
                    RustLibApi? api,
                    BaseHandler? handler,
                    ExternalLibrary? externalLibrary,
                  }) async {
                    await instance.initImpl(
                      api: api,
                      handler: handler,
                      externalLibrary: externalLibrary,
                    );
                  }

                  /// Initialize flutter_rust_bridge in mock mode.
                  /// No libraries for FFI are loaded.
                  static void initMock({
                    required RustLibApi api,
                  }) {
                    instance.initMockImpl(
                      api: api,
                    );
                  }

                  /// Dispose flutter_rust_bridge
                  ///
                  /// The call to this function is optional, since flutter_rust_bridge (and everything else)
                  /// is automatically disposed when the app stops.
                  static void dispose() => instance.disposeImpl();

                  @override
                  ApiImplConstructor<RustLibApiImpl, RustLibWire> get apiImplConstructor => RustLibApiImpl.new;

                  @override
                  WireConstructor<RustLibWire> get wireConstructor => RustLibWire.fromExternalLibrary;

                  @override
                  Future<void> executeRustInitializers() async {
                    await api.crateApiSimpleInitApp();

                  }

                  @override
                  ExternalLibraryLoaderConfig get defaultExternalLibraryLoaderConfig => kDefaultExternalLibraryLoaderConfig;

                  @override
                  String get codegenVersion => '2.6.0';

                  @override
                  int get rustContentHash => 1597962205;

                  static const kDefaultExternalLibraryLoaderConfig = ExternalLibraryLoaderConfig(
                    stem: 'rust_lib_rust_n_flutter',
                    ioDirectory: 'rust/target/release/',
                    webPrefix: 'pkg/',
                  );
                }
                

                abstract class RustLibApi extends BaseApi {
                  Future<String> crateApiCryptotranDecrypt({required List<int> encryptedData , required List<int> key , required List<int> iv });

Future<(Uint8List,Uint8List)> crateApiCryptotranEncrypt({required String plainText , required List<int> key });

Future<RsaKeyPair> crateApiCryptotranGenerateRsaKeyPair();

Future<Uint8List> crateApiCryptotranGenerateSymmetricKey();

String crateApiSimpleGreet({required String name });

Future<void> crateApiSimpleInitApp();

Future<String> crateApiCryptotranSign({required String origText , required String privateKey });

Future<bool> crateApiCryptotranVerifySignature({required String signature , required String origText , required String publicKeyPem });

Future<void> crateApiCryptotranWritePemFile({required String path , required String pem });


                }
                

                class RustLibApiImpl extends RustLibApiImplPlatform implements RustLibApi {
                  RustLibApiImpl({
                    required super.handler,
                    required super.wire,
                    required super.generalizedFrbRustBinding,
                    required super.portManager,
                  });

                  @override Future<String> crateApiCryptotranDecrypt({required List<int> encryptedData , required List<int> key , required List<int> iv })  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);sse_encode_list_prim_u_8_loose(encryptedData, serializer);
sse_encode_list_prim_u_8_loose(key, serializer);
sse_encode_list_prim_u_8_loose(iv, serializer);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 1, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_String,
          decodeErrorData: sse_decode_String,
        )
        ,
            constMeta: kCrateApiCryptotranDecryptConstMeta,
            argValues: [encryptedData, key, iv],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiCryptotranDecryptConstMeta => const TaskConstMeta(
            debugName: "decrypt",
            argNames: ["encryptedData", "key", "iv"],
        );
        

@override Future<(Uint8List,Uint8List)> crateApiCryptotranEncrypt({required String plainText , required List<int> key })  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);sse_encode_String(plainText, serializer);
sse_encode_list_prim_u_8_loose(key, serializer);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 2, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_record_list_prim_u_8_strict_list_prim_u_8_strict,
          decodeErrorData: sse_decode_String,
        )
        ,
            constMeta: kCrateApiCryptotranEncryptConstMeta,
            argValues: [plainText, key],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiCryptotranEncryptConstMeta => const TaskConstMeta(
            debugName: "encrypt",
            argNames: ["plainText", "key"],
        );
        

@override Future<RsaKeyPair> crateApiCryptotranGenerateRsaKeyPair()  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 3, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_rsa_key_pair,
          decodeErrorData: null,
        )
        ,
            constMeta: kCrateApiCryptotranGenerateRsaKeyPairConstMeta,
            argValues: [],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiCryptotranGenerateRsaKeyPairConstMeta => const TaskConstMeta(
            debugName: "generate_rsa_key_pair",
            argNames: [],
        );
        

@override Future<Uint8List> crateApiCryptotranGenerateSymmetricKey()  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 4, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_list_prim_u_8_strict,
          decodeErrorData: null,
        )
        ,
            constMeta: kCrateApiCryptotranGenerateSymmetricKeyConstMeta,
            argValues: [],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiCryptotranGenerateSymmetricKeyConstMeta => const TaskConstMeta(
            debugName: "generate_symmetric_key",
            argNames: [],
        );
        

@override String crateApiSimpleGreet({required String name })  { return handler.executeSync(SyncTask(
            callFfi: () {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);sse_encode_String(name, serializer);
            return pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 5)!;
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_String,
          decodeErrorData: null,
        )
        ,
            constMeta: kCrateApiSimpleGreetConstMeta,
            argValues: [name],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiSimpleGreetConstMeta => const TaskConstMeta(
            debugName: "greet",
            argNames: ["name"],
        );
        

@override Future<void> crateApiSimpleInitApp()  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 6, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_unit,
          decodeErrorData: null,
        )
        ,
            constMeta: kCrateApiSimpleInitAppConstMeta,
            argValues: [],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiSimpleInitAppConstMeta => const TaskConstMeta(
            debugName: "init_app",
            argNames: [],
        );
        

@override Future<String> crateApiCryptotranSign({required String origText , required String privateKey })  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);sse_encode_String(origText, serializer);
sse_encode_String(privateKey, serializer);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 7, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_String,
          decodeErrorData: sse_decode_String,
        )
        ,
            constMeta: kCrateApiCryptotranSignConstMeta,
            argValues: [origText, privateKey],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiCryptotranSignConstMeta => const TaskConstMeta(
            debugName: "sign",
            argNames: ["origText", "privateKey"],
        );
        

@override Future<bool> crateApiCryptotranVerifySignature({required String signature , required String origText , required String publicKeyPem })  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);sse_encode_String(signature, serializer);
sse_encode_String(origText, serializer);
sse_encode_String(publicKeyPem, serializer);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 8, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_bool,
          decodeErrorData: sse_decode_String,
        )
        ,
            constMeta: kCrateApiCryptotranVerifySignatureConstMeta,
            argValues: [signature, origText, publicKeyPem],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiCryptotranVerifySignatureConstMeta => const TaskConstMeta(
            debugName: "verify_signature",
            argNames: ["signature", "origText", "publicKeyPem"],
        );
        

@override Future<void> crateApiCryptotranWritePemFile({required String path , required String pem })  { return handler.executeNormal(NormalTask(
            callFfi: (port_) {
              
            final serializer = SseSerializer(generalizedFrbRustBinding);sse_encode_String(path, serializer);
sse_encode_String(pem, serializer);
            pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 9, port: port_);
            
            },
            codec: 
        SseCodec(
          decodeSuccessData: sse_decode_unit,
          decodeErrorData: sse_decode_String,
        )
        ,
            constMeta: kCrateApiCryptotranWritePemFileConstMeta,
            argValues: [path, pem],
            apiImpl: this,
        )); }


        TaskConstMeta get kCrateApiCryptotranWritePemFileConstMeta => const TaskConstMeta(
            debugName: "write_pem_file",
            argNames: ["path", "pem"],
        );
        



                  @protected String dco_decode_String(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
return raw as String; }

@protected bool dco_decode_bool(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
return raw as bool; }

@protected List<int> dco_decode_list_prim_u_8_loose(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
return raw as List<int>; }

@protected Uint8List dco_decode_list_prim_u_8_strict(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
return raw as Uint8List; }

@protected (Uint8List,Uint8List) dco_decode_record_list_prim_u_8_strict_list_prim_u_8_strict(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
final arr = raw as List<dynamic>;
            if (arr.length != 2) {
                throw Exception('Expected 2 elements, got ${arr.length}');
            }
            return (dco_decode_list_prim_u_8_strict(arr[0]),dco_decode_list_prim_u_8_strict(arr[1]),); }

@protected RsaKeyPair dco_decode_rsa_key_pair(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
final arr = raw as List<dynamic>;
                if (arr.length != 2) throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
                return RsaKeyPair(privateKeyPem: dco_decode_String(arr[0]),
publicKeyPem: dco_decode_String(arr[1]),); }

@protected int dco_decode_u_8(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
return raw as int; }

@protected void dco_decode_unit(dynamic raw){ // Codec=Dco (DartCObject based), see doc to use other codecs
return; }

@protected String sse_decode_String(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
var inner = sse_decode_list_prim_u_8_strict(deserializer);
        return utf8.decoder.convert(inner); }

@protected bool sse_decode_bool(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
return deserializer.buffer.getUint8() != 0; }

@protected List<int> sse_decode_list_prim_u_8_loose(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
var len_ = sse_decode_i_32(deserializer);
                return deserializer.buffer.getUint8List(len_); }

@protected Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
var len_ = sse_decode_i_32(deserializer);
                return deserializer.buffer.getUint8List(len_); }

@protected (Uint8List,Uint8List) sse_decode_record_list_prim_u_8_strict_list_prim_u_8_strict(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
var var_field0 = sse_decode_list_prim_u_8_strict(deserializer);
var var_field1 = sse_decode_list_prim_u_8_strict(deserializer);
return (var_field0, var_field1); }

@protected RsaKeyPair sse_decode_rsa_key_pair(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
var var_privateKeyPem = sse_decode_String(deserializer);
var var_publicKeyPem = sse_decode_String(deserializer);
return RsaKeyPair(privateKeyPem: var_privateKeyPem, publicKeyPem: var_publicKeyPem); }

@protected int sse_decode_u_8(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
return deserializer.buffer.getUint8(); }

@protected void sse_decode_unit(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
 }

@protected int sse_decode_i_32(SseDeserializer deserializer){ // Codec=Sse (Serialization based), see doc to use other codecs
return deserializer.buffer.getInt32(); }

@protected void sse_encode_String(String self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
sse_encode_list_prim_u_8_strict(utf8.encoder.convert(self), serializer); }

@protected void sse_encode_bool(bool self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
serializer.buffer.putUint8(self ? 1 : 0); }

@protected void sse_encode_list_prim_u_8_loose(List<int> self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
sse_encode_i_32(self.length, serializer);
                    serializer.buffer.putUint8List(self is Uint8List ? self : Uint8List.fromList(self)); }

@protected void sse_encode_list_prim_u_8_strict(Uint8List self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
sse_encode_i_32(self.length, serializer);
                    serializer.buffer.putUint8List(self); }

@protected void sse_encode_record_list_prim_u_8_strict_list_prim_u_8_strict((Uint8List,Uint8List) self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
sse_encode_list_prim_u_8_strict(self.$1, serializer);
sse_encode_list_prim_u_8_strict(self.$2, serializer);
 }

@protected void sse_encode_rsa_key_pair(RsaKeyPair self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
sse_encode_String(self.privateKeyPem, serializer);
sse_encode_String(self.publicKeyPem, serializer);
 }

@protected void sse_encode_u_8(int self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
serializer.buffer.putUint8(self); }

@protected void sse_encode_unit(void self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
 }

@protected void sse_encode_i_32(int self, SseSerializer serializer){ // Codec=Sse (Serialization based), see doc to use other codecs
serializer.buffer.putInt32(self); }
                }
                
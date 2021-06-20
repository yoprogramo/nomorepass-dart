import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class NmpCrypto {
  List<int> derive_key_and_iv(
      String password, List<int> salt, int key_length, int iv_lenght) {
    List<int> d = [];
    List<int> d_i = [];
    while (d.length < key_length + iv_lenght) {
      d_i = md5.convert(d_i + utf8.encode(password) + salt).bytes;
      d += d_i;
    }
    return d;
  }

  String encrypt(text, password) {
    var random = Random.secure();
    // Calculamos un random para salt (hasta 16 bytes)
    var salt = List<int>.generate(8, (i) => random.nextInt(256));
    final keyandiv = this.derive_key_and_iv(password, salt, 32, 16);

    final key = Key(Uint8List.fromList(keyandiv.sublist(0, 32)));
    final iv = IV(Uint8List.fromList(keyandiv.sublist(32, 32 + 16)));

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    List<int> res = utf8.encode('Salted__') + salt;
    final encrypted = encrypter.encrypt(text, iv: iv);
    res += encrypted.bytes;
    return base64.encode(res);
  }

  String decrypt(String text, String pass) {
    final input = base64.decode(text);
    final salt = input.sublist(8, 16);
    final keyandiv = this.derive_key_and_iv(pass, salt, 32, 16);
    final key = Key(Uint8List.fromList(keyandiv.sublist(0, 32)));
    final iv = IV(Uint8List.fromList(keyandiv.sublist(32, 32 + 16)));

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted =
        Encrypted.fromBase64(base64Encode(input.sublist(16, input.length)));
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }
}
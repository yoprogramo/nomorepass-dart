import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'crypto.dart';

class Nomorepass {
  String apikey = 'FREEAPI';
  String server = 'api.nomorepass.com';
  String base = 'https://api.nomorepass.com';
  String getidUrl = '';
  String checkUrl = '';
  String referenceUrl = '';
  String grantUrl = '';
  String pingUrl = '';
  bool stopped = false;
  String ticket = '';
  String token = '';

  Nomorepass([String? server, String? apikey]) {
    server ??= 'api.nomorepass.com';
    apikey ??= 'FREEAPI';
    this.apikey = apikey;
    this.server = server;
    this.base = "https://" + server;
    this.getidUrl = this.base + "/api/getid.php";
    this.checkUrl = this.base + "/api/check.php";
    this.referenceUrl = this.base + "/api/reference.php";
    this.grantUrl = this.base + "/api/grant.php";
    this.pingUrl = this.base + "/api/ping.php";
  }

  String newToken([int? size]) {
    final _random = new Random();
    String charset =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    if (size == null) size = 12;
    String ret = "";
    for (int i = 0; i < size; i++) {
      ret += charset[_random.nextInt(charset.length)];
    }
    return ret;
  }

  Future<String?> getQrText(String site) async {
    var data = {'site': site};
    var headers = {'User-Agent': 'NoMorePass-Dart/1.0', 'apikey': this.apikey};
    var url = Uri.parse(this.getidUrl);
    var resp = await http.post(url, headers: headers, body: data);
    if (resp.statusCode == 200) {
      final cuerpo = resp.body;
      final datos = json.decode(cuerpo);
      if (datos['resultado'] == 'ok') {
        this.ticket = datos['ticket'];
        this.token = this.newToken();
        final text = 'nomorepass://' + this.token + this.ticket + site;
        return text;
      }
    }
    return null;
  }
}

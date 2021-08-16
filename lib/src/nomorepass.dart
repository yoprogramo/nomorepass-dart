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
  NmpCrypto nmpc = new NmpCrypto();

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

  Future<String?> getQrNomorekeys(String? site, String user, String password,
      String type, Map? extra) async {
    // Returns the QR url to send a nomorekeys key to the phone
    // basically the same as getQRSend but with nomorekeys://
    // only available for soundkey and lightkey right now
    // SOUNDKEY passwords are limited to 14 characters
    // LIGHTKEY are a unsigned int
    if (type != "SOUNDKEY" && type != "LIGHTKEY") {
      return null;
    }
    if (site == null) {
      site = "WEBDEVICE";
    }
    final data = {'site': site};
    var headers = {'User-Agent': 'NoMorePass-Dart/1.0', 'apikey': this.apikey};
    var url = Uri.parse(this.getidUrl);
    var resp = await http.post(url, headers: headers, body: data);
    if (resp.statusCode == 200) {
      final cuerpo = resp.body;
      final datos = json.decode(cuerpo);
      if (datos['resultado'] == 'ok') {
        final token = this.newToken();
        this.token = token;
        this.ticket = datos['ticket'];
        if (type == 'SOUNDKEY') {
          password = password.padRight(14).substring(0, 14);
        } else {
          password = (int.parse(password) % 65536).toString();
        }
        final ep = this.nmpc.encrypt(password, token);
        String extrastr = '';
        if (extra != null) {
          if (extra.containsKey('extra')) {
            Map theextra = extra['extra'];
            if (theextra.containsKey('secret')) {
              extra['extra']['secret'] =
                  this.nmpc.encrypt(extra['extra']['secret'], token);
              extra['extra']['type'] = type.toLowerCase();
            } else {
              extra['extra'] = {'type': type.toLowerCase()};
            }
            extrastr = json.encode(extra);
          } else {
            extra = {
              'extra': {'type': type.toLowerCase()}
            };
            extrastr = json.encode(extra);
          }
        }
        final params = {
          'grant': 'grant',
          'ticket': this.ticket,
          'user': user,
          'password': ep,
          'extra': extrastr
        };
        url = Uri.parse(this.grantUrl);
        resp = await http.post(url, headers: headers, body: params);
        if (resp.statusCode == 200) {
          final dat = json.decode(resp.body);
          if (dat['resultado'] == 'ok') {
            final text = 'nomorekeys://' + type + token + dat['ticket'] + site;
            return text;
          }
        }
      }
    }
    return null;
  }

  Future<Map?> start() async {
    // Comenzamos a preguntar (check) si nos han enviado el pass
    // dado que esta función es síncrona no devolvemos el control
    // hasta que tenemos una respuesta (positiva o negativa)
    // o hasta que el valor del atributo stopped es cierto
    while (this.stopped == false) {
      final data = {'ticket': this.ticket};
      var headers = {
        'User-Agent': 'NoMorePass-Dart/1.0',
        'apikey': this.apikey
      };
      var url = Uri.parse(this.checkUrl);
      var resp = await http.post(url, headers: headers, body: data);
      if (resp.statusCode == 200) {
        final cuerpo = resp.body;
        //print(cuerpo);
        final decoded = json.decode(cuerpo);
        if (decoded['resultado'] == 'ok') {
          if (decoded['grant'] == 'deny') {
            return {'error': 'denied'};
          } else {
            if (decoded['grant'] == 'grant') {
              final res = {
                'user': decoded["usuario"],
                'password': nmpc.decrypt(decoded["password"], this.token),
                'extra': decoded['extra']
              };
              return res;
            } else {
              if (decoded['grant'] == 'expired') {
                return {'error': 'expired'};
              } else {
                await Future.delayed(Duration(seconds: 4));
              }
            }
          }
        } else {
          return {'error': decoded['error']};
        }
      } else {
        return {'error': 'network error'};
      }
    }
    this.stopped = false;
    return {'error': 'stopped'};
  }

  void stop() {
    this.stopped = true;
  }

  Future<String?> getQrSend(
      String? site, String user, String password, Map? extra) async {
    if (site == null) {
      site = "WEBDEVICE";
    }
    final data = {'site': site};
    final headers = {
      'User-Agent': 'NoMorePass-Dart/1.0',
      'apikey': this.apikey
    };
    var url = Uri.parse(this.getidUrl);
    var resp = await http.post(url, headers: headers, body: data);
    if (resp.statusCode == 200) {
      final cuerpo = resp.body;
      final datos = json.decode(cuerpo);
      if (datos['resultado'] == 'ok') {
        final token = this.newToken();
        this.token = token;
        this.ticket = datos['ticket'];
        final ep = this.nmpc.encrypt(password, token);
        String extrastr = '';
        if (extra != null) {
          if (extra.containsKey('extra')) {
            Map theextra = extra['extra'];
            if (theextra.containsKey('secret')) {
              extra['extra']['secret'] =
                  this.nmpc.encrypt(extra['extra']['secret'], token);
              extra['extra']['type'] = 'pwd';
            } else {
              extra['extra'] = {'type': 'pwd'};
            }
            extrastr = json.encode(extra);
          } else {
            extra = {
              'extra': {'type': 'pwd'}
            };
            extrastr = json.encode(extra);
          }
        }
        final params = {
          'grant': 'grant',
          'ticket': this.ticket,
          'user': user,
          'password': ep,
          'extra': extrastr
        };
        url = Uri.parse(this.grantUrl);
        resp = await http.post(url, headers: headers, body: params);
        if (resp.statusCode == 200) {
          final dat = json.decode(resp.body);
          if (dat['resultado'] == 'ok') {
            final text = 'nomorepass://SENDPASS' + token + dat['ticket'] + site;
            return text;
          }
        }
      }
    }
    return null;
  }

  Future<Map?> send() async {
    // Comprueba si la contraseña enviada
    // se ha recibido. Solo para cuando
    // se recibe una respuesta positiva o negativa
    // o se comprueba que stopped = true
    while (this.stopped == false) {
      final params = {'device': 'WEBDEVICE', 'ticket': this.ticket};
      final headers = {
        'User-Agent': 'NoMorePass-Dart/1.0',
        'apikey': this.apikey
      };
      final url = Uri.parse(this.pingUrl);
      var resp = await http.post(url, headers: headers, body: params);
      if (resp.statusCode == 200) {
        final dat = json.decode(resp.body);
        if (dat['resultado'] == 'ok' && dat['ping'] == 'ok') {
          await Future.delayed(Duration(seconds: 4));
        } else {
          return dat;
        }
      }
    }
    return {"error": "stopped"};
  }

  Future<Map?> sendRemotePassToDevice(String? cloud, String deviceid,
      String secret, String username, String password, Map? extra) async {
    // Envía una contraseña remota a un dispositivo cloud
    // cloud: url de /extern/send_ticket
    // devideid: id del dispositivo
    // secret: md5 del secreto del dispositivo
    // username: usuario
    // password: contraseña
    String cloudurl = 'https://api.nmkeys.com/extern/send_ticket';
    if (cloud != null) {
      cloudurl = cloud;
    }
    final token = secret;
    var params = {'site': 'Send remote pass'};
    final headers = {
      'User-Agent': 'NoMorePass-Dart/1.0',
      'apikey': this.apikey
    };
    var url = Uri.parse(this.getidUrl);
    var resp = await http.post(url, headers: headers, body: params);
    if (resp.statusCode == 200) {
      var dat = json.decode(resp.body);
      if (dat['resultado'] == 'ok') {
        final ticket = dat['ticket'];
        final ep = nmpc.encrypt(password, token);
        Map textra = {"type": "remote"};
        if (extra != null) {
          textra = extra;
        }
        params = {
          'grant': 'grant',
          'ticket': ticket,
          'user': username,
          'password': ep,
          'extra': json.encode(textra)
        };
        url = Uri.parse(this.grantUrl);
        resp = await http.post(url, headers: headers, body: params);
        if (resp.statusCode == 200) {
          dat = json.decode(resp.body);
          if (dat['resultado'] == 'ok') {
            params = {
              'hash': token.substring(0, 10),
              'ticket': ticket,
              'deviceid': deviceid
            };
            url = Uri.parse(cloudurl);
            resp = await http.post(url,
                headers: {'content-type': 'application/json'},
                body: utf8.encode(json.encode(params)));
            if (resp.statusCode == 200) {
              dat = json.decode(resp.body);
              return dat;
            } else {
              print(resp.statusCode);
              return {"error": "error calling $cloudurl"};
            }
          } else {
            return {"error": dat};
          }
        } else {
          return {"error": "error calling granturl"};
        }
      } else {
        return {"error": dat};
      }
    } else {
      return {"error": "error calling getid"};
    }
  }
}

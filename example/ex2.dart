import '../lib/nomorepass.dart';

void main() async {
  Nomorepass nmp = Nomorepass();

  Map? res = null;
  int expiry =
      (new DateTime.now().microsecondsSinceEpoch / 1000000).round() + 200;
  nmp.setExpiry(expiry); // 200 sec expiry
  print('Expiry: $expiry');
  print("Generating QR...");
  String? url =
      await nmp.getQrNomorekeys('testKey', 'Daniel', '123456', 'KEY', {
    'host': 'puertaCasa',
    'extra': {
      'deviceid': 300,
      'external_id': 840,
      'shleft': 0,
      'type': 'padkey'
    }
  });
  //print(await nmp.getQrText('prueba'));
  print(url);
  print("Scan this QR to send a password back");
  // res = null;
  Future.delayed(const Duration(seconds: 60), () {
    if (res == null) {
      nmp.stopped = true;
    }
  }).then((value) {
    if (nmp.stopped == true) {
      print("Aborted!");
      nmp.stop();
    }
  });
  print("Waiting for reception (30sec waiting)");
  nmp.stopped = false;
  res = await nmp.send();
  if (res != null && res.containsKey('error')) {
    print("Error ${res['error']}");
  } else {
    if (res != null) {
      print("Password received:");
    }
  }
}

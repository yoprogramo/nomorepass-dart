import '../lib/nomorepass.dart';

void main() async {
  // Nomorepass inicialization
  Nomorepass nmp = Nomorepass();
  // Create token
  String texto = nmp.newToken(10);
  print("New token: $texto");

  // Crypto services
  NmpCrypto nmpc = NmpCrypto();
  final enc = nmpc.encrypt('lo que quiero enscriptar', 'TOKEN');
  final dec = nmpc.decrypt(enc, 'TOKEN');
  print("Encrypted text: $enc");
  print("Decrypted text: $dec");

  // Remote pasword sending
  print("Sending password to remote device");
  print(await nmp.sendRemotePassToDevice(
      'https://test.nmkeys.com/extern/send_ticket',
      'DNCM91E3VO',
      '26bd80fd7c445933525c5768f58e1882',
      'test1remoto',
      'test1remoto', {
    'type': 'remote',
    'position': {'lat': 40.3488923, 'lon': -3.8079261}
  }));
  print("Sent!");
  // Password distribution
  // QR to send a key to mobile phone
  print("Generating QR");
  print(await nmp
      .getQrNomorekeys("TestSoundKey", "key", "Secret key", "SOUNDKEY", {
    'extra': {'secret': '1234567890123456'}
  }));
  print("Scan this QR to receive a new soundkey");
  print("Generating QR");
  print(await nmp.getQrSend("Test password", "usertest", "mypassword", {}));
  print("Scan this QR to receive a new password");
  Map? res = null;
  Future.delayed(const Duration(seconds: 30), () {
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
  res = await nmp.send();
  // QR to send a password
  print("Generating QR...");
  print(await nmp.getQrText('prueba'));
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
  res = await nmp.start();
  if (res != null && res.containsKey('error')) {
    print("Error ${res['error']}");
  } else {
    if (res != null) {
      print("User: ${res['user']}");
      print("Pass: ${res['password']}");
      print("Extra: ${res['extra']}");
    }
  }
}

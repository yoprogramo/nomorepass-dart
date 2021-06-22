# NoMorePass DART libraries

This library allows you to use the nomorepass.com system to send and
receive credentials using nomorepass mobile application. It is intended 
to use in any environment, so it does not generate / print the qr-code, 
instead provides the text that should be included in the qrcode 
(you can generate using any qrcode libraries).

## Usage

To receive passwords:

```
// Nomorepass inicialization
  Nomorepass nmp = Nomorepass();
  
  // QR to send a password
  print("Generating QR...");
  print(await nmp.getQrText('test'));
  print("Draw and scan this QR with nomorepass to send a password back");
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
```

To send password:

```
  print("Generating QR");
  print(await nmp.getQrSend("Test password", "usertest", "mypassword", {}));
  print("Scan this QR with nomorepass to receive a new password");
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
  print ("Received!);
```

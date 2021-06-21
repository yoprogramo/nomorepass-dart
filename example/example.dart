import '../lib/nomorepass.dart';

void main() async {
  Nomorepass nmp = Nomorepass();
  String texto = nmp.newToken(10);
  NmpCrypto nmpc = NmpCrypto();

  final enc = nmpc.encrypt('lo que quiero enscriptar', 'TOKEN');
  final dec = nmpc.decrypt(enc, 'TOKEN');

  print(await nmp.getQrText('prueba'));
  print(texto);
  print(enc);
  print(dec);
  print (await nmp.getQrNomorekeys("TestSoundKey","key","Secret key","SOUNDKEY",{'extra': {'secret': '1234567890123456'}}));
}

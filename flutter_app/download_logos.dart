import 'dart:io';

void main() async {
  final dir = Directory('assets/logo');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  
  final httpClient = HttpClient();
  
  final req1 = await httpClient.getUrl(Uri.parse('https://res.cloudinary.com/dsnatrse2/image/upload/v1783339653/Logo_nu9vjd.png'));
  final res1 = await req1.close();
  await res1.pipe(File('assets/logo/black_logo.png').openWrite());

  final req2 = await httpClient.getUrl(Uri.parse('https://res.cloudinary.com/dsnatrse2/image/upload/v1783339652/Logo1_xickjx.png'));
  final res2 = await req2.close();
  await res2.pipe(File('assets/logo/white_logo.png').openWrite());
  
  print('Logos downloaded');
}

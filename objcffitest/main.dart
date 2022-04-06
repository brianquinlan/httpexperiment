import 'dart:ffi';
import 'nsurlsession_bindings.dart';

main() {
  final lib = DynamicLibrary.open(
      "/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit");
  final app = NativeLibrary(lib);
  print(app.NSFoundationVersionNumber);
}

# leak_sniffer_example

Example صغير وواضح لقاعدة `avoid_unclosed_stream_controller`.

الملف الأساسي هو:

- [lib/main.dart](/Users/tolba/StudioProjects/leak_sniffer/apps/leak_sniffer_example/lib/main.dart)

فيه `StreamController<int>` بيتعمل له `add()` داخل الزرار، لكن مفيش `close()` داخل `dispose()`.

شغّل من root:

```bash
make watch
```

أو:

```bash
cd apps/leak_sniffer_example
dart run custom_lint
```

ولما تصلح الكود بالشكل ده، الـwarning يختفي:

```dart
@override
void dispose() {
  _counterStream.close();
  super.dispose();
}
```

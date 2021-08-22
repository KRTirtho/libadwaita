import 'package:flutter/material.dart';
import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:gtk/gtk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = GnomeTheme();
    return MaterialApp(
      title: 'Flutter Demo',
      theme: theme.data(context),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Gtk + Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          GtkHeaderBar.bitsdojo(
            appWindow: appWindow,
            leading: GtkHeaderButton(
              icon: const AdwaitaIcon(AdwaitaIcons.list_add),
              onPressed: _incrementCounter,
            ),
            center: Text(
              "Gtk ❤️ Flutter",
              style:
                  Theme.of(context).textTheme.headline6!.copyWith(fontSize: 17),
            ),
            trailling: Row(
              children: [
                GtkPopupMenu(
                  body: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _counter = 0;
                            Navigator.of(context).pop();
                          });
                        },
                        title: const Text(
                          'Reset Counter',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onClose: appWindow.close,
            onMinimize: appWindow.minimize,
            onMaximize: appWindow.maximizeOrRestore,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'You have pushed the add button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'SearchScreen.dart';
import 'ProfileScreen.dart';
import 'HomeScreen.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Login'),
    );
  }
}



class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

bool checkIsLoggedIn() {
  return true;
}

bool checkClientID(clientId) {
  if (clientId.toString().length <= 0)
    return false;
  return true;
}

class _MyHomePageState extends State<MyHomePage> {

  bool isLoggedIn = false;

  final String clientId = "cbd78472f1ac9e8";
  final String responseType = "token";
  final webViewPlugin = new FlutterWebviewPlugin();
  int _currentIndex = 1;
  String accessToken = "";
  List<Widget> children;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  @override
  void initState() {
    super.initState();

    webViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      var uri = Uri.parse(state.url.replaceFirst('#', '?'));
      if (uri.query.contains('access_token')) {
        webViewPlugin.close();
        uri.queryParameters.forEach((k, v) {
          if (k == "access_token") {
            setState(() {
              children = [
                Search(),
                HomePage(),
                Profile(),
              ];
              SharedPreferences.getInstance().then((SharedPreferences prefs) {
                prefs.setString(
                    'user_access_token', uri.queryParameters["access_token"]);
                prefs.setString(
                    'user_refresh_token', uri.queryParameters["refresh_token"]);
                prefs.setString('user_account_name',
                    uri.queryParameters["account_username"]);
                prefs.setString('account_id', clientId);
              });
              this.accessToken = v.toString();
              this.isLoggedIn = true;
            });
          }
        });
      } else
        this.isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.isLoggedIn == false) {
      return Scaffold(
          body: WebviewScaffold(
            url: "https://api.imgur.com/oauth2/authorize?client_id=" + clientId +
              "&response_type=" + responseType,
          ),
          appBar:  AppBar(
              title: Center(child: Text('Epicture')),
          ),
      );
    } else {
      return (Scaffold(
        appBar: AppBar(
          title: Row(  mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Epicture'), GestureDetector(
                  onTap: () {
                    SharedPreferences.getInstance().then((SharedPreferences prefs) {
                      prefs.remove('user_access_token');
                      prefs.remove('user_refresh_token');
                      prefs.remove('user_account_name');
                      prefs.remove('account_id');
                    });
                    setState(() {
                      this.isLoggedIn = !this.isLoggedIn;
                      this.accessToken = "";
                    });
                  },
                  child: Icon(Icons.exit_to_app, color: Colors.red)),]),
        ),
        body: children[_currentIndex],
        floatingActionButton: FloatingActionButton(
          onPressed:(){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecondRoute()),
            );
          },
          child: Icon(Icons.add),
          tooltip: 'Increment',
        ),

        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.search),
              title: new Text('Search'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.home),
              title: new Text('Home'),
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), title: Text('Profile'))
          ],
        ),
      ));
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gfw2masq/Gfw2Pac.dart';
import 'package:gfw2masq/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(title: Text("gfwlist tools"),),
      body: Center(child: Column(
        children: <Widget>[
            RaisedButton(child: Text("2Dnsmasq"),onPressed: ()=> Navigator.push(context,MaterialPageRoute(builder: (context)=>Gfw2masq()))), 
            RaisedButton(child: Text("2Pac"),onPressed: ()=> Navigator.push(context,MaterialPageRoute(builder: (context)=>Gfw2Pac()))), 
        ], 
      ),), 
    );
  }
}

class Gfw2masq extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("build _VsTtPage");
    return MultiProvider(providers: [
      ChangeNotifierProvider.value(value:Gfw2masqVM()),
    ], child: _PageBody());
  }
}

class _PageBody extends StatelessWidget {
  final ipPartern =
      r"^((2(5[0-5]|[0-4]\d))|[0-1]?\d{1,2})(\.((2(5[0-5]|[0-4]\d))|[0-1]?\d{1,2})){3}$";
      final ipsetPatern = r"^[a-z]{3-10}$";
  @override
  Widget build(BuildContext context) {
    print("build _pageBody");
                    RegExp ipRegExp= new RegExp(ipPartern);
                    RegExp ipsetRegExp= new RegExp(ipsetPatern);
    return Scaffold(
      appBar: AppBar(
        title: Text("GfwList 2 dnsmasq"),
      ),
      body: SingleChildScrollView(
        child: Consumer<Gfw2masqVM>(builder: (ctx, vm, child) {
          return Column(children: [
            Form(
                child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "server port",
                    hintText: "127.0.0.1@5353",
                  ),
                  initialValue: "127.0.0.1@5353",
                  validator: (value) {
                    vm.DNSServer = null;
                    var length = 0;
                    if (value == null)
                      length = 0;
                    else{ 
                      value = value.trim();
                      length = value.length;
                    }
                    if (value.length < 10) {
                      return "长度不正确";
                    }
                    var strs = value.split("@");
                    if (strs.length != 2) {
                      return "格式不正确，请用@作ip和port的分割号";
                    }
                    var ipMatch = ipRegExp.hasMatch(strs[1]);
                    if (!ipMatch) {
                      return "ip格式不正确";
                    }
                    int port = int.parse(strs[2]);
                    if(port <= 0 || port > 65535){
                       return "端口号的范围是0到65535"; 
                    }
                    vm.DNSServer = value ;
                    return null;
                  },
                ),
                TextFormField(decoration:InputDecoration(labelText: "ipset Name",hintText: "ipset Name"),initialValue: "gfwlist", validator: (value){ 
                    var length = 0;
                    vm.ipsetName = null;
                    if (value == null)
                      length = 0;
                    else{ 
                      value = value.trim();
                      length = value.length;
                    }
                    if (length > 10 || length < 3) {
                      return "ipset Name长度应为3-10";
                    }

                    var ipMatch = ipsetRegExp.hasMatch(value);
                    if (!ipMatch) {
                      return "ipset应当全小写字母"; 
                      }
                      vm.ipsetName = value;
                   return null;

                },),
              ],
            )),
            Text("body text:${vm.downloadStr}"),
            Text("downloa progress:${vm.status}"),
            LinearProgressIndicator(
              value: vm.progress,
              backgroundColor: Colors.cyan,
            ),
            CircularProgressIndicator(
              value: vm.progress,
              backgroundColor: Colors.lightGreen,
            ),
            RefreshProgressIndicator(
              value: vm.progress,
              backgroundColor: Colors.white,
            )
          ]);
        }),
      ),
      floatingActionButton: Consumer<Gfw2masqVM>(
          builder: (ctx, vm, child) => FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  vm.download();
                },
              )),
    );
  }
}

class Gfw2masqVM with ChangeNotifier {
  var status = "ready";
  var statusBuilder = StringBuffer("Ready==");
  final SPLASH = "/";
  String PrefixServer = "server=";
  String DNSServer = "127.0.0.1#1053";
  String PrefixIpset = "ipset=";
  String ipsetName = "gfwlist";
  var downloadStr = "";
  var progress = 0.0;

  Future download() async {
    progress = 0.0;
    _appendLine("CheckPermission");
    var granted = await checkPermission(); 

    _appendLine(
        "PermssionStatus: ${granted ? 'Permission Granted' : 'permission Denied'}");
    _appendLine("parse success");
    var builder2 = StringBuffer();
    var gfwlistStr = await getGfwlist();
    var lines = gfwlistStr.split("\n");
    _appendLine("all count ${lines.length}");
    lines.forEach((line) {
      if (line.startsWith("||")) {
        line = line.replaceFirst("||", "");
        line = line.replaceAll("\n", "");
        builder2.writeln("$PrefixServer$SPLASH$line$SPLASH$DNSServer");
        builder2.writeln("$PrefixIpset$SPLASH$line$SPLASH$ipsetName");
      } else {
        // builder2.writeln(line);
      }
    });
    _appendLine("convert gfwlist success");
    // print(builder2.toString());
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = appDocDir.path;
    var fileName = "/gfwlist.conf";
    var file = File("$appDocPath$fileName");
    var exists = await file.exists();
    _appendLine("file exists $exists");
    if (exists) {
      await file.delete();
    }
    await file.create();
    await file.writeAsString(builder2.toString());
    _appendLine("write exists ${file.toString()}");
  }

  void _setStatus(String value) {
    this.status = value;
    notifyListeners();
  }

  void _appendLine(String value) {
    statusBuilder.writeln(value);
    _setStatus(statusBuilder.toString());
  }
}

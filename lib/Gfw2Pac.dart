import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gfw2masq/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class Gfw2Pac extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("build _VsTtPage");
    return MultiProvider(providers: [
      ChangeNotifierProvider.value(value:Gfw2masqVM()),
    ], child: _PacBody());
  }
}

class _PacBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GfwList 2 dnsmasq"),
      ),
      body: SingleChildScrollView(
        child: Consumer<Gfw2masqVM>(builder: (ctx, vm, child) {
          return Column(children: [
            Text("downloa progress:${vm.status}"),
            LinearProgressIndicator(
              value: vm.progress,
              backgroundColor: Colors.cyan,
            ),
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
  var quotation  = r'"';
  var comma = ",";
  var progress = 0.0;
  var firstLine = r'''var proxy = "PROXY 127.0.0.1:8001; SOCKS5 127.0.0.1:1081; SOCKS 127.0.0.1:1081; DIRECT";

var domains = [  
  ''';


  var proxyFunc = r'''];
 
 function FindProxyForURL(url, host) {
    for (var i = domains.length - 1; i >= 0; i--) {
    	if (dnsDomainIs(host, domains[i])) {
            return proxy;
    	}
    }
    return "DIRECT";
}''';

  Future download() async {
    progress = 0.0;
    _appendLine("CheckPermission");
    var granted = await checkPermission(); 
    _appendLine( "PermssionStatus: ${granted ? 'Permission Granted' : 'permission Denied'}");
    _appendLine("parse success");
    var builder2 = StringBuffer();
    var gfwlistStr = null;
    try{

     gfwlistStr = await getGfwlist();
     print("donwload list success");
    }catch(e){
     print("donwload list failed");
     print("${e.toString()}");
      _appendLine(e.toString());
      _appendLine("failed");
      return;
    }
    var lines = gfwlistStr.split("\n");
    _appendLine("all count ${lines.length}");
    builder2.writeln(firstLine);
    lines.forEach((line) {
      if (line.startsWith("||")) {
        line = line.replaceFirst("||", "");
        line = line.replaceAll("\n", "");
        builder2.writeln("$quotation$line$quotation$comma");
      } else {
        // builder2.writeln(line);
      }
    });
    builder2.writeln(proxyFunc);
    _appendLine("convert gfwlist success");
    // print(builder2.toString());
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = appDocDir.path;
    var fileName = "/gfwlist.pac";
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
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> getGfwlist() async {
  var dio = Dio();
  Response<String> response = await dio.get<String>(
      "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt",
      onReceiveProgress: downloadProgress);
  if (response.statusCode != 200) {
    return "";
  }
  var valueStr = StringBuffer();
  response.headers.forEach((key, values) {
    valueStr.clear();
    values.forEach((item) => valueStr.write(item));
    print("$key = ${valueStr.toString()}");
  });

  var httpResult = response.data;
  httpResult = httpResult.replaceAll("\n", "");
  var decoded = base64.decode(httpResult);
  var resultStr = utf8.decode(decoded);
  return resultStr;
}

void downloadProgress(int count, int total) {
  var progress = count / total;
  var downloadStr =
      "$count/$total ===== ${(progress * 100).toStringAsFixed(1)}%";
  print(downloadStr + "\n");
}

Future<bool> checkPermission() async {
  PermissionStatus permission =
      await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
  var granted = permission.value == PermissionStatus.granted.value;
  if (granted) {
    return granted;
  }

  Map<PermissionGroup, PermissionStatus> permission2 =
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  var denied = StringBuffer();
  permission2.forEach((PermissionGroup key, PermissionStatus value) {
    print("permssion ${key.toString()}");
    if (key.value == PermissionGroup.storage.value) {
      var granted = (value.value == PermissionStatus.granted.value); 
    print("granted ${granted}");
      if (!granted) {
        denied.write("${key.toString()}  === ${value.toString()}");
      }
    }
  });
  print(denied);
  return granted;
}

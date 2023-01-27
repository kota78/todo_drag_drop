import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_drag_drop/api/rest_client.dart';
import 'package:todo_drag_drop/models/task.dart';

class Client {
  static final clientID = dotenv.env['CLIENT_ID'] ?? "";
  static final clientSecret = dotenv.env['CLIENT_SECRET'] ?? "";
  static const keyAccessToken = 'ticktick/accessToken';

  static Future<String> createAccessTokenFromCallbackUri(
      Uri uri, String expectedState) async {
    final String? state = uri.queryParameters['state'];
    final String? code = uri.queryParameters['code'];
    debugPrint("state:$state\ncode:$code");
    if (expectedState != state) {
      throw Exception('the state is different from expectedState');
    }

    final response = await http.post(
      Uri(
        scheme: 'https',
        host: 'dida365.com',
        path: '/oauth/token',
        queryParameters: {
          'client_id': clientID,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'scope': 'tasks:read',
          'redirect_uri': 'https://www.google.com/',
        },
      ),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    debugPrint("responseBody: ${response.body}");
    final body = jsonDecode(response.body);
    final accessToken = body['access_token'];
    return accessToken;
  }

  static Future<void> saveAccessToken(String accessToken) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAccessToken, accessToken);
  }

  static Future<String?> getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAccessToken);
  }

  static Future<void> deleteAccessToken() async {
    final accessToken = await getAccessToken();
    String url = "https://qiita.com/api/v2/access_tokens/$accessToken";
    final response = await http.delete(Uri.parse(url));
    debugPrint(response.statusCode.toString());
    if (response.statusCode == 204) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove(keyAccessToken);
    } else {
      throw Exception('Failed to delete');
    }
  }

  static Future<bool> accessTokenIsSaved() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  static Future<Task> fetchTask(String accessToken) async {
    debugPrint(accessToken);
    final dio = Dio();
    dio.options.headers["Authorization"] = "Bearer  $accessToken";
    final client = RestClient(dio);
    final data = await client.getTask();
    debugPrint(
        "[title]${data.title}\n[content]${data.content}\n[desc]${data.desc}");
    return data;
  }

  static Future<Task> createTask(String accessToken) async {
    debugPrint(accessToken);
    final dio = Dio();
    dio.options.headers["Authorization"] = "Bearer  $accessToken";
    final client = RestClient(dio);
    final data = await client
        .createTask(Task(title: "title", content: "content", desc: "desc"));
    debugPrint(
        "[title]${data.title}\n[content]${data.content}\n[desc]${data.desc}");
    return data;
  }
}

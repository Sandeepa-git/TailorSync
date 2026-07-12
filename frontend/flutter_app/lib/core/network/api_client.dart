import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  String? _accessToken;
  void Function()? onUnauthorized;

  ApiClient(this.dio);

  static ApiClient create(String baseUrl) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    final client = ApiClient(dio);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (client._accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${client._accessToken}';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          final path = e.requestOptions.path;
          if (!path.contains('/auth/login') && !path.contains('/auth/signup')) {
            client.onUnauthorized?.call();
          }
        }
        return handler.next(e);
      },
    ));
    return client;
  }

  void setToken(String token) {
    _accessToken = token;
  }

  void clearToken() {
    _accessToken = null;
  }

  // User Profile
  Future<Response> getMe() async {
    return dio.get('/users/me');
  }

  Future<Response> updateProfile(Map<String, dynamic> payload) async {
    return dio.put('/users/me', data: payload);
  }

  // Business Profile
  Future<Response> getBusiness() async {
    return dio.get('/business/me');
  }

  Future<Response> updateBusiness(Map<String, dynamic> payload) async {
    return dio.put('/business/me', data: payload);
  }

  // Staff Management
  Future<Response> listStaff() async {
    return dio.get('/staff/');
  }

  Future<Response> createStaff(Map<String, dynamic> payload) async {
    return dio.post('/staff/', data: payload);
  }

  Future<Response> deactivateStaff(int id) async {
    return dio.delete('/staff/$id');
  }

  // Authentication
  Future<Response> login(String email, String password) async {
    return dio.post('/auth/login', data: {'email': email, 'password': password});
  }

  Future<Response> signup(String email, String password, String name, String phone) async {
    return dio.post('/auth/signup', data: {'email': email, 'password': password, 'full_name': name, 'phone': phone});
  }

  Future<Response> googleLogin(String firebaseToken) async {
    return dio.post('/auth/google', data: {'firebase_token': firebaseToken});
  }

  Future<Response> refreshToken(String refreshToken) async {
    return dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
  }

  // Customers
  Future<Response> listCustomers({Map<String, dynamic>? params}) async {
    return dio.get('/customers/', queryParameters: params);
  }

  Future<Response> createCustomer(Map<String, dynamic> payload) async {
    return dio.post('/customers/', data: payload);
  }

  Future<Response> updateCustomer(int id, Map<String, dynamic> payload) async {
    return dio.put('/customers/$id', data: payload);
  }

  Future<Response> deleteCustomer(int id) async {
    return dio.delete('/customers/$id');
  }

  // Orders
  Future<Response> listOrders({Map<String, dynamic>? params}) async {
    return dio.get('/orders/', queryParameters: params);
  }

  Future<Response> createOrder(Map<String, dynamic> payload) async {
    return dio.post('/orders/', data: payload);
  }

  Future<Response> getOrder(int id) async {
    return dio.get('/orders/$id');
  }

  Future<Response> updateOrder(int id, Map<String, dynamic> payload) async {
    return dio.put('/orders/$id', data: payload);
  }

  Future<Response> deleteOrder(int id) async {
    return dio.delete('/orders/$id');
  }

  Future<Response> getOrderStats() async {
    return dio.get('/orders/stats');
  }

  // AI
  Future<Response> estimateFabric(Map<String, dynamic> payload) async {
    return dio.post('/ai/estimate-fabric', data: payload);
  }

  Future<Response> recommendFabric(Map<String, dynamic> payload) async {
    return dio.post('/ai/recommend-fabric', data: payload);
  }

  Future<Response> predictMeasurements(Map<String, dynamic> payload) async {
    return dio.post('/ai/predict-measurements', data: payload);
  }

  // Measurement Templates
  Future<Response> getMeasurementTemplates() async {
    return dio.get('/measurement-templates/');
  }

  Future<Response> getMeasurementTemplateByCategory(String categoryName) async {
    return dio.get('/measurement-templates/$categoryName');
  }

  Future<Response> createMeasurementTemplate(Map<String, dynamic> payload) async {
    return dio.post('/measurement-templates/', data: payload);
  }

  Future<Response> updateMeasurementTemplate(int id, Map<String, dynamic> payload) async {
    return dio.put('/measurement-templates/$id', data: payload);
  }

  Future<Response> deleteMeasurementTemplate(int id) async {
    return dio.delete('/measurement-templates/$id');
  }
}

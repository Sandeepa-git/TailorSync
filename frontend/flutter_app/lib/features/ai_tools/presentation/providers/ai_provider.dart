import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/api_client.dart';

final aiProvider = Provider((ref) {
	final api = ApiClient.create('http://10.18.157.15:8000/api/v1');
	return api;
});

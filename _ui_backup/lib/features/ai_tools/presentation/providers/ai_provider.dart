import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/providers/api_provider.dart';

final aiProvider = Provider((ref) {
	return ref.watch(apiClientProvider);
});

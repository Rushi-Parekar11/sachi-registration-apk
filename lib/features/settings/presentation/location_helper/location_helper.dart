import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

Future<List<Map<String, String?>>> getPlacemarks(Position position) async {
  try {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
    final response = await http.get(url, headers: {
      'User-Agent': 'SachiRegistrationApp/1.0',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['address'] != null) {
        final address = data['address'];
        return [
          {
            'country': address['country'],
            'administrativeArea': address['state'] ?? address['county'],
            'locality': address['city'] ?? address['town'] ?? address['village'],
            'postalCode': address['postcode'],
          }
        ];
      }
    }
    return [];
  } catch (e) {
    return [];
  }
}

import 'package:country_state_city/country_state_city.dart';

void main() async {
  final countries = await getAllCountries();
  print(countries.length);
  
  final india = countries.firstWhere((c) => c.name == 'India');
  final states = await getStatesOfCountry(india.isoCode);
  print(states.length);
  
  final maharashtra = states.firstWhere((s) => s.name == 'Maharashtra');
  final cities = await getStateCities(india.isoCode, maharashtra.isoCode);
  print(cities.length);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:radha_mobile/core/network/dto/product_lookup_dto.dart';

void main() {
  group('ProductLookupResult', () {
    test(
      'parses server nutrition contract with allergen list and processing level',
      () {
        final result = ProductLookupResult.fromJson({
          'found': true,
          'source': 'open-food-facts',
          'product': {
            'id': 'product-1',
            'ean': '8901262010016',
            'name': 'Amul Pasteurized Butter',
            'brand': 'Amul',
            'nutrition': {
              'servingSize': '100.00',
              'servingUnit': 'g',
              'calories': '720.00',
              'fat': '80.00',
              'sodium': '650.00',
              'containsAllergens': ['milk'],
              'isProcessed': 'ultra',
            },
          },
        });

        final nutrition = result.product!.nutrition!;
        expect(result.found, isTrue);
        expect(result.product!.name, 'Amul Pasteurized Butter');
        expect(nutrition.containsAllergens, ['milk']);
        expect(nutrition.hasAllergenSignal, isTrue);
        expect(nutrition.isUltraProcessed, isTrue);
        expect(nutrition.calories, 720);
      },
    );

    test(
      'keeps empty allergen arrays distinct from unavailable allergen data',
      () {
        final empty = ProductNutrition.fromJson({'containsAllergens': []});
        final absent = ProductNutrition.fromJson({});

        expect(empty.hasAllergenSignal, isFalse);
        expect(absent.hasAllergenSignal, isNull);
      },
    );
  });
}

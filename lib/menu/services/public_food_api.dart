import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';

class PublicFoodApi {
  static const _mealDbBase = 'https://www.themealdb.com/api/json/v1/1';
  static const _cocktailDbBase = 'https://www.thecocktaildb.com/api/json/v1/1';
  
  final _random = Random();

  /// Fetches a mix of random meals to simulate food menu
  Future<List<MenuItem>> fetchRandomMeals({int targetCount = 10}) async {
    final List<MenuItem> items = [];
    
    try {
      // TheMealDB free tier only returns 1 random meal at a time over /random.php
      // To get multiple fast, we search by a common letter like 'b' or 'c' which returns an array.
      final letters = ['b', 'c', 'p', 's', 'm'];
      final char = letters[_random.nextInt(letters.length)];
      
      final url = Uri.parse('$_mealDbBase/search.php?f=$char');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List<dynamic>? ?? [];
        
        for (var i = 0; i < min(meals.length, targetCount); i++) {
          final meal = meals[i];
          items.add(_mapToMenuItem(
            id: 'meal_${meal['idMeal']}',
            name: meal['strMeal'] ?? 'Plat inconnu',
            description: _generateDescription(meal['strMeal'] ?? ''),
            imageUrl: meal['strMealThumb'] ?? '',
            category: MenuCategory.food,
          ));
        }
      }
    } catch (e) {
      print('Error fetching meals: $e');
    }
    
    return items;
  }

  /// Fetches a mix of random drinks to simulate beverage menu
  Future<List<MenuItem>> fetchRandomDrinks({int targetCount = 10}) async {
    final List<MenuItem> items = [];
    
    try {
      // Fetch Non-Alcoholic drinks
      final url = Uri.parse('$_cocktailDbBase/filter.php?a=Non_Alcoholic');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drinks = data['drinks'] as List<dynamic>? ?? [];
        
        // Shuffle to get varied drinks
        drinks.shuffle(_random);
        
        for (var i = 0; i < min(drinks.length, targetCount); i++) {
          final drink = drinks[i];
          items.add(_mapToMenuItem(
            id: 'drink_${drink['idDrink']}',
            name: drink['strDrink'] ?? 'Boisson inconnue',
            description: 'Boisson rafraîchissante préparée sur place.',
            imageUrl: drink['strDrinkThumb'] ?? '',
            category: MenuCategory.drink,
          ));
        }
      }
    } catch (e) {
      print('Error fetching drinks: $e');
    }
    
    return items;
  }
  
  /// Searches for meals directly by a search string
  Future<List<MenuItem>> searchMeals(String query) async {
    final List<MenuItem> items = [];
    if (query.isEmpty) return items;
    
    try {
      final url = Uri.parse('$_mealDbBase/search.php?s=${Uri.encodeComponent(query)}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List<dynamic>? ?? [];
        
        for (final meal in meals) {
          items.add(_mapToMenuItem(
            id: 'meal_${meal['idMeal']}',
            name: meal['strMeal'] ?? '',
            description: _generateDescription(meal['strMeal'] ?? ''),
            imageUrl: meal['strMealThumb'] ?? '',
            category: MenuCategory.food,
          ));
        }
      }
    } catch (e) {
      print('Error searching meals: $e');
    }
    return items;
  }
  
  /// Searches for drinks by a string
  Future<List<MenuItem>> searchDrinks(String query) async {
    final List<MenuItem> items = [];
    if (query.isEmpty) return items;
    
    try {
      final url = Uri.parse('$_cocktailDbBase/search.php?s=${Uri.encodeComponent(query)}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drinks = data['drinks'] as List<dynamic>? ?? [];
        
        for (final drink in drinks) {
          items.add(_mapToMenuItem(
            id: 'drink_${drink['idDrink']}',
            name: drink['strDrink'] ?? '',
            description: 'Boisson fraîche.',
            imageUrl: drink['strDrinkThumb'] ?? '',
            category: MenuCategory.drink,
          ));
        }
      }
    } catch (e) {
      print('Error searching drinks: $e');
    }
    return items;
  }
  
  MenuItem _mapToMenuItem({
    required String id,
    required String name,
    required String description,
    required String imageUrl,
    required MenuCategory category,
  }) {
    // Generate random realistic prices for FCFA (e.g. 1500 to 8000)
    // Round to nearest 500
    final basePrice = category == MenuCategory.food 
        ? _random.nextInt(10) * 500 + 2500 
        : _random.nextInt(4) * 500 + 1000;
        
    final quantity = _random.nextInt(30);
    MenuStockStatus status = MenuStockStatus.normal;
    if (quantity == 0) {
      status = MenuStockStatus.outOfStock;
    } else if (quantity < 5) {
      status = MenuStockStatus.low;
    }
    
    return MenuItem(
      id: id,
      name: name,
      description: description,
      price: basePrice.toDouble(),
      imageUrl: imageUrl,
      category: category,
      quantityRemaining: quantity,
      status: status,
      lastUpdated: DateTime.now().subtract(Duration(minutes: _random.nextInt(120))),
    );
  }
  
  String _generateDescription(String name) {
    final descriptions = [
      'Notre spécialité maison préparée avec des ingrédients frais.',
      'Un classique revisité par notre chef.',
      'Parfait pour une petite faim ou à partager.',
      'Savoureux et généreux, accompagné de ses garnitures.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }
}

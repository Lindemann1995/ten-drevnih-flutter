import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart';

class CraftScreen extends StatefulWidget {
  final String npcSlug;
  final String npcName;

  const CraftScreen({super.key, required this.npcSlug, required this.npcName});

  @override
  State<CraftScreen> createState() => _CraftScreenState();
}

class _CraftScreenState extends State<CraftScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  
  List<dynamic> _myRecipes = [];
  List<dynamic> _myScrolls = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    
    final recipesResult = await ApiClient.getNpcRecipes(widget.npcSlug);
    final scrollsResult = await ApiClient.getPlayerScrolls();
    
    if (!mounted) return;
    
    if (recipesResult['success'] == true) {
      setState(() {
        _myRecipes = recipesResult['data']['recipes'] ?? [];
        if (scrollsResult['success'] == true) {
          _myScrolls = scrollsResult['data']['scrolls'] ?? [];
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = recipesResult['error'] ?? 'Ошибка загрузки';
        _isLoading = false;
      });
    }
  }

  Future<void> _learnScroll(String scrollSlug) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
    );

    final result = await ApiClient.learnRecipe(scrollSlug);
    
    if (!mounted) return;
    Navigator.pop(context);

    if (result['success'] == true) {
      _showMessage('Рецепт изучен!');
      _loadData();
    } else {
      _showMessage(result['error'] ?? 'Ошибка изучения');
    }
  }

  Future<void> _craft(int recipeId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
    );

    final result = await ApiClient.craftItem(recipeId);
    
    if (!mounted) return;
    Navigator.pop(context);

    if (result['success'] == true) {
      _showSuccessAnimation(result['data']['item']);
      _loadData();
    } else {
      _showMessage(result['error'] ?? 'Ошибка крафта');
    }
  }

  void _showSuccessAnimation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨ УСПЕХ! ✨', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Image.asset(
                      AssetPaths.forItem(item['image_path'], item['slug']),
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Color(0xFFD4AF37), size: 60),
                    ),
                    const SizedBox(height: 16),
                    Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 8),
                    // 🆕 ПРИПИСКА О ТОМ, ЧТО РЕЦЕПТ ИЗРАСХОДОВАН
                    const Text(
                      '(Рецепт израсходован)',
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: const Color(0xFF1A0A0A)),
                      child: const Text('ОТЛИЧНО'),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B0000)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('Кузница: ${widget.npcName}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A0A0A),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'МОИ РЕЦЕПТЫ', icon: Icon(Icons.handyman)),
            Tab(text: 'ИЗУЧИТЬ', icon: Icon(Icons.auto_stories)),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecipesList(),
                    _buildScrollsList(),
                  ],
                ),
    );
  }

  Widget _buildRecipesList() {
    if (_myRecipes.isEmpty) {
      return const Center(child: Text('У вас пока нет изученных рецептов', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _myRecipes[index];
        final resultItem = recipe['result_item'];
        
        bool canCraft = true;
        for (var ing in recipe['ingredients']) {
          if (ing['has'] < ing['required']) {
            canCraft = false;
            break;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: const Color(0xFF3A1A1A), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                    child: Image.asset(
                      AssetPaths.forItem(resultItem['image_path'], resultItem['slug']),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.white30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resultItem['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(recipe['name'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF3A1A1A), height: 20),
              const Text('Требуемые ресурсы:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recipe['ingredients'].map<Widget>((ing) {
                  final hasEnough = ing['has'] >= ing['required'];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasEnough ? const Color(0xFF1A2A1A) : const Color(0xFF2A1A1A),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: hasEnough ? const Color(0xFF4A8B4A) : const Color(0xFF8B0000)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AssetPaths.forItem(ing['image_path'], ing['slug']),
                          width: 20, height: 20,
                          errorBuilder: (_, __, ___) => const Icon(Icons.help, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${ing['name']} ${ing['has']}/${ing['required']}',
                          style: TextStyle(color: hasEnough ? Colors.white : const Color(0xFFFF6B6B), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: canCraft ? () => _craft(recipe['id']) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canCraft ? const Color(0xFFD4AF37) : Colors.grey[800],
                    foregroundColor: canCraft ? const Color(0xFF1A0A0A) : Colors.white54,
                  ),
                  child: Text(canCraft ? 'СКРАФТИТЬ' : 'НЕ ХВАТАЕТ РЕСУРСОВ', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollsList() {
    if (_myScrolls.isEmpty) {
      return const Center(child: Text('У вас нет свитков для изучения', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myScrolls.length,
      itemBuilder: (context, index) {
        final scroll = _myScrolls[index];
        
        Color rarityColor = Colors.grey;
        if (scroll['rarity'] == 'uncommon') rarityColor = const Color(0xFF4A8B4A);
        if (scroll['rarity'] == 'rare') rarityColor = const Color(0xFF3A5A8B);
        if (scroll['rarity'] == 'epic') rarityColor = const Color(0xFF8B3A8B);
        if (scroll['rarity'] == 'legendary') rarityColor = const Color(0xFFD4AF37);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: rarityColor, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                child: Image.asset(
                  AssetPaths.forItem(scroll['image_path'], scroll['slug']),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.auto_stories, color: rarityColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scroll['name'], style: TextStyle(color: rarityColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(scroll['recipe_name'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('В наличии: ${scroll['quantity']} шт.', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: scroll['is_learned'] ? null : () => _learnScroll(scroll['slug']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scroll['is_learned'] ? Colors.grey[800] : const Color(0xFF2A8B2A),
                  foregroundColor: Colors.white,
                ),
                child: Text(scroll['is_learned'] ? 'ИЗУЧЕНО' : 'ИЗУЧИТЬ'),
              ),
            ],
          ),
        );
      },
    );
  }
}
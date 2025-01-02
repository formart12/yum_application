import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:yum_application/src/data/ingredient/model/basic_ingredient.dart';
import 'package:yum_application/src/data/ingredient/model/ingredient.dart';
import 'package:yum_application/src/data/ingredient/repository/ingredient_repository.dart';
import 'package:yum_application/src/util/global_variable.dart';

class IngredientViewModelImpl extends ChangeNotifier
    implements IngredientViewModel {
  final IngredientRepository ingredientRepository;
  List<Ingredient> _myIngredients = List.empty(growable: true);

  /// 나의 냉동 재료 getter
  @override
  List<Ingredient> get myFreezedIngredients {
    return _myIngredients
        .where((ingredient) => ingredient.isFreezed == true)
        .toList();
  }

  /// 나의 냉장 재료 getter
  @override
  List<Ingredient> get myUnfreezedIngredients {
    return _myIngredients
        .where((ingredient) => ingredient.isFreezed == false)
        .toList();
  }

  IngredientViewModelImpl({required this.ingredientRepository}) {
    fetchData();
  }

  Ingredient? _selectedIngredient;

  @override
  Ingredient? get selectedIngredient => _selectedIngredient;

  bool _isFreezed = false;
  bool get isFreezed => _isFreezed;

  @override
  Future<void> fetchData() async {
    try {
      final result = await ingredientRepository.getMyIngredient();
      _myIngredients.clear();
      _myIngredients = result;
      notifyListeners();
    } on Exception catch (e) {
      // 예를 들어, 에러상황에서는 토스트 메시지를 띄워서 사용자에게 알림을 보냄.
      throw Exception("재료 불러오기 에러");
    }
  }

  @override
  Future<void> createNewIngredient() async {
    // 선택한 재료가 없으면 return;
    if (_selectedIngredient == null) {
      return;
    }
    print(_selectedIngredient);
    try {
      // 선택한 재료를 타겟으로 설정
      final newIngredient = selectedIngredient!;
      final prevIngredients = _myIngredients;
      _myIngredients = [
        ...prevIngredients,
        newIngredient,
      ];
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final context = GlobalVariable.naviagatorState.currentContext!;
        Navigator.of(context).pop();
      });
      final result =
          await ingredientRepository.createNewIngredient(newIngredient);
      _myIngredients = [
        ...prevIngredients,
        result,
      ];
      // 선택 재료 초기화 및 화면 갱신
      cancel();
    } on Exception catch (e) {
      throw Exception("재료 생성 에러");
    }
  }

  @override
  Future<void> updateIngredient() async {
    // 선택한 재료가 없으면 return;
    if (_selectedIngredient == null) {
      return;
    }
    print(_selectedIngredient);
    try {
      // 선택한 재료를 타겟으로 설정
      final newIngredient = selectedIngredient;

      // Api를 통해 재료 수정
      final newupdatedIngredient =
          await ingredientRepository.updateIngredient(newIngredient!);

      // 기존 냉장고 재료 목록에서 해당 재료를 찾아 수정
      final index = _myIngredients
          .indexWhere((ingredient) => ingredient.id == newupdatedIngredient.id);
      if (index != -1) {
        _myIngredients[index] = newupdatedIngredient;
      }
      notifyListeners();
    } on Exception catch (e) {
      throw Exception("재료 수정 에러");
    }
  }

  @override
  void deleteIngredient(Ingredient ingredient) {
    _myIngredients = _myIngredients.where((i) => ingredient != i).toList();
    ingredientRepository.deleteIngredient(ingredient.id!);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final context = GlobalVariable.naviagatorState.currentContext!;
      Navigator.of(context).pop();
    });
    notifyListeners();
  }

  @override
  void selectIngredient(BasicIngredient ingredient) {
    final newIngredient = Ingredient(
        name: ingredient.name,
        category: ingredient.category,
        isFreezed: _isFreezed);
    _selectedIngredient = newIngredient;
    notifyListeners();
  }

  @override
  void cancel() {
    _selectedIngredient = null;
    notifyListeners();
  }

  @override
  void toggleIsFreezed(bool value) {
    _isFreezed = value;
    if (_selectedIngredient != null) {
      _selectedIngredient = _selectedIngredient!.copy(isFreezed: _isFreezed);
    }
    notifyListeners();
  }

  @override
  void updateStartAt(DateTime newStartAt) {
    if (_selectedIngredient == null) return;
    _selectedIngredient = _selectedIngredient!.copy(startAt: newStartAt);
    notifyListeners();
  }

  @override
  void updateEndAt(DateTime newEndAt) {
    if (_selectedIngredient == null) return;
    _selectedIngredient = _selectedIngredient!.copy(endAt: newEndAt);
    notifyListeners();
  }
}

abstract class IngredientViewModel {
  List<Ingredient> get myFreezedIngredients;

  List<Ingredient> get myUnfreezedIngredients;

  Ingredient? get selectedIngredient;

  Future<void> fetchData();

  void createNewIngredient();

  void updateIngredient();

  void deleteIngredient(Ingredient ingredient);

  void selectIngredient(BasicIngredient ingredient);

  void cancel();

  void toggleIsFreezed(bool value);

  void updateStartAt(DateTime startAt);

  void updateEndAt(DateTime endAt);
}

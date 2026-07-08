---
name: jsonny
description: Convert Postman API response + endpoint details into production-ready Flutter/Dart feature code following the sixvalley create_auction Clean Architecture pattern. Use when the user wants to generate a new feature from an API endpoint.
argument-hint: [feature_name]
allowed-tools: Read, Write, Edit, Bash
---

# jsonny — Flutter Feature Code Generator

You are a Flutter code generation assistant for the `flutter_sixvalley_ecommerce` project. When invoked, collect all necessary information, then generate all files for a complete feature layer, strictly following the patterns found in `lib/features/create_auction/`.

---

## STEP 1 — Collect Inputs

If `$ARGUMENTS` is non-empty, use it as the feature name (skip asking for it).

Ask the user for all of the following in one message:

1. **Feature name** — snake_case, e.g. `product_review`. This becomes the directory name and class prefix.
2. **API endpoint path** — just the path, e.g. `/api/v1/customer/reviews`. Will be added to `AppConstants`.
3. **HTTP method** — `GET`, `POST`, `PUT`, or `DELETE`.
4. **Request parameters** — for GET: query params with types and required/optional; for POST: body fields with types and required/optional.
5. **Response JSON** — paste the full Postman response JSON.
6. **Requires auth?** — yes or no. If yes, repository will use `_setRequestHeaders`.
7. **Controller needed?** — yes or no.

---

## STEP 2 — Derive Names and Types

From `feature_name` (snake_case) derive:

- **ClassName** = PascalCase of feature_name (e.g. `product_review` → `ProductReview`)
- **AppConstants key** = camelCase of feature_name + `Uri` suffix (e.g. `productReviewUri`)
- **File names** = snake_case matching feature_name for every file

From the **response JSON**, infer Dart field types:
- JSON string → `String?`
- JSON integer → `int?`
- JSON float → `double?`
- JSON boolean → `bool?`
- JSON array of objects → `List<SubClassName>?` (generate a sub-class in the same file)
- JSON null → `String?` (most permissive default)
- **Numeric-as-string** (e.g. `"total_size": "12"`) → parse with `int.tryParse('${json["total_size"]}')`

For **paginated list responses** (fields like `total_size`, `limit`, `offset` + a data array), generate TWO model classes: a wrapper (e.g. `ProductReviewListModel`) and a child (e.g. `ProductReviewModel`).

---

## STEP 3 — Generate All Files

Use the Write tool to create each file. Show the target path before each file.

### Directory layout to create:
```
lib/features/{feature_name}/
├── controllers/
│   └── {feature_name}_controller.dart
├── domain/
│   ├── models/
│   │   └── {feature_name}_model.dart
│   ├── repository/
│   │   ├── {feature_name}_repository_interface.dart
│   │   └── {feature_name}_repository.dart
│   └── services/
│       ├── {feature_name}_service_interface.dart
│       └── {feature_name}_service.dart
├── screens/
└── widgets/
```

---

### FILE 1: Model — `domain/models/{feature_name}_model.dart`

**Rules:**
- All fields nullable with `?`.
- Response models (GET): generate `fromJson` factory constructor and `toJson`.
- Request-only models (POST body builder): plain constructor only, no `fromJson`.
- Paginated responses: wrapper class + child class in the same file.
- Sub-objects: define as separate classes in the same file.
- Numeric-as-string fields use `int.tryParse('${json["key"]}')`.
- Array fields: null-guard + `List.from(json['key'].map(...))`.

**Template — single response object:**
```dart
class {ClassName}Model {
  String? fieldOne;
  int? fieldTwo;
  double? fieldThree;
  bool? fieldFour;
  List<{SubClassName}>? items;

  {ClassName}Model({
    this.fieldOne,
    this.fieldTwo,
    this.fieldThree,
    this.fieldFour,
    this.items,
  });

  factory {ClassName}Model.fromJson(Map<String, dynamic> json) {
    return {ClassName}Model(
      fieldOne: json['field_one'],
      fieldTwo: int.tryParse('${json['field_two']}'),
      fieldThree: json['field_three'] != null ? double.tryParse('${json['field_three']}') : null,
      fieldFour: json['field_four'] == true || json['field_four'] == 1,
      items: json['items'] != null
          ? List<{SubClassName}>.from(json['items'].map((e) => {SubClassName}.fromJson(e)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field_one': fieldOne,
      'field_two': fieldTwo,
      'field_three': fieldThree,
      'field_four': fieldFour,
    };
  }
}
```

**Template — paginated list wrapper:**
```dart
class {ClassName}ListModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<{ClassName}Model>? data;

  {ClassName}ListModel({this.totalSize, this.limit, this.offset, this.data});

  factory {ClassName}ListModel.fromJson(Map<String, dynamic> json) {
    return {ClassName}ListModel(
      totalSize: int.tryParse('${json['total_size']}'),
      limit: int.tryParse('${json['limit']}'),
      offset: int.tryParse('${json['offset']}'),
      data: json['data'] != null
          ? List<{ClassName}Model>.from(json['data'].map((e) => {ClassName}Model.fromJson(e)))
          : null,
    );
  }
}
```

---

### FILE 2: Repository Interface — `domain/repository/{feature_name}_repository_interface.dart`

**Rules:**
- Always `implements RepositoryInterface` (from `lib/interface/repo_interface.dart`).
- Declare only the feature-specific methods. Do NOT re-declare the 5 base methods.
- Method names: `get{ClassName}`, `get{ClassName}List`, `create{ClassName}`, `update{ClassName}`, `delete{ClassName}`.
- Return type: always `Future<ApiResponseModel>`.
- Named parameters with `required` for mandatory fields. Nullable type for optional.
- Never accept a raw `Map<String, dynamic>` as a parameter.

**Template:**
```dart
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class {ClassName}RepositoryInterface implements RepositoryInterface {
  Future<ApiResponseModel> get{ClassName}List({
    required int offset,
    int limit = 10,
  });

  // or for POST:
  Future<ApiResponseModel> create{ClassName}({
    required String param1,
    int? param2,
  });
}
```

---

### FILE 3: Repository Implementation — `domain/repository/{feature_name}_repository.dart`

**Rules:**
- `DioClient?` field, accessed with `!` throughout (e.g. `dioClient!.get(...)`).
- If auth=yes: include `_setRequestHeaders(String? token)` — sets BOTH `Authorization: Bearer ...` AND `AppConstants.langKey` headers.
- GET requests: `dioClient!.get(AppConstants.{key}Uri, queryParameters: {...})`.
- POST requests: build local `fields` map, then `dioClient!.post(AppConstants.{key}Uri, data: fields)`.
- Multipart POST: build `List<MultipartWithKey>` and use `dioClient!.postMultipart(...)`.
- Always wrap in try/catch → `ApiResponseModel.withSuccess(response)` / `ApiResponseModel.withError(ApiErrorHandler.getMessage(e))`.
- All 5 base `RepositoryInterface` methods MUST be overridden with `throw UnimplementedError()`.
- Import `main.dart` for `Get.context!` — do NOT import the `get` package.

**Template — authenticated GET list:**
```dart
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/{feature_name}/domain/repository/{feature_name}_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

class {ClassName}Repository implements {ClassName}RepositoryInterface {
  final DioClient? dioClient;
  {ClassName}Repository({required this.dioClient});

  void _setRequestHeaders(String? token) {
    final String? countryCode = dioClient!.countryCode;
    final String langValue =
        (countryCode == null || countryCode == 'US') ? 'en' : countryCode.toLowerCase();
    dioClient!.dio!.options.headers = {
      'Authorization':
          'Bearer ${token ?? Provider.of<AuthController>(Get.context!, listen: false).getUserToken()}',
      AppConstants.langKey: langValue,
    };
  }

  @override
  Future<ApiResponseModel> get{ClassName}List({
    required int offset,
    int limit = 10,
  }) async {
    final String? token =
        Provider.of<AuthController>(Get.context!, listen: false).getUserToken();
    _setRequestHeaders(token);
    try {
      final response = await dioClient!.get(
        AppConstants.{featureNameCamel}Uri,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override Future add(value) => throw UnimplementedError();
  @override Future delete(int id) => throw UnimplementedError();
  @override Future get(String id) => throw UnimplementedError();
  @override Future getList({int? offset = 1}) => throw UnimplementedError();
  @override Future update(Map<String, dynamic> body, int id) => throw UnimplementedError();
}
```

**Additional template — POST method body (insert inside class):**
```dart
  @override
  Future<ApiResponseModel> create{ClassName}({
    required String param1,
    int? param2,
  }) async {
    final String? token =
        Provider.of<AuthController>(Get.context!, listen: false).getUserToken();
    _setRequestHeaders(token);
    try {
      final Map<String, dynamic> fields = {};
      fields['param_1'] = param1;
      if (param2 != null) fields['param_2'] = param2;
      final response = await dioClient!.post(
        AppConstants.{featureNameCamel}Uri,
        data: fields,
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
```

**Template — unauthenticated GET (omit `_setRequestHeaders` and auth imports entirely):**
```dart
  @override
  Future<ApiResponseModel> get{ClassName}List({required int offset, int limit = 10}) async {
    try {
      final response = await dioClient!.get(
        AppConstants.{featureNameCamel}Uri,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
```

---

### FILE 4: Service Interface — `domain/services/{feature_name}_service_interface.dart`

**Rules:**
- Pure abstract class — no `implements`, no constructor.
- Mirror the repository interface methods exactly but return `Future<dynamic>`.
- Same named parameters as the repository interface.

**Template:**
```dart
abstract class {ClassName}ServiceInterface {
  Future<dynamic> get{ClassName}List({
    required int offset,
    int limit = 10,
  });

  // or for POST:
  Future<dynamic> create{ClassName}({
    required String param1,
    int? param2,
  });
}
```

---

### FILE 5: Service Implementation — `domain/services/{feature_name}_service.dart`

**Rules:**
- Constructor takes `{ClassName}RepositoryInterface` via required named parameter.
- Each method simply delegates with `return await repositoryInterface.methodName(...)`.
- No logic, no error handling — pure thin wrapper.

**Template:**
```dart
import 'package:flutter_sixvalley_ecommerce/features/{feature_name}/domain/repository/{feature_name}_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/{feature_name}/domain/services/{feature_name}_service_interface.dart';

class {ClassName}Service implements {ClassName}ServiceInterface {
  final {ClassName}RepositoryInterface repositoryInterface;
  {ClassName}Service({required this.repositoryInterface});

  @override
  Future get{ClassName}List({required int offset, int limit = 10}) async {
    return await repositoryInterface.get{ClassName}List(offset: offset, limit: limit);
  }
}
```

---

### FILE 6: Controller — `controllers/{feature_name}_controller.dart`

**Rules:**
- `extends ChangeNotifier`.
- Constructor takes `{ClassName}ServiceInterface` via required named parameter.
- Always has `bool _isLoading = false` with a public getter.
- GET-list variant: add `_offset`, `_limit`, `_hasMore`, `_totalSize`, `List<Model> _items = []`.
- POST/action variant: just `_isLoading` + action method.
- State flow: `_isLoading = true; notifyListeners();` → call service → `_isLoading = false; notifyListeners();` in both branches.
- Success check: `response.response != null && response.response!.statusCode == 200`.
- Error: call `ApiChecker.checkApi(response)`.

**Template — GET list with pagination:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/{feature_name}/domain/models/{feature_name}_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/{feature_name}/domain/services/{feature_name}_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';

class {ClassName}Controller extends ChangeNotifier {
  final {ClassName}ServiceInterface serviceInterface;
  {ClassName}Controller({required this.serviceInterface});

  List<{ClassName}Model> _items = [];
  List<{ClassName}Model> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _offset = 1;
  int _totalSize = 0;
  final int _limit = 10;

  Future<void> get{ClassName}List(BuildContext context, {bool isRefresh = false}) async {
    if (isRefresh) {
      _offset = 1;
      _hasMore = true;
      _items = [];
      _totalSize = 0;
    }
    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    final ApiResponseModel response = await serviceInterface.get{ClassName}List(
      offset: _offset,
      limit: _limit,
    );

    if (response.response != null && response.response!.statusCode == 200) {
      final {ClassName}ListModel model =
          {ClassName}ListModel.fromJson(response.response!.data);
      final List<{ClassName}Model> newItems = model.data ?? [];

      if (isRefresh) {
        _items = newItems;
      } else {
        _items.addAll(newItems);
      }

      _totalSize = model.totalSize ?? 0;
      _hasMore = _items.length < _totalSize;
      if (_hasMore) _offset++;
    } else {
      ApiChecker.checkApi(response);
    }

    _isLoading = false;
    notifyListeners();
  }
}
```

**Template — POST/action:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/{feature_name}/domain/services/{feature_name}_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';

class {ClassName}Controller extends ChangeNotifier {
  final {ClassName}ServiceInterface serviceInterface;
  {ClassName}Controller({required this.serviceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> create{ClassName}(BuildContext context, {
    required String param1,
    int? param2,
  }) async {
    _isLoading = true;
    notifyListeners();

    final ApiResponseModel response = await serviceInterface.create{ClassName}(
      param1: param1,
      param2: param2,
    );

    bool isSuccess = false;
    if (response.response != null && response.response!.statusCode == 200) {
      isSuccess = true;
    } else {
      ApiChecker.checkApi(response);
    }

    _isLoading = false;
    notifyListeners();
    return isSuccess;
  }
}
```

---

## STEP 4 — Auto-Register in Project Files

After writing all 6 feature files, wire the feature into the project automatically using Read then Edit. Do NOT skip this step or print a checklist — make the edits directly.

### 4a. `lib/utill/app_constants.dart` — add URI constant

1. Read `lib/utill/app_constants.dart` and find the last `static const String` line whose name contains `auction` and ends with a URI path.
2. Edit: insert the new constant immediately after it:
```dart
  static const String {featureNameCamel}Uri = '{/api/v1/...}';
```

### 4b. `lib/di_container.dart` — add imports

1. Read the top of `lib/di_container.dart` and find the last `import` line whose path contains `auction` or the last `import` line in the existing feature import block.
2. Edit: insert the 5 new imports immediately after it (use relative paths, matching the style in the file — no `package:` prefix):
```dart
import 'features/{feature_name}/controllers/{feature_name}_controller.dart';
import 'features/{feature_name}/domain/repository/{feature_name}_repository.dart';
import 'features/{feature_name}/domain/repository/{feature_name}_repository_interface.dart';
import 'features/{feature_name}/domain/services/{feature_name}_service.dart';
import 'features/{feature_name}/domain/services/{feature_name}_service_interface.dart';
```

### 4c. `lib/di_container.dart` — add registrations

1. Read `lib/di_container.dart` and find the last `sl.registerFactory(...)` call that registers an auction controller.
2. Edit: insert the 3 new registration blocks immediately after it:
```dart

  {ClassName}RepositoryInterface {featureNameCamel}Repo =
      {ClassName}Repository(dioClient: sl());
  sl.registerLazySingleton(() => {featureNameCamel}Repo);

  {ClassName}ServiceInterface {featureNameCamel}Service =
      {ClassName}Service(repositoryInterface: sl());
  sl.registerLazySingleton(() => {featureNameCamel}Service);

  sl.registerFactory(() => {ClassName}Controller(serviceInterface: sl()));
```

### 4d. `lib/main.dart` — add provider

1. Read `lib/main.dart` and find the last `ChangeNotifierProvider` line whose controller name contains `Auction` or is the last auction-related provider.
2. Edit: insert the new provider immediately after it:
```dart
      ChangeNotifierProvider(create: (context) => di.sl<{ClassName}Controller>()),
```
Note: `main.dart` uses `di.sl<...>()` (not `sl<..>()`). Match the style exactly.

### 4e. Verify

Run and report the result:
```bash
flutter analyze lib/features/{feature_name}/
```

---

## DECISION TREE

```
Is the endpoint GET?
  YES →
    Does response have total_size / limit / offset + array key?
      YES → paginated list → generate ListModel + Model, GET-list controller
      NO  → single object → generate single Model, simple GET controller
  NO (POST / PUT / DELETE) →
    Map all request body fields as named params on the repository method.
    required = field is mandatory; optional = nullable type.
    Build the fields map locally inside the repo method.
    For DELETE: use dioClient!.delete(AppConstants.{key}Uri + '/$id').
    For PUT: add fields['_method'] = 'PUT' and use postMultipart or post.
```

---

## CRITICAL PITFALLS

- **`Get.context!`** — NEVER import from the `get` package. Import from `package:flutter_sixvalley_ecommerce/main.dart`.
- **`dioClient!`** — The field is nullable (`DioClient?`), always access with `!`.
- **AppConstants** — Store path only (e.g. `/api/v1/...`). `DioClient` prepends the base URL automatically. Never hardcode the full URL in a repository.
- **5 base methods** — ALL 5 (`add`, `delete`, `get`, `getList`, `update`) must be overridden with `throw UnimplementedError()` in every repository impl.
- **Controller factory** — Use `sl.registerFactory`, never `sl.registerLazySingleton` for controllers.
- **No `fromJson` on POST-only models** — Only response models need `fromJson`.
- **`_setRequestHeaders`** — Sets BOTH `Authorization` AND `AppConstants.langKey` (the `'lang'` header) together. Never set just one.
- **No `sl()` in feature code** — Only `di_container.dart` uses `sl`. Feature classes receive dependencies via constructor injection.

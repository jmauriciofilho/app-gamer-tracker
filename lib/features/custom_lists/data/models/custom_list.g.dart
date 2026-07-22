// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_list.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomListCollection on Isar {
  IsarCollection<CustomList> get customLists => this.collection();
}

const CustomListSchema = CollectionSchema(
  name: r'CustomList',
  id: -8525547938508663416,
  properties: {
    r'filterDeveloper': PropertySchema(
      id: 0,
      name: r'filterDeveloper',
      type: IsarType.string,
    ),
    r'filterGenre': PropertySchema(
      id: 1,
      name: r'filterGenre',
      type: IsarType.string,
    ),
    r'filterPlatform': PropertySchema(
      id: 2,
      name: r'filterPlatform',
      type: IsarType.string,
    ),
    r'filterStatus': PropertySchema(
      id: 3,
      name: r'filterStatus',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _customListEstimateSize,
  serialize: _customListSerialize,
  deserialize: _customListDeserialize,
  deserializeProp: _customListDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _customListGetId,
  getLinks: _customListGetLinks,
  attach: _customListAttach,
  version: '3.1.0+1',
);

int _customListEstimateSize(
  CustomList object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.filterDeveloper;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.filterGenre;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.filterPlatform;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.filterStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _customListSerialize(
  CustomList object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.filterDeveloper);
  writer.writeString(offsets[1], object.filterGenre);
  writer.writeString(offsets[2], object.filterPlatform);
  writer.writeString(offsets[3], object.filterStatus);
  writer.writeString(offsets[4], object.name);
}

CustomList _customListDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomList();
  object.filterDeveloper = reader.readStringOrNull(offsets[0]);
  object.filterGenre = reader.readStringOrNull(offsets[1]);
  object.filterPlatform = reader.readStringOrNull(offsets[2]);
  object.filterStatus = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.name = reader.readString(offsets[4]);
  return object;
}

P _customListDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _customListGetId(CustomList object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customListGetLinks(CustomList object) {
  return [];
}

void _customListAttach(IsarCollection<dynamic> col, Id id, CustomList object) {
  object.id = id;
}

extension CustomListQueryWhereSort
    on QueryBuilder<CustomList, CustomList, QWhere> {
  QueryBuilder<CustomList, CustomList, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomListQueryWhere
    on QueryBuilder<CustomList, CustomList, QWhereClause> {
  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CustomListQueryFilter
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {
  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filterDeveloper',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filterDeveloper',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterDeveloper',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filterDeveloper',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filterDeveloper',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filterDeveloper',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filterDeveloper',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filterDeveloper',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filterDeveloper',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filterDeveloper',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterDeveloper',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterDeveloperIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filterDeveloper',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filterGenre',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filterGenre',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterGenre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filterGenre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filterGenre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filterGenre',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filterGenre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filterGenre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filterGenre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filterGenre',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterGenre',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterGenreIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filterGenre',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filterPlatform',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filterPlatform',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterPlatform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filterPlatform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filterPlatform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filterPlatform',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filterPlatform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filterPlatform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filterPlatform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filterPlatform',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterPlatform',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterPlatformIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filterPlatform',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filterStatus',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filterStatus',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filterStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filterStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filterStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filterStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filterStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filterStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filterStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filterStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      filterStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filterStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension CustomListQueryObject
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {}

extension CustomListQueryLinks
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {}

extension CustomListQuerySortBy
    on QueryBuilder<CustomList, CustomList, QSortBy> {
  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByFilterDeveloper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterDeveloper', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy>
      sortByFilterDeveloperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterDeveloper', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByFilterGenre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterGenre', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByFilterGenreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterGenre', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByFilterPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterPlatform', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy>
      sortByFilterPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterPlatform', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByFilterStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterStatus', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByFilterStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterStatus', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension CustomListQuerySortThenBy
    on QueryBuilder<CustomList, CustomList, QSortThenBy> {
  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByFilterDeveloper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterDeveloper', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy>
      thenByFilterDeveloperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterDeveloper', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByFilterGenre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterGenre', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByFilterGenreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterGenre', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByFilterPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterPlatform', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy>
      thenByFilterPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterPlatform', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByFilterStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterStatus', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByFilterStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filterStatus', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension CustomListQueryWhereDistinct
    on QueryBuilder<CustomList, CustomList, QDistinct> {
  QueryBuilder<CustomList, CustomList, QDistinct> distinctByFilterDeveloper(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filterDeveloper',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctByFilterGenre(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filterGenre', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctByFilterPlatform(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filterPlatform',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctByFilterStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filterStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension CustomListQueryProperty
    on QueryBuilder<CustomList, CustomList, QQueryProperty> {
  QueryBuilder<CustomList, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomList, String?, QQueryOperations>
      filterDeveloperProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filterDeveloper');
    });
  }

  QueryBuilder<CustomList, String?, QQueryOperations> filterGenreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filterGenre');
    });
  }

  QueryBuilder<CustomList, String?, QQueryOperations> filterPlatformProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filterPlatform');
    });
  }

  QueryBuilder<CustomList, String?, QQueryOperations> filterStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filterStatus');
    });
  }

  QueryBuilder<CustomList, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}

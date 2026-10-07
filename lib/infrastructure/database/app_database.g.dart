// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CalendarCategoriesTable extends CalendarCategories
    with TableInfo<$CalendarCategoriesTable, CalendarCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, color, icon, sortOrder, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_categories';
  @override
  VerificationContext validateIntegrity(
      Insertable<CalendarCategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarCategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CalendarCategoriesTable createAlias(String alias) {
    return $CalendarCategoriesTable(attachedDatabase, alias);
  }
}

class CalendarCategoryRow extends DataClass
    implements Insertable<CalendarCategoryRow> {
  final String id;
  final String name;

  /// 颜色以 ARGB int 存储，避免数据库层依赖 Flutter。
  final int color;
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarCategoryRow(
      {required this.id,
      required this.name,
      required this.color,
      this.icon,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CalendarCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarCategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'icon': serializer.toJson<String?>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarCategoryRow copyWith(
          {String? id,
          String? name,
          int? color,
          Value<String?> icon = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CalendarCategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon.present ? icon.value : this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CalendarCategoryRow copyWithCompanion(CalendarCategoriesCompanion data) {
    return CalendarCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, icon, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarCategoriesCompanion extends UpdateCompanion<CalendarCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<String?> icon;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalendarCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarCategoriesCompanion.insert({
    required String id,
    required String name,
    required int color,
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        color = Value(color),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CalendarCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarCategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? color,
      Value<String?>? icon,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CalendarCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
      'all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES calendar_categories (id)'));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _repeatRuleMeta =
      const VerificationMeta('repeatRule');
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
      'repeat_rule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repeatUntilMeta =
      const VerificationMeta('repeatUntil');
  @override
  late final GeneratedColumn<DateTime> repeatUntil = GeneratedColumn<DateTime>(
      'repeat_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _reminderMinutesMeta =
      const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
      'reminder_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<EventStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<EventStatus>($CalendarEventsTable.$converterstatus);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        startTime,
        endTime,
        allDay,
        location,
        categoryId,
        color,
        repeatRule,
        repeatUntil,
        reminderMinutes,
        status,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(Insertable<CalendarEventRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('all_day')) {
      context.handle(_allDayMeta,
          allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
          _repeatRuleMeta,
          repeatRule.isAcceptableOrUnknown(
              data['repeat_rule']!, _repeatRuleMeta));
    }
    if (data.containsKey('repeat_until')) {
      context.handle(
          _repeatUntilMeta,
          repeatUntil.isAcceptableOrUnknown(
              data['repeat_until']!, _repeatUntilMeta));
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
          _reminderMinutesMeta,
          reminderMinutes.isAcceptableOrUnknown(
              data['reminder_minutes']!, _reminderMinutesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEventRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      allDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}all_day'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color']),
      repeatRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeat_rule']),
      repeatUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}repeat_until']),
      reminderMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reminder_minutes']),
      status: $CalendarEventsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EventStatus, String, String> $converterstatus =
      const EnumNameConverter<EventStatus>(EventStatus.values);
}

class CalendarEventRow extends DataClass
    implements Insertable<CalendarEventRow> {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? location;
  final String? categoryId;

  /// 事件自定义颜色（ARGB int）。
  final int? color;

  /// 重复规则：`none` / `daily` / `weekly` / `monthly` / `yearly`（null 等价于不重复）。
  final String? repeatRule;

  /// 重复的结束日期（含当天）；为空表示一直重复（按查询窗口展开）。
  final DateTime? repeatUntil;

  /// 提前提醒分钟数。
  final int? reminderMinutes;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarEventRow(
      {required this.id,
      required this.title,
      this.description,
      required this.startTime,
      required this.endTime,
      required this.allDay,
      this.location,
      this.categoryId,
      this.color,
      this.repeatRule,
      this.repeatUntil,
      this.reminderMinutes,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    if (!nullToAbsent || repeatUntil != null) {
      map['repeat_until'] = Variable<DateTime>(repeatUntil);
    }
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    {
      map['status'] =
          Variable<String>($CalendarEventsTable.$converterstatus.toSql(status));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startTime: Value(startTime),
      endTime: Value(endTime),
      allDay: Value(allDay),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      repeatUntil: repeatUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatUntil),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarEventRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEventRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      location: serializer.fromJson<String?>(json['location']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      color: serializer.fromJson<int?>(json['color']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      repeatUntil: serializer.fromJson<DateTime?>(json['repeatUntil']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      status: $CalendarEventsTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'allDay': serializer.toJson<bool>(allDay),
      'location': serializer.toJson<String?>(location),
      'categoryId': serializer.toJson<String?>(categoryId),
      'color': serializer.toJson<int?>(color),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'repeatUntil': serializer.toJson<DateTime?>(repeatUntil),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'status': serializer
          .toJson<String>($CalendarEventsTable.$converterstatus.toJson(status)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarEventRow copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          DateTime? startTime,
          DateTime? endTime,
          bool? allDay,
          Value<String?> location = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          Value<int?> color = const Value.absent(),
          Value<String?> repeatRule = const Value.absent(),
          Value<DateTime?> repeatUntil = const Value.absent(),
          Value<int?> reminderMinutes = const Value.absent(),
          EventStatus? status,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CalendarEventRow(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        allDay: allDay ?? this.allDay,
        location: location.present ? location.value : this.location,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        color: color.present ? color.value : this.color,
        repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
        repeatUntil: repeatUntil.present ? repeatUntil.value : this.repeatUntil,
        reminderMinutes: reminderMinutes.present
            ? reminderMinutes.value
            : this.reminderMinutes,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CalendarEventRow copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEventRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      location: data.location.present ? data.location.value : this.location,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      color: data.color.present ? data.color.value : this.color,
      repeatRule:
          data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      repeatUntil:
          data.repeatUntil.present ? data.repeatUntil.value : this.repeatUntil,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('location: $location, ')
          ..write('categoryId: $categoryId, ')
          ..write('color: $color, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatUntil: $repeatUntil, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      startTime,
      endTime,
      allDay,
      location,
      categoryId,
      color,
      repeatRule,
      repeatUntil,
      reminderMinutes,
      status,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEventRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.allDay == this.allDay &&
          other.location == this.location &&
          other.categoryId == this.categoryId &&
          other.color == this.color &&
          other.repeatRule == this.repeatRule &&
          other.repeatUntil == this.repeatUntil &&
          other.reminderMinutes == this.reminderMinutes &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEventRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<bool> allDay;
  final Value<String?> location;
  final Value<String?> categoryId;
  final Value<int?> color;
  final Value<String?> repeatRule;
  final Value<DateTime?> repeatUntil;
  final Value<int?> reminderMinutes;
  final Value<EventStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.allDay = const Value.absent(),
    this.location = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.color = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.repeatUntil = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    this.allDay = const Value.absent(),
    this.location = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.color = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.repeatUntil = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    required EventStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        startTime = Value(startTime),
        endTime = Value(endTime),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CalendarEventRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? allDay,
    Expression<String>? location,
    Expression<String>? categoryId,
    Expression<int>? color,
    Expression<String>? repeatRule,
    Expression<DateTime>? repeatUntil,
    Expression<int>? reminderMinutes,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (allDay != null) 'all_day': allDay,
      if (location != null) 'location': location,
      if (categoryId != null) 'category_id': categoryId,
      if (color != null) 'color': color,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (repeatUntil != null) 'repeat_until': repeatUntil,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<bool>? allDay,
      Value<String?>? location,
      Value<String?>? categoryId,
      Value<int?>? color,
      Value<String?>? repeatRule,
      Value<DateTime?>? repeatUntil,
      Value<int?>? reminderMinutes,
      Value<EventStatus>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      color: color ?? this.color,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatUntil: repeatUntil ?? this.repeatUntil,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (repeatUntil.present) {
      map['repeat_until'] = Variable<DateTime>(repeatUntil.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $CalendarEventsTable.$converterstatus.toSql(status.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('location: $location, ')
          ..write('categoryId: $categoryId, ')
          ..write('color: $color, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('repeatUntil: $repeatUntil, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CountdownsTable extends Countdowns
    with TableInfo<$CountdownsTable, CountdownRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountdownsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetTimeMeta =
      const VerificationMeta('targetTime');
  @override
  late final GeneratedColumn<DateTime> targetTime = GeneratedColumn<DateTime>(
      'target_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _backgroundColorMeta =
      const VerificationMeta('backgroundColor');
  @override
  late final GeneratedColumn<int> backgroundColor = GeneratedColumn<int>(
      'background_color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<CountdownDisplayStyle, String>
      displayStyle = GeneratedColumn<String>(
              'display_style', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<CountdownDisplayStyle>(
              $CountdownsTable.$converterdisplayStyle);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        targetTime,
        description,
        color,
        backgroundColor,
        icon,
        isPinned,
        displayStyle,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'countdowns';
  @override
  VerificationContext validateIntegrity(Insertable<CountdownRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_time')) {
      context.handle(
          _targetTimeMeta,
          targetTime.isAcceptableOrUnknown(
              data['target_time']!, _targetTimeMeta));
    } else if (isInserting) {
      context.missing(_targetTimeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('background_color')) {
      context.handle(
          _backgroundColorMeta,
          backgroundColor.isAcceptableOrUnknown(
              data['background_color']!, _backgroundColorMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CountdownRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CountdownRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      targetTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}target_time'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color']),
      backgroundColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}background_color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      displayStyle: $CountdownsTable.$converterdisplayStyle.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}display_style'])!),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CountdownsTable createAlias(String alias) {
    return $CountdownsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CountdownDisplayStyle, String, String>
      $converterdisplayStyle = const EnumNameConverter<CountdownDisplayStyle>(
          CountdownDisplayStyle.values);
}

class CountdownRow extends DataClass implements Insertable<CountdownRow> {
  final String id;
  final String title;
  final DateTime targetTime;
  final String? description;
  final int? color;

  /// 卡片背景色（ARGB int）；为空时用主题的 surface。
  final int? backgroundColor;
  final String? icon;
  final bool isPinned;
  final CountdownDisplayStyle displayStyle;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CountdownRow(
      {required this.id,
      required this.title,
      required this.targetTime,
      this.description,
      this.color,
      this.backgroundColor,
      this.icon,
      required this.isPinned,
      required this.displayStyle,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['target_time'] = Variable<DateTime>(targetTime);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || backgroundColor != null) {
      map['background_color'] = Variable<int>(backgroundColor);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    {
      map['display_style'] = Variable<String>(
          $CountdownsTable.$converterdisplayStyle.toSql(displayStyle));
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CountdownsCompanion toCompanion(bool nullToAbsent) {
    return CountdownsCompanion(
      id: Value(id),
      title: Value(title),
      targetTime: Value(targetTime),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      backgroundColor: backgroundColor == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundColor),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isPinned: Value(isPinned),
      displayStyle: Value(displayStyle),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CountdownRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CountdownRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetTime: serializer.fromJson<DateTime>(json['targetTime']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<int?>(json['color']),
      backgroundColor: serializer.fromJson<int?>(json['backgroundColor']),
      icon: serializer.fromJson<String?>(json['icon']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      displayStyle: $CountdownsTable.$converterdisplayStyle
          .fromJson(serializer.fromJson<String>(json['displayStyle'])),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'targetTime': serializer.toJson<DateTime>(targetTime),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<int?>(color),
      'backgroundColor': serializer.toJson<int?>(backgroundColor),
      'icon': serializer.toJson<String?>(icon),
      'isPinned': serializer.toJson<bool>(isPinned),
      'displayStyle': serializer.toJson<String>(
          $CountdownsTable.$converterdisplayStyle.toJson(displayStyle)),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CountdownRow copyWith(
          {String? id,
          String? title,
          DateTime? targetTime,
          Value<String?> description = const Value.absent(),
          Value<int?> color = const Value.absent(),
          Value<int?> backgroundColor = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          bool? isPinned,
          CountdownDisplayStyle? displayStyle,
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CountdownRow(
        id: id ?? this.id,
        title: title ?? this.title,
        targetTime: targetTime ?? this.targetTime,
        description: description.present ? description.value : this.description,
        color: color.present ? color.value : this.color,
        backgroundColor: backgroundColor.present
            ? backgroundColor.value
            : this.backgroundColor,
        icon: icon.present ? icon.value : this.icon,
        isPinned: isPinned ?? this.isPinned,
        displayStyle: displayStyle ?? this.displayStyle,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CountdownRow copyWithCompanion(CountdownsCompanion data) {
    return CountdownRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetTime:
          data.targetTime.present ? data.targetTime.value : this.targetTime,
      description:
          data.description.present ? data.description.value : this.description,
      color: data.color.present ? data.color.value : this.color,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      icon: data.icon.present ? data.icon.value : this.icon,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      displayStyle: data.displayStyle.present
          ? data.displayStyle.value
          : this.displayStyle,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CountdownRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetTime: $targetTime, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('icon: $icon, ')
          ..write('isPinned: $isPinned, ')
          ..write('displayStyle: $displayStyle, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      targetTime,
      description,
      color,
      backgroundColor,
      icon,
      isPinned,
      displayStyle,
      sortOrder,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CountdownRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetTime == this.targetTime &&
          other.description == this.description &&
          other.color == this.color &&
          other.backgroundColor == this.backgroundColor &&
          other.icon == this.icon &&
          other.isPinned == this.isPinned &&
          other.displayStyle == this.displayStyle &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CountdownsCompanion extends UpdateCompanion<CountdownRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> targetTime;
  final Value<String?> description;
  final Value<int?> color;
  final Value<int?> backgroundColor;
  final Value<String?> icon;
  final Value<bool> isPinned;
  final Value<CountdownDisplayStyle> displayStyle;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CountdownsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetTime = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.displayStyle = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountdownsCompanion.insert({
    required String id,
    required String title,
    required DateTime targetTime,
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.isPinned = const Value.absent(),
    required CountdownDisplayStyle displayStyle,
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        targetTime = Value(targetTime),
        displayStyle = Value(displayStyle),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CountdownRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? targetTime,
    Expression<String>? description,
    Expression<int>? color,
    Expression<int>? backgroundColor,
    Expression<String>? icon,
    Expression<bool>? isPinned,
    Expression<String>? displayStyle,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetTime != null) 'target_time': targetTime,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (icon != null) 'icon': icon,
      if (isPinned != null) 'is_pinned': isPinned,
      if (displayStyle != null) 'display_style': displayStyle,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountdownsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<DateTime>? targetTime,
      Value<String?>? description,
      Value<int?>? color,
      Value<int?>? backgroundColor,
      Value<String?>? icon,
      Value<bool>? isPinned,
      Value<CountdownDisplayStyle>? displayStyle,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CountdownsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetTime: targetTime ?? this.targetTime,
      description: description ?? this.description,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: icon ?? this.icon,
      isPinned: isPinned ?? this.isPinned,
      displayStyle: displayStyle ?? this.displayStyle,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetTime.present) {
      map['target_time'] = Variable<DateTime>(targetTime.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<int>(backgroundColor.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (displayStyle.present) {
      map['display_style'] = Variable<String>(
          $CountdownsTable.$converterdisplayStyle.toSql(displayStyle.value));
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountdownsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetTime: $targetTime, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('icon: $icon, ')
          ..write('isPinned: $isPinned, ')
          ..write('displayStyle: $displayStyle, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES calendar_events (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _triggerTimeMeta =
      const VerificationMeta('triggerTime');
  @override
  late final GeneratedColumn<DateTime> triggerTime = GeneratedColumn<DateTime>(
      'trigger_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _repeatRuleMeta =
      const VerificationMeta('repeatRule');
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
      'repeat_rule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, eventId, title, triggerTime, repeatRule, enabled, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('trigger_time')) {
      context.handle(
          _triggerTimeMeta,
          triggerTime.isAcceptableOrUnknown(
              data['trigger_time']!, _triggerTimeMeta));
    } else if (isInserting) {
      context.missing(_triggerTimeMeta);
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
          _repeatRuleMeta,
          repeatRule.isAcceptableOrUnknown(
              data['repeat_rule']!, _repeatRuleMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      triggerTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}trigger_time'])!,
      repeatRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeat_rule']),
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;

  /// 关联日程；为空表示独立提醒。
  final String? eventId;
  final String title;
  final DateTime triggerTime;
  final String? repeatRule;
  final bool enabled;
  final DateTime createdAt;
  const ReminderRow(
      {required this.id,
      this.eventId,
      required this.title,
      required this.triggerTime,
      this.repeatRule,
      required this.enabled,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    map['title'] = Variable<String>(title);
    map['trigger_time'] = Variable<DateTime>(triggerTime);
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      title: Value(title),
      triggerTime: Value(triggerTime),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
    );
  }

  factory ReminderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      title: serializer.fromJson<String>(json['title']),
      triggerTime: serializer.fromJson<DateTime>(json['triggerTime']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String?>(eventId),
      'title': serializer.toJson<String>(title),
      'triggerTime': serializer.toJson<DateTime>(triggerTime),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReminderRow copyWith(
          {String? id,
          Value<String?> eventId = const Value.absent(),
          String? title,
          DateTime? triggerTime,
          Value<String?> repeatRule = const Value.absent(),
          bool? enabled,
          DateTime? createdAt}) =>
      ReminderRow(
        id: id ?? this.id,
        eventId: eventId.present ? eventId.value : this.eventId,
        title: title ?? this.title,
        triggerTime: triggerTime ?? this.triggerTime,
        repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt ?? this.createdAt,
      );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      title: data.title.present ? data.title.value : this.title,
      triggerTime:
          data.triggerTime.present ? data.triggerTime.value : this.triggerTime,
      repeatRule:
          data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('title: $title, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, eventId, title, triggerTime, repeatRule, enabled, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.title == this.title &&
          other.triggerTime == this.triggerTime &&
          other.repeatRule == this.repeatRule &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String?> eventId;
  final Value<String> title;
  final Value<DateTime> triggerTime;
  final Value<String?> repeatRule;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.title = const Value.absent(),
    this.triggerTime = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    this.eventId = const Value.absent(),
    required String title,
    required DateTime triggerTime,
    this.repeatRule = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        triggerTime = Value(triggerTime),
        createdAt = Value(createdAt);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? title,
    Expression<DateTime>? triggerTime,
    Expression<String>? repeatRule,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (title != null) 'title': title,
      if (triggerTime != null) 'trigger_time': triggerTime,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith(
      {Value<String>? id,
      Value<String?>? eventId,
      Value<String>? title,
      Value<DateTime>? triggerTime,
      Value<String?>? repeatRule,
      Value<bool>? enabled,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RemindersCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      triggerTime: triggerTime ?? this.triggerTime,
      repeatRule: repeatRule ?? this.repeatRule,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (triggerTime.present) {
      map['trigger_time'] = Variable<DateTime>(triggerTime.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('title: $title, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiPersonasTable extends AiPersonas
    with TableInfo<$AiPersonasTable, AiPersonaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiPersonasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
      'avatar', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarColorMeta =
      const VerificationMeta('avatarColor');
  @override
  late final GeneratedColumn<int> avatarColor = GeneratedColumn<int>(
      'avatar_color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _personalityMeta =
      const VerificationMeta('personality');
  @override
  late final GeneratedColumn<String> personality = GeneratedColumn<String>(
      'personality', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _speakingStyleMeta =
      const VerificationMeta('speakingStyle');
  @override
  late final GeneratedColumn<String> speakingStyle = GeneratedColumn<String>(
      'speaking_style', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userNicknameMeta =
      const VerificationMeta('userNickname');
  @override
  late final GeneratedColumn<String> userNickname = GeneratedColumn<String>(
      'user_nickname', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _systemPromptMeta =
      const VerificationMeta('systemPrompt');
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
      'system_prompt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      enabledTools = GeneratedColumn<String>(
              'enabled_tools', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($AiPersonasTable.$converterenabledTools);
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.7));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        avatar,
        avatarColor,
        description,
        personality,
        speakingStyle,
        userNickname,
        systemPrompt,
        enabledTools,
        temperature,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_personas';
  @override
  VerificationContext validateIntegrity(Insertable<AiPersonaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(_avatarMeta,
          avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta));
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
          _avatarColorMeta,
          avatarColor.isAcceptableOrUnknown(
              data['avatar_color']!, _avatarColorMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('personality')) {
      context.handle(
          _personalityMeta,
          personality.isAcceptableOrUnknown(
              data['personality']!, _personalityMeta));
    }
    if (data.containsKey('speaking_style')) {
      context.handle(
          _speakingStyleMeta,
          speakingStyle.isAcceptableOrUnknown(
              data['speaking_style']!, _speakingStyleMeta));
    }
    if (data.containsKey('user_nickname')) {
      context.handle(
          _userNicknameMeta,
          userNickname.isAcceptableOrUnknown(
              data['user_nickname']!, _userNicknameMeta));
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
          _systemPromptMeta,
          systemPrompt.isAcceptableOrUnknown(
              data['system_prompt']!, _systemPromptMeta));
    }
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiPersonaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiPersonaRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar']),
      avatarColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avatar_color']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      personality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}personality']),
      speakingStyle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}speaking_style']),
      userNickname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_nickname']),
      systemPrompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_prompt']),
      enabledTools: $AiPersonasTable.$converterenabledTools.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}enabled_tools'])!),
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AiPersonasTable createAlias(String alias) {
    return $AiPersonasTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterenabledTools =
      const StringListConverter();
}

class AiPersonaRow extends DataClass implements Insertable<AiPersonaRow> {
  final String id;
  final String name;
  final String? avatar;

  /// 头像底色（ARGB int），配合 emoji / 单字头像使用。
  final int? avatarColor;
  final String? description;
  final String? personality;
  final String? speakingStyle;
  final String? userNickname;
  final String? systemPrompt;
  final List<String> enabledTools;
  final double temperature;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiPersonaRow(
      {required this.id,
      required this.name,
      this.avatar,
      this.avatarColor,
      this.description,
      this.personality,
      this.speakingStyle,
      this.userNickname,
      this.systemPrompt,
      required this.enabledTools,
      required this.temperature,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || avatarColor != null) {
      map['avatar_color'] = Variable<int>(avatarColor);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || personality != null) {
      map['personality'] = Variable<String>(personality);
    }
    if (!nullToAbsent || speakingStyle != null) {
      map['speaking_style'] = Variable<String>(speakingStyle);
    }
    if (!nullToAbsent || userNickname != null) {
      map['user_nickname'] = Variable<String>(userNickname);
    }
    if (!nullToAbsent || systemPrompt != null) {
      map['system_prompt'] = Variable<String>(systemPrompt);
    }
    {
      map['enabled_tools'] = Variable<String>(
          $AiPersonasTable.$converterenabledTools.toSql(enabledTools));
    }
    map['temperature'] = Variable<double>(temperature);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AiPersonasCompanion toCompanion(bool nullToAbsent) {
    return AiPersonasCompanion(
      id: Value(id),
      name: Value(name),
      avatar:
          avatar == null && nullToAbsent ? const Value.absent() : Value(avatar),
      avatarColor: avatarColor == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarColor),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      personality: personality == null && nullToAbsent
          ? const Value.absent()
          : Value(personality),
      speakingStyle: speakingStyle == null && nullToAbsent
          ? const Value.absent()
          : Value(speakingStyle),
      userNickname: userNickname == null && nullToAbsent
          ? const Value.absent()
          : Value(userNickname),
      systemPrompt: systemPrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(systemPrompt),
      enabledTools: Value(enabledTools),
      temperature: Value(temperature),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiPersonaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiPersonaRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      avatarColor: serializer.fromJson<int?>(json['avatarColor']),
      description: serializer.fromJson<String?>(json['description']),
      personality: serializer.fromJson<String?>(json['personality']),
      speakingStyle: serializer.fromJson<String?>(json['speakingStyle']),
      userNickname: serializer.fromJson<String?>(json['userNickname']),
      systemPrompt: serializer.fromJson<String?>(json['systemPrompt']),
      enabledTools: serializer.fromJson<List<String>>(json['enabledTools']),
      temperature: serializer.fromJson<double>(json['temperature']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatar': serializer.toJson<String?>(avatar),
      'avatarColor': serializer.toJson<int?>(avatarColor),
      'description': serializer.toJson<String?>(description),
      'personality': serializer.toJson<String?>(personality),
      'speakingStyle': serializer.toJson<String?>(speakingStyle),
      'userNickname': serializer.toJson<String?>(userNickname),
      'systemPrompt': serializer.toJson<String?>(systemPrompt),
      'enabledTools': serializer.toJson<List<String>>(enabledTools),
      'temperature': serializer.toJson<double>(temperature),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiPersonaRow copyWith(
          {String? id,
          String? name,
          Value<String?> avatar = const Value.absent(),
          Value<int?> avatarColor = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> personality = const Value.absent(),
          Value<String?> speakingStyle = const Value.absent(),
          Value<String?> userNickname = const Value.absent(),
          Value<String?> systemPrompt = const Value.absent(),
          List<String>? enabledTools,
          double? temperature,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AiPersonaRow(
        id: id ?? this.id,
        name: name ?? this.name,
        avatar: avatar.present ? avatar.value : this.avatar,
        avatarColor: avatarColor.present ? avatarColor.value : this.avatarColor,
        description: description.present ? description.value : this.description,
        personality: personality.present ? personality.value : this.personality,
        speakingStyle:
            speakingStyle.present ? speakingStyle.value : this.speakingStyle,
        userNickname:
            userNickname.present ? userNickname.value : this.userNickname,
        systemPrompt:
            systemPrompt.present ? systemPrompt.value : this.systemPrompt,
        enabledTools: enabledTools ?? this.enabledTools,
        temperature: temperature ?? this.temperature,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AiPersonaRow copyWithCompanion(AiPersonasCompanion data) {
    return AiPersonaRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      avatarColor:
          data.avatarColor.present ? data.avatarColor.value : this.avatarColor,
      description:
          data.description.present ? data.description.value : this.description,
      personality:
          data.personality.present ? data.personality.value : this.personality,
      speakingStyle: data.speakingStyle.present
          ? data.speakingStyle.value
          : this.speakingStyle,
      userNickname: data.userNickname.present
          ? data.userNickname.value
          : this.userNickname,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      enabledTools: data.enabledTools.present
          ? data.enabledTools.value
          : this.enabledTools,
      temperature:
          data.temperature.present ? data.temperature.value : this.temperature,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiPersonaRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('description: $description, ')
          ..write('personality: $personality, ')
          ..write('speakingStyle: $speakingStyle, ')
          ..write('userNickname: $userNickname, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('enabledTools: $enabledTools, ')
          ..write('temperature: $temperature, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      avatar,
      avatarColor,
      description,
      personality,
      speakingStyle,
      userNickname,
      systemPrompt,
      enabledTools,
      temperature,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiPersonaRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatar == this.avatar &&
          other.avatarColor == this.avatarColor &&
          other.description == this.description &&
          other.personality == this.personality &&
          other.speakingStyle == this.speakingStyle &&
          other.userNickname == this.userNickname &&
          other.systemPrompt == this.systemPrompt &&
          other.enabledTools == this.enabledTools &&
          other.temperature == this.temperature &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiPersonasCompanion extends UpdateCompanion<AiPersonaRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> avatar;
  final Value<int?> avatarColor;
  final Value<String?> description;
  final Value<String?> personality;
  final Value<String?> speakingStyle;
  final Value<String?> userNickname;
  final Value<String?> systemPrompt;
  final Value<List<String>> enabledTools;
  final Value<double> temperature;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AiPersonasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.description = const Value.absent(),
    this.personality = const Value.absent(),
    this.speakingStyle = const Value.absent(),
    this.userNickname = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.enabledTools = const Value.absent(),
    this.temperature = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiPersonasCompanion.insert({
    required String id,
    required String name,
    this.avatar = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.description = const Value.absent(),
    this.personality = const Value.absent(),
    this.speakingStyle = const Value.absent(),
    this.userNickname = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    required List<String> enabledTools,
    this.temperature = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        enabledTools = Value(enabledTools),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AiPersonaRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatar,
    Expression<int>? avatarColor,
    Expression<String>? description,
    Expression<String>? personality,
    Expression<String>? speakingStyle,
    Expression<String>? userNickname,
    Expression<String>? systemPrompt,
    Expression<String>? enabledTools,
    Expression<double>? temperature,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (description != null) 'description': description,
      if (personality != null) 'personality': personality,
      if (speakingStyle != null) 'speaking_style': speakingStyle,
      if (userNickname != null) 'user_nickname': userNickname,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (enabledTools != null) 'enabled_tools': enabledTools,
      if (temperature != null) 'temperature': temperature,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiPersonasCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? avatar,
      Value<int?>? avatarColor,
      Value<String?>? description,
      Value<String?>? personality,
      Value<String?>? speakingStyle,
      Value<String?>? userNickname,
      Value<String?>? systemPrompt,
      Value<List<String>>? enabledTools,
      Value<double>? temperature,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AiPersonasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      avatarColor: avatarColor ?? this.avatarColor,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      speakingStyle: speakingStyle ?? this.speakingStyle,
      userNickname: userNickname ?? this.userNickname,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      enabledTools: enabledTools ?? this.enabledTools,
      temperature: temperature ?? this.temperature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<int>(avatarColor.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (personality.present) {
      map['personality'] = Variable<String>(personality.value);
    }
    if (speakingStyle.present) {
      map['speaking_style'] = Variable<String>(speakingStyle.value);
    }
    if (userNickname.present) {
      map['user_nickname'] = Variable<String>(userNickname.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (enabledTools.present) {
      map['enabled_tools'] = Variable<String>(
          $AiPersonasTable.$converterenabledTools.toSql(enabledTools.value));
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiPersonasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('description: $description, ')
          ..write('personality: $personality, ')
          ..write('speakingStyle: $speakingStyle, ')
          ..write('userNickname: $userNickname, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('enabledTools: $enabledTools, ')
          ..write('temperature: $temperature, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiProvidersTable extends AiProviders
    with TableInfo<$AiProvidersTable, AiProviderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseUrlMeta =
      const VerificationMeta('baseUrl');
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.7));
  static const VerificationMeta _maxTokensMeta =
      const VerificationMeta('maxTokens');
  @override
  late final GeneratedColumn<int> maxTokens = GeneratedColumn<int>(
      'max_tokens', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _streamingEnabledMeta =
      const VerificationMeta('streamingEnabled');
  @override
  late final GeneratedColumn<bool> streamingEnabled = GeneratedColumn<bool>(
      'streaming_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("streaming_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        baseUrl,
        apiKey,
        model,
        temperature,
        maxTokens,
        streamingEnabled,
        isDefault,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_providers';
  @override
  VerificationContext validateIntegrity(Insertable<AiProviderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(_baseUrlMeta,
          baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta));
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(_apiKeyMeta,
          apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('max_tokens')) {
      context.handle(_maxTokensMeta,
          maxTokens.isAcceptableOrUnknown(data['max_tokens']!, _maxTokensMeta));
    }
    if (data.containsKey('streaming_enabled')) {
      context.handle(
          _streamingEnabledMeta,
          streamingEnabled.isAcceptableOrUnknown(
              data['streaming_enabled']!, _streamingEnabledMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiProviderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiProviderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      baseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_url'])!,
      apiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_key']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature'])!,
      maxTokens: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_tokens']),
      streamingEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}streaming_enabled'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AiProvidersTable createAlias(String alias) {
    return $AiProvidersTable(attachedDatabase, alias);
  }
}

class AiProviderRow extends DataClass implements Insertable<AiProviderRow> {
  final String id;
  final String name;
  final String baseUrl;
  final String? apiKey;
  final String model;
  final double temperature;
  final int? maxTokens;
  final bool streamingEnabled;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiProviderRow(
      {required this.id,
      required this.name,
      required this.baseUrl,
      this.apiKey,
      required this.model,
      required this.temperature,
      this.maxTokens,
      required this.streamingEnabled,
      required this.isDefault,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_url'] = Variable<String>(baseUrl);
    if (!nullToAbsent || apiKey != null) {
      map['api_key'] = Variable<String>(apiKey);
    }
    map['model'] = Variable<String>(model);
    map['temperature'] = Variable<double>(temperature);
    if (!nullToAbsent || maxTokens != null) {
      map['max_tokens'] = Variable<int>(maxTokens);
    }
    map['streaming_enabled'] = Variable<bool>(streamingEnabled);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AiProvidersCompanion toCompanion(bool nullToAbsent) {
    return AiProvidersCompanion(
      id: Value(id),
      name: Value(name),
      baseUrl: Value(baseUrl),
      apiKey:
          apiKey == null && nullToAbsent ? const Value.absent() : Value(apiKey),
      model: Value(model),
      temperature: Value(temperature),
      maxTokens: maxTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTokens),
      streamingEnabled: Value(streamingEnabled),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiProviderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiProviderRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      apiKey: serializer.fromJson<String?>(json['apiKey']),
      model: serializer.fromJson<String>(json['model']),
      temperature: serializer.fromJson<double>(json['temperature']),
      maxTokens: serializer.fromJson<int?>(json['maxTokens']),
      streamingEnabled: serializer.fromJson<bool>(json['streamingEnabled']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'apiKey': serializer.toJson<String?>(apiKey),
      'model': serializer.toJson<String>(model),
      'temperature': serializer.toJson<double>(temperature),
      'maxTokens': serializer.toJson<int?>(maxTokens),
      'streamingEnabled': serializer.toJson<bool>(streamingEnabled),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiProviderRow copyWith(
          {String? id,
          String? name,
          String? baseUrl,
          Value<String?> apiKey = const Value.absent(),
          String? model,
          double? temperature,
          Value<int?> maxTokens = const Value.absent(),
          bool? streamingEnabled,
          bool? isDefault,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AiProviderRow(
        id: id ?? this.id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey.present ? apiKey.value : this.apiKey,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens.present ? maxTokens.value : this.maxTokens,
        streamingEnabled: streamingEnabled ?? this.streamingEnabled,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AiProviderRow copyWithCompanion(AiProvidersCompanion data) {
    return AiProviderRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      model: data.model.present ? data.model.value : this.model,
      temperature:
          data.temperature.present ? data.temperature.value : this.temperature,
      maxTokens: data.maxTokens.present ? data.maxTokens.value : this.maxTokens,
      streamingEnabled: data.streamingEnabled.present
          ? data.streamingEnabled.value
          : this.streamingEnabled,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiProviderRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('model: $model, ')
          ..write('temperature: $temperature, ')
          ..write('maxTokens: $maxTokens, ')
          ..write('streamingEnabled: $streamingEnabled, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, baseUrl, apiKey, model, temperature,
      maxTokens, streamingEnabled, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiProviderRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseUrl == this.baseUrl &&
          other.apiKey == this.apiKey &&
          other.model == this.model &&
          other.temperature == this.temperature &&
          other.maxTokens == this.maxTokens &&
          other.streamingEnabled == this.streamingEnabled &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiProvidersCompanion extends UpdateCompanion<AiProviderRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseUrl;
  final Value<String?> apiKey;
  final Value<String> model;
  final Value<double> temperature;
  final Value<int?> maxTokens;
  final Value<bool> streamingEnabled;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AiProvidersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.model = const Value.absent(),
    this.temperature = const Value.absent(),
    this.maxTokens = const Value.absent(),
    this.streamingEnabled = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiProvidersCompanion.insert({
    required String id,
    required String name,
    required String baseUrl,
    this.apiKey = const Value.absent(),
    required String model,
    this.temperature = const Value.absent(),
    this.maxTokens = const Value.absent(),
    this.streamingEnabled = const Value.absent(),
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        baseUrl = Value(baseUrl),
        model = Value(model),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AiProviderRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseUrl,
    Expression<String>? apiKey,
    Expression<String>? model,
    Expression<double>? temperature,
    Expression<int>? maxTokens,
    Expression<bool>? streamingEnabled,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseUrl != null) 'base_url': baseUrl,
      if (apiKey != null) 'api_key': apiKey,
      if (model != null) 'model': model,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (streamingEnabled != null) 'streaming_enabled': streamingEnabled,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiProvidersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? baseUrl,
      Value<String?>? apiKey,
      Value<String>? model,
      Value<double>? temperature,
      Value<int?>? maxTokens,
      Value<bool>? streamingEnabled,
      Value<bool>? isDefault,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AiProvidersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (maxTokens.present) {
      map['max_tokens'] = Variable<int>(maxTokens.value);
    }
    if (streamingEnabled.present) {
      map['streaming_enabled'] = Variable<bool>(streamingEnabled.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiProvidersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('model: $model, ')
          ..write('temperature: $temperature, ')
          ..write('maxTokens: $maxTokens, ')
          ..write('streamingEnabled: $streamingEnabled, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatSessionsTable extends ChatSessions
    with TableInfo<$ChatSessionsTable, ChatSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personaIdMeta =
      const VerificationMeta('personaId');
  @override
  late final GeneratedColumn<String> personaId = GeneratedColumn<String>(
      'persona_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ai_personas (id)'));
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, personaId, providerId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ChatSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('persona_id')) {
      context.handle(_personaIdMeta,
          personaId.isAcceptableOrUnknown(data['persona_id']!, _personaIdMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      personaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}persona_id']),
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }
}

class ChatSessionRow extends DataClass implements Insertable<ChatSessionRow> {
  final String id;
  final String title;
  final String? personaId;

  /// 这个会话用哪个服务商；为空时用"默认服务商"。
  /// 故意不加外键：SQLite 的 ALTER TABLE ADD COLUMN 不方便带 REFERENCES，
  /// 服务商被删掉时的回落逻辑放在应用层（见 activeAiConfigProvider）。
  final String? providerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChatSessionRow(
      {required this.id,
      required this.title,
      this.personaId,
      this.providerId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || personaId != null) {
      map['persona_id'] = Variable<String>(personaId);
    }
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      id: Value(id),
      title: Value(title),
      personaId: personaId == null && nullToAbsent
          ? const Value.absent()
          : Value(personaId),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSessionRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      personaId: serializer.fromJson<String?>(json['personaId']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'personaId': serializer.toJson<String?>(personaId),
      'providerId': serializer.toJson<String?>(providerId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChatSessionRow copyWith(
          {String? id,
          String? title,
          Value<String?> personaId = const Value.absent(),
          Value<String?> providerId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ChatSessionRow(
        id: id ?? this.id,
        title: title ?? this.title,
        personaId: personaId.present ? personaId.value : this.personaId,
        providerId: providerId.present ? providerId.value : this.providerId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChatSessionRow copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSessionRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      personaId: data.personaId.present ? data.personaId.value : this.personaId,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('personaId: $personaId, ')
          ..write('providerId: $providerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, personaId, providerId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSessionRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.personaId == this.personaId &&
          other.providerId == this.providerId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSessionRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> personaId;
  final Value<String?> providerId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.personaId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    required String id,
    required String title,
    this.personaId = const Value.absent(),
    this.providerId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ChatSessionRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? personaId,
    Expression<String>? providerId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (personaId != null) 'persona_id': personaId,
      if (providerId != null) 'provider_id': providerId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? personaId,
      Value<String?>? providerId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      personaId: personaId ?? this.personaId,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (personaId.present) {
      map['persona_id'] = Variable<String>(personaId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('personaId: $personaId, ')
          ..write('providerId: $providerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES chat_sessions (id)'));
  @override
  late final GeneratedColumnWithTypeConverter<ChatRole, String> role =
      GeneratedColumn<String>('role', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ChatRole>($ChatMessagesTable.$converterrole);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toolNameMeta =
      const VerificationMeta('toolName');
  @override
  late final GeneratedColumn<String> toolName = GeneratedColumn<String>(
      'tool_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toolCallIdMeta =
      const VerificationMeta('toolCallId');
  @override
  late final GeneratedColumn<String> toolCallId = GeneratedColumn<String>(
      'tool_call_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toolArgumentsMeta =
      const VerificationMeta('toolArguments');
  @override
  late final GeneratedColumn<String> toolArguments = GeneratedColumn<String>(
      'tool_arguments', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toolResultMeta =
      const VerificationMeta('toolResult');
  @override
  late final GeneratedColumn<String> toolResult = GeneratedColumn<String>(
      'tool_result', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reasoningContentMeta =
      const VerificationMeta('reasoningContent');
  @override
  late final GeneratedColumn<String> reasoningContent = GeneratedColumn<String>(
      'reasoning_content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        role,
        content,
        toolName,
        toolCallId,
        toolArguments,
        toolResult,
        reasoningContent,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessageRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tool_name')) {
      context.handle(_toolNameMeta,
          toolName.isAcceptableOrUnknown(data['tool_name']!, _toolNameMeta));
    }
    if (data.containsKey('tool_call_id')) {
      context.handle(
          _toolCallIdMeta,
          toolCallId.isAcceptableOrUnknown(
              data['tool_call_id']!, _toolCallIdMeta));
    }
    if (data.containsKey('tool_arguments')) {
      context.handle(
          _toolArgumentsMeta,
          toolArguments.isAcceptableOrUnknown(
              data['tool_arguments']!, _toolArgumentsMeta));
    }
    if (data.containsKey('tool_result')) {
      context.handle(
          _toolResultMeta,
          toolResult.isAcceptableOrUnknown(
              data['tool_result']!, _toolResultMeta));
    }
    if (data.containsKey('reasoning_content')) {
      context.handle(
          _reasoningContentMeta,
          reasoningContent.isAcceptableOrUnknown(
              data['reasoning_content']!, _reasoningContentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      role: $ChatMessagesTable.$converterrole.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      toolName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tool_name']),
      toolCallId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tool_call_id']),
      toolArguments: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tool_arguments']),
      toolResult: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tool_result']),
      reasoningContent: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reasoning_content']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChatRole, String, String> $converterrole =
      const EnumNameConverter<ChatRole>(ChatRole.values);
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final String? toolName;

  /// OpenAI 协议里 `role=tool` 的消息必须带 `tool_call_id`。
  final String? toolCallId;
  final String? toolArguments;
  final String? toolResult;

  /// 思考模型的内部推理（MiMo / DeepSeek-R1 的 `reasoning_content`）。
  /// 多轮工具调用时会原样回传给模型；界面默认不展示。
  final String? reasoningContent;
  final DateTime createdAt;
  const ChatMessageRow(
      {required this.id,
      required this.sessionId,
      required this.role,
      required this.content,
      this.toolName,
      this.toolCallId,
      this.toolArguments,
      this.toolResult,
      this.reasoningContent,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    {
      map['role'] =
          Variable<String>($ChatMessagesTable.$converterrole.toSql(role));
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || toolName != null) {
      map['tool_name'] = Variable<String>(toolName);
    }
    if (!nullToAbsent || toolCallId != null) {
      map['tool_call_id'] = Variable<String>(toolCallId);
    }
    if (!nullToAbsent || toolArguments != null) {
      map['tool_arguments'] = Variable<String>(toolArguments);
    }
    if (!nullToAbsent || toolResult != null) {
      map['tool_result'] = Variable<String>(toolResult);
    }
    if (!nullToAbsent || reasoningContent != null) {
      map['reasoning_content'] = Variable<String>(reasoningContent);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      role: Value(role),
      content: Value(content),
      toolName: toolName == null && nullToAbsent
          ? const Value.absent()
          : Value(toolName),
      toolCallId: toolCallId == null && nullToAbsent
          ? const Value.absent()
          : Value(toolCallId),
      toolArguments: toolArguments == null && nullToAbsent
          ? const Value.absent()
          : Value(toolArguments),
      toolResult: toolResult == null && nullToAbsent
          ? const Value.absent()
          : Value(toolResult),
      reasoningContent: reasoningContent == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoningContent),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessageRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      role: $ChatMessagesTable.$converterrole
          .fromJson(serializer.fromJson<String>(json['role'])),
      content: serializer.fromJson<String>(json['content']),
      toolName: serializer.fromJson<String?>(json['toolName']),
      toolCallId: serializer.fromJson<String?>(json['toolCallId']),
      toolArguments: serializer.fromJson<String?>(json['toolArguments']),
      toolResult: serializer.fromJson<String?>(json['toolResult']),
      reasoningContent: serializer.fromJson<String?>(json['reasoningContent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'role': serializer
          .toJson<String>($ChatMessagesTable.$converterrole.toJson(role)),
      'content': serializer.toJson<String>(content),
      'toolName': serializer.toJson<String?>(toolName),
      'toolCallId': serializer.toJson<String?>(toolCallId),
      'toolArguments': serializer.toJson<String?>(toolArguments),
      'toolResult': serializer.toJson<String?>(toolResult),
      'reasoningContent': serializer.toJson<String?>(reasoningContent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessageRow copyWith(
          {String? id,
          String? sessionId,
          ChatRole? role,
          String? content,
          Value<String?> toolName = const Value.absent(),
          Value<String?> toolCallId = const Value.absent(),
          Value<String?> toolArguments = const Value.absent(),
          Value<String?> toolResult = const Value.absent(),
          Value<String?> reasoningContent = const Value.absent(),
          DateTime? createdAt}) =>
      ChatMessageRow(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        role: role ?? this.role,
        content: content ?? this.content,
        toolName: toolName.present ? toolName.value : this.toolName,
        toolCallId: toolCallId.present ? toolCallId.value : this.toolCallId,
        toolArguments:
            toolArguments.present ? toolArguments.value : this.toolArguments,
        toolResult: toolResult.present ? toolResult.value : this.toolResult,
        reasoningContent: reasoningContent.present
            ? reasoningContent.value
            : this.reasoningContent,
        createdAt: createdAt ?? this.createdAt,
      );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      toolName: data.toolName.present ? data.toolName.value : this.toolName,
      toolCallId:
          data.toolCallId.present ? data.toolCallId.value : this.toolCallId,
      toolArguments: data.toolArguments.present
          ? data.toolArguments.value
          : this.toolArguments,
      toolResult:
          data.toolResult.present ? data.toolResult.value : this.toolResult,
      reasoningContent: data.reasoningContent.present
          ? data.reasoningContent.value
          : this.reasoningContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('toolName: $toolName, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolArguments: $toolArguments, ')
          ..write('toolResult: $toolResult, ')
          ..write('reasoningContent: $reasoningContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, role, content, toolName,
      toolCallId, toolArguments, toolResult, reasoningContent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.toolName == this.toolName &&
          other.toolCallId == this.toolCallId &&
          other.toolArguments == this.toolArguments &&
          other.toolResult == this.toolResult &&
          other.reasoningContent == this.reasoningContent &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<ChatRole> role;
  final Value<String> content;
  final Value<String?> toolName;
  final Value<String?> toolCallId;
  final Value<String?> toolArguments;
  final Value<String?> toolResult;
  final Value<String?> reasoningContent;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.toolName = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.toolArguments = const Value.absent(),
    this.toolResult = const Value.absent(),
    this.reasoningContent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required ChatRole role,
    required String content,
    this.toolName = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.toolArguments = const Value.absent(),
    this.toolResult = const Value.absent(),
    this.reasoningContent = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        role = Value(role),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? toolName,
    Expression<String>? toolCallId,
    Expression<String>? toolArguments,
    Expression<String>? toolResult,
    Expression<String>? reasoningContent,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (toolName != null) 'tool_name': toolName,
      if (toolCallId != null) 'tool_call_id': toolCallId,
      if (toolArguments != null) 'tool_arguments': toolArguments,
      if (toolResult != null) 'tool_result': toolResult,
      if (reasoningContent != null) 'reasoning_content': reasoningContent,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<ChatRole>? role,
      Value<String>? content,
      Value<String?>? toolName,
      Value<String?>? toolCallId,
      Value<String?>? toolArguments,
      Value<String?>? toolResult,
      Value<String?>? reasoningContent,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      toolName: toolName ?? this.toolName,
      toolCallId: toolCallId ?? this.toolCallId,
      toolArguments: toolArguments ?? this.toolArguments,
      toolResult: toolResult ?? this.toolResult,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (role.present) {
      map['role'] =
          Variable<String>($ChatMessagesTable.$converterrole.toSql(role.value));
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (toolName.present) {
      map['tool_name'] = Variable<String>(toolName.value);
    }
    if (toolCallId.present) {
      map['tool_call_id'] = Variable<String>(toolCallId.value);
    }
    if (toolArguments.present) {
      map['tool_arguments'] = Variable<String>(toolArguments.value);
    }
    if (toolResult.present) {
      map['tool_result'] = Variable<String>(toolResult.value);
    }
    if (reasoningContent.present) {
      map['reasoning_content'] = Variable<String>(reasoningContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('toolName: $toolName, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolArguments: $toolArguments, ')
          ..write('toolResult: $toolResult, ')
          ..write('reasoningContent: $reasoningContent, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ThemeConfigsTable extends ThemeConfigs
    with TableInfo<$ThemeConfigsTable, ThemeConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThemeConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _brightnessMeta =
      const VerificationMeta('brightness');
  @override
  late final GeneratedColumn<String> brightness = GeneratedColumn<String>(
      'brightness', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _primaryColorMeta =
      const VerificationMeta('primaryColor');
  @override
  late final GeneratedColumn<int> primaryColor = GeneratedColumn<int>(
      'primary_color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _secondaryColorMeta =
      const VerificationMeta('secondaryColor');
  @override
  late final GeneratedColumn<int> secondaryColor = GeneratedColumn<int>(
      'secondary_color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _backgroundColorMeta =
      const VerificationMeta('backgroundColor');
  @override
  late final GeneratedColumn<int> backgroundColor = GeneratedColumn<int>(
      'background_color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _surfaceColorMeta =
      const VerificationMeta('surfaceColor');
  @override
  late final GeneratedColumn<int> surfaceColor = GeneratedColumn<int>(
      'surface_color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _textColorMeta =
      const VerificationMeta('textColor');
  @override
  late final GeneratedColumn<int> textColor = GeneratedColumn<int>(
      'text_color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _borderRadiusMeta =
      const VerificationMeta('borderRadius');
  @override
  late final GeneratedColumn<double> borderRadius = GeneratedColumn<double>(
      'border_radius', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(18));
  static const VerificationMeta _cardOpacityMeta =
      const VerificationMeta('cardOpacity');
  @override
  late final GeneratedColumn<double> cardOpacity = GeneratedColumn<double>(
      'card_opacity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _blurAmountMeta =
      const VerificationMeta('blurAmount');
  @override
  late final GeneratedColumn<double> blurAmount = GeneratedColumn<double>(
      'blur_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fontScaleMeta =
      const VerificationMeta('fontScale');
  @override
  late final GeneratedColumn<double> fontScale = GeneratedColumn<double>(
      'font_scale', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _animationEnabledMeta =
      const VerificationMeta('animationEnabled');
  @override
  late final GeneratedColumn<bool> animationEnabled = GeneratedColumn<bool>(
      'animation_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("animation_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _shadowStrengthMeta =
      const VerificationMeta('shadowStrength');
  @override
  late final GeneratedColumn<double> shadowStrength = GeneratedColumn<double>(
      'shadow_strength', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.35));
  static const VerificationMeta _navigationBarColorMeta =
      const VerificationMeta('navigationBarColor');
  @override
  late final GeneratedColumn<int> navigationBarColor = GeneratedColumn<int>(
      'navigation_bar_color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sidebarColorMeta =
      const VerificationMeta('sidebarColor');
  @override
  late final GeneratedColumn<int> sidebarColor = GeneratedColumn<int>(
      'sidebar_color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _eventColorMeta =
      const VerificationMeta('eventColor');
  @override
  late final GeneratedColumn<int> eventColor = GeneratedColumn<int>(
      'event_color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _countdownColorMeta =
      const VerificationMeta('countdownColor');
  @override
  late final GeneratedColumn<int> countdownColor = GeneratedColumn<int>(
      'countdown_color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        brightness,
        primaryColor,
        secondaryColor,
        backgroundColor,
        surfaceColor,
        textColor,
        borderRadius,
        cardOpacity,
        blurAmount,
        fontScale,
        animationEnabled,
        shadowStrength,
        navigationBarColor,
        sidebarColor,
        eventColor,
        countdownColor,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'theme_configs';
  @override
  VerificationContext validateIntegrity(Insertable<ThemeConfigRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brightness')) {
      context.handle(
          _brightnessMeta,
          brightness.isAcceptableOrUnknown(
              data['brightness']!, _brightnessMeta));
    } else if (isInserting) {
      context.missing(_brightnessMeta);
    }
    if (data.containsKey('primary_color')) {
      context.handle(
          _primaryColorMeta,
          primaryColor.isAcceptableOrUnknown(
              data['primary_color']!, _primaryColorMeta));
    } else if (isInserting) {
      context.missing(_primaryColorMeta);
    }
    if (data.containsKey('secondary_color')) {
      context.handle(
          _secondaryColorMeta,
          secondaryColor.isAcceptableOrUnknown(
              data['secondary_color']!, _secondaryColorMeta));
    } else if (isInserting) {
      context.missing(_secondaryColorMeta);
    }
    if (data.containsKey('background_color')) {
      context.handle(
          _backgroundColorMeta,
          backgroundColor.isAcceptableOrUnknown(
              data['background_color']!, _backgroundColorMeta));
    } else if (isInserting) {
      context.missing(_backgroundColorMeta);
    }
    if (data.containsKey('surface_color')) {
      context.handle(
          _surfaceColorMeta,
          surfaceColor.isAcceptableOrUnknown(
              data['surface_color']!, _surfaceColorMeta));
    } else if (isInserting) {
      context.missing(_surfaceColorMeta);
    }
    if (data.containsKey('text_color')) {
      context.handle(_textColorMeta,
          textColor.isAcceptableOrUnknown(data['text_color']!, _textColorMeta));
    } else if (isInserting) {
      context.missing(_textColorMeta);
    }
    if (data.containsKey('border_radius')) {
      context.handle(
          _borderRadiusMeta,
          borderRadius.isAcceptableOrUnknown(
              data['border_radius']!, _borderRadiusMeta));
    }
    if (data.containsKey('card_opacity')) {
      context.handle(
          _cardOpacityMeta,
          cardOpacity.isAcceptableOrUnknown(
              data['card_opacity']!, _cardOpacityMeta));
    }
    if (data.containsKey('blur_amount')) {
      context.handle(
          _blurAmountMeta,
          blurAmount.isAcceptableOrUnknown(
              data['blur_amount']!, _blurAmountMeta));
    }
    if (data.containsKey('font_scale')) {
      context.handle(_fontScaleMeta,
          fontScale.isAcceptableOrUnknown(data['font_scale']!, _fontScaleMeta));
    }
    if (data.containsKey('animation_enabled')) {
      context.handle(
          _animationEnabledMeta,
          animationEnabled.isAcceptableOrUnknown(
              data['animation_enabled']!, _animationEnabledMeta));
    }
    if (data.containsKey('shadow_strength')) {
      context.handle(
          _shadowStrengthMeta,
          shadowStrength.isAcceptableOrUnknown(
              data['shadow_strength']!, _shadowStrengthMeta));
    }
    if (data.containsKey('navigation_bar_color')) {
      context.handle(
          _navigationBarColorMeta,
          navigationBarColor.isAcceptableOrUnknown(
              data['navigation_bar_color']!, _navigationBarColorMeta));
    }
    if (data.containsKey('sidebar_color')) {
      context.handle(
          _sidebarColorMeta,
          sidebarColor.isAcceptableOrUnknown(
              data['sidebar_color']!, _sidebarColorMeta));
    }
    if (data.containsKey('event_color')) {
      context.handle(
          _eventColorMeta,
          eventColor.isAcceptableOrUnknown(
              data['event_color']!, _eventColorMeta));
    }
    if (data.containsKey('countdown_color')) {
      context.handle(
          _countdownColorMeta,
          countdownColor.isAcceptableOrUnknown(
              data['countdown_color']!, _countdownColorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ThemeConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThemeConfigRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      brightness: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brightness'])!,
      primaryColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}primary_color'])!,
      secondaryColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}secondary_color'])!,
      backgroundColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}background_color'])!,
      surfaceColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surface_color'])!,
      textColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}text_color'])!,
      borderRadius: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}border_radius'])!,
      cardOpacity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}card_opacity'])!,
      blurAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}blur_amount'])!,
      fontScale: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}font_scale'])!,
      animationEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}animation_enabled'])!,
      shadowStrength: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}shadow_strength'])!,
      navigationBarColor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}navigation_bar_color']),
      sidebarColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sidebar_color']),
      eventColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}event_color']),
      countdownColor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}countdown_color']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ThemeConfigsTable createAlias(String alias) {
    return $ThemeConfigsTable(attachedDatabase, alias);
  }
}

class ThemeConfigRow extends DataClass implements Insertable<ThemeConfigRow> {
  final String id;
  final String name;

  /// light / dark，避免数据库层依赖 Flutter 的 Brightness。
  final String brightness;
  final int primaryColor;
  final int secondaryColor;
  final int backgroundColor;
  final int surfaceColor;
  final int textColor;
  final double borderRadius;
  final double cardOpacity;
  final double blurAmount;
  final double fontScale;
  final bool animationEnabled;

  /// 阴影强度（0-1）。
  final double shadowStrength;

  /// 区域配色（可空）：导航栏 / 侧边栏 / 日历事件默认色 / 倒计时默认色。
  final int? navigationBarColor;
  final int? sidebarColor;
  final int? eventColor;
  final int? countdownColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ThemeConfigRow(
      {required this.id,
      required this.name,
      required this.brightness,
      required this.primaryColor,
      required this.secondaryColor,
      required this.backgroundColor,
      required this.surfaceColor,
      required this.textColor,
      required this.borderRadius,
      required this.cardOpacity,
      required this.blurAmount,
      required this.fontScale,
      required this.animationEnabled,
      required this.shadowStrength,
      this.navigationBarColor,
      this.sidebarColor,
      this.eventColor,
      this.countdownColor,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['brightness'] = Variable<String>(brightness);
    map['primary_color'] = Variable<int>(primaryColor);
    map['secondary_color'] = Variable<int>(secondaryColor);
    map['background_color'] = Variable<int>(backgroundColor);
    map['surface_color'] = Variable<int>(surfaceColor);
    map['text_color'] = Variable<int>(textColor);
    map['border_radius'] = Variable<double>(borderRadius);
    map['card_opacity'] = Variable<double>(cardOpacity);
    map['blur_amount'] = Variable<double>(blurAmount);
    map['font_scale'] = Variable<double>(fontScale);
    map['animation_enabled'] = Variable<bool>(animationEnabled);
    map['shadow_strength'] = Variable<double>(shadowStrength);
    if (!nullToAbsent || navigationBarColor != null) {
      map['navigation_bar_color'] = Variable<int>(navigationBarColor);
    }
    if (!nullToAbsent || sidebarColor != null) {
      map['sidebar_color'] = Variable<int>(sidebarColor);
    }
    if (!nullToAbsent || eventColor != null) {
      map['event_color'] = Variable<int>(eventColor);
    }
    if (!nullToAbsent || countdownColor != null) {
      map['countdown_color'] = Variable<int>(countdownColor);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ThemeConfigsCompanion toCompanion(bool nullToAbsent) {
    return ThemeConfigsCompanion(
      id: Value(id),
      name: Value(name),
      brightness: Value(brightness),
      primaryColor: Value(primaryColor),
      secondaryColor: Value(secondaryColor),
      backgroundColor: Value(backgroundColor),
      surfaceColor: Value(surfaceColor),
      textColor: Value(textColor),
      borderRadius: Value(borderRadius),
      cardOpacity: Value(cardOpacity),
      blurAmount: Value(blurAmount),
      fontScale: Value(fontScale),
      animationEnabled: Value(animationEnabled),
      shadowStrength: Value(shadowStrength),
      navigationBarColor: navigationBarColor == null && nullToAbsent
          ? const Value.absent()
          : Value(navigationBarColor),
      sidebarColor: sidebarColor == null && nullToAbsent
          ? const Value.absent()
          : Value(sidebarColor),
      eventColor: eventColor == null && nullToAbsent
          ? const Value.absent()
          : Value(eventColor),
      countdownColor: countdownColor == null && nullToAbsent
          ? const Value.absent()
          : Value(countdownColor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ThemeConfigRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThemeConfigRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brightness: serializer.fromJson<String>(json['brightness']),
      primaryColor: serializer.fromJson<int>(json['primaryColor']),
      secondaryColor: serializer.fromJson<int>(json['secondaryColor']),
      backgroundColor: serializer.fromJson<int>(json['backgroundColor']),
      surfaceColor: serializer.fromJson<int>(json['surfaceColor']),
      textColor: serializer.fromJson<int>(json['textColor']),
      borderRadius: serializer.fromJson<double>(json['borderRadius']),
      cardOpacity: serializer.fromJson<double>(json['cardOpacity']),
      blurAmount: serializer.fromJson<double>(json['blurAmount']),
      fontScale: serializer.fromJson<double>(json['fontScale']),
      animationEnabled: serializer.fromJson<bool>(json['animationEnabled']),
      shadowStrength: serializer.fromJson<double>(json['shadowStrength']),
      navigationBarColor: serializer.fromJson<int?>(json['navigationBarColor']),
      sidebarColor: serializer.fromJson<int?>(json['sidebarColor']),
      eventColor: serializer.fromJson<int?>(json['eventColor']),
      countdownColor: serializer.fromJson<int?>(json['countdownColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'brightness': serializer.toJson<String>(brightness),
      'primaryColor': serializer.toJson<int>(primaryColor),
      'secondaryColor': serializer.toJson<int>(secondaryColor),
      'backgroundColor': serializer.toJson<int>(backgroundColor),
      'surfaceColor': serializer.toJson<int>(surfaceColor),
      'textColor': serializer.toJson<int>(textColor),
      'borderRadius': serializer.toJson<double>(borderRadius),
      'cardOpacity': serializer.toJson<double>(cardOpacity),
      'blurAmount': serializer.toJson<double>(blurAmount),
      'fontScale': serializer.toJson<double>(fontScale),
      'animationEnabled': serializer.toJson<bool>(animationEnabled),
      'shadowStrength': serializer.toJson<double>(shadowStrength),
      'navigationBarColor': serializer.toJson<int?>(navigationBarColor),
      'sidebarColor': serializer.toJson<int?>(sidebarColor),
      'eventColor': serializer.toJson<int?>(eventColor),
      'countdownColor': serializer.toJson<int?>(countdownColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ThemeConfigRow copyWith(
          {String? id,
          String? name,
          String? brightness,
          int? primaryColor,
          int? secondaryColor,
          int? backgroundColor,
          int? surfaceColor,
          int? textColor,
          double? borderRadius,
          double? cardOpacity,
          double? blurAmount,
          double? fontScale,
          bool? animationEnabled,
          double? shadowStrength,
          Value<int?> navigationBarColor = const Value.absent(),
          Value<int?> sidebarColor = const Value.absent(),
          Value<int?> eventColor = const Value.absent(),
          Value<int?> countdownColor = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ThemeConfigRow(
        id: id ?? this.id,
        name: name ?? this.name,
        brightness: brightness ?? this.brightness,
        primaryColor: primaryColor ?? this.primaryColor,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        surfaceColor: surfaceColor ?? this.surfaceColor,
        textColor: textColor ?? this.textColor,
        borderRadius: borderRadius ?? this.borderRadius,
        cardOpacity: cardOpacity ?? this.cardOpacity,
        blurAmount: blurAmount ?? this.blurAmount,
        fontScale: fontScale ?? this.fontScale,
        animationEnabled: animationEnabled ?? this.animationEnabled,
        shadowStrength: shadowStrength ?? this.shadowStrength,
        navigationBarColor: navigationBarColor.present
            ? navigationBarColor.value
            : this.navigationBarColor,
        sidebarColor:
            sidebarColor.present ? sidebarColor.value : this.sidebarColor,
        eventColor: eventColor.present ? eventColor.value : this.eventColor,
        countdownColor:
            countdownColor.present ? countdownColor.value : this.countdownColor,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ThemeConfigRow copyWithCompanion(ThemeConfigsCompanion data) {
    return ThemeConfigRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brightness:
          data.brightness.present ? data.brightness.value : this.brightness,
      primaryColor: data.primaryColor.present
          ? data.primaryColor.value
          : this.primaryColor,
      secondaryColor: data.secondaryColor.present
          ? data.secondaryColor.value
          : this.secondaryColor,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      surfaceColor: data.surfaceColor.present
          ? data.surfaceColor.value
          : this.surfaceColor,
      textColor: data.textColor.present ? data.textColor.value : this.textColor,
      borderRadius: data.borderRadius.present
          ? data.borderRadius.value
          : this.borderRadius,
      cardOpacity:
          data.cardOpacity.present ? data.cardOpacity.value : this.cardOpacity,
      blurAmount:
          data.blurAmount.present ? data.blurAmount.value : this.blurAmount,
      fontScale: data.fontScale.present ? data.fontScale.value : this.fontScale,
      animationEnabled: data.animationEnabled.present
          ? data.animationEnabled.value
          : this.animationEnabled,
      shadowStrength: data.shadowStrength.present
          ? data.shadowStrength.value
          : this.shadowStrength,
      navigationBarColor: data.navigationBarColor.present
          ? data.navigationBarColor.value
          : this.navigationBarColor,
      sidebarColor: data.sidebarColor.present
          ? data.sidebarColor.value
          : this.sidebarColor,
      eventColor:
          data.eventColor.present ? data.eventColor.value : this.eventColor,
      countdownColor: data.countdownColor.present
          ? data.countdownColor.value
          : this.countdownColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThemeConfigRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brightness: $brightness, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('secondaryColor: $secondaryColor, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('surfaceColor: $surfaceColor, ')
          ..write('textColor: $textColor, ')
          ..write('borderRadius: $borderRadius, ')
          ..write('cardOpacity: $cardOpacity, ')
          ..write('blurAmount: $blurAmount, ')
          ..write('fontScale: $fontScale, ')
          ..write('animationEnabled: $animationEnabled, ')
          ..write('shadowStrength: $shadowStrength, ')
          ..write('navigationBarColor: $navigationBarColor, ')
          ..write('sidebarColor: $sidebarColor, ')
          ..write('eventColor: $eventColor, ')
          ..write('countdownColor: $countdownColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      brightness,
      primaryColor,
      secondaryColor,
      backgroundColor,
      surfaceColor,
      textColor,
      borderRadius,
      cardOpacity,
      blurAmount,
      fontScale,
      animationEnabled,
      shadowStrength,
      navigationBarColor,
      sidebarColor,
      eventColor,
      countdownColor,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThemeConfigRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.brightness == this.brightness &&
          other.primaryColor == this.primaryColor &&
          other.secondaryColor == this.secondaryColor &&
          other.backgroundColor == this.backgroundColor &&
          other.surfaceColor == this.surfaceColor &&
          other.textColor == this.textColor &&
          other.borderRadius == this.borderRadius &&
          other.cardOpacity == this.cardOpacity &&
          other.blurAmount == this.blurAmount &&
          other.fontScale == this.fontScale &&
          other.animationEnabled == this.animationEnabled &&
          other.shadowStrength == this.shadowStrength &&
          other.navigationBarColor == this.navigationBarColor &&
          other.sidebarColor == this.sidebarColor &&
          other.eventColor == this.eventColor &&
          other.countdownColor == this.countdownColor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ThemeConfigsCompanion extends UpdateCompanion<ThemeConfigRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> brightness;
  final Value<int> primaryColor;
  final Value<int> secondaryColor;
  final Value<int> backgroundColor;
  final Value<int> surfaceColor;
  final Value<int> textColor;
  final Value<double> borderRadius;
  final Value<double> cardOpacity;
  final Value<double> blurAmount;
  final Value<double> fontScale;
  final Value<bool> animationEnabled;
  final Value<double> shadowStrength;
  final Value<int?> navigationBarColor;
  final Value<int?> sidebarColor;
  final Value<int?> eventColor;
  final Value<int?> countdownColor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ThemeConfigsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brightness = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.secondaryColor = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.surfaceColor = const Value.absent(),
    this.textColor = const Value.absent(),
    this.borderRadius = const Value.absent(),
    this.cardOpacity = const Value.absent(),
    this.blurAmount = const Value.absent(),
    this.fontScale = const Value.absent(),
    this.animationEnabled = const Value.absent(),
    this.shadowStrength = const Value.absent(),
    this.navigationBarColor = const Value.absent(),
    this.sidebarColor = const Value.absent(),
    this.eventColor = const Value.absent(),
    this.countdownColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThemeConfigsCompanion.insert({
    required String id,
    required String name,
    required String brightness,
    required int primaryColor,
    required int secondaryColor,
    required int backgroundColor,
    required int surfaceColor,
    required int textColor,
    this.borderRadius = const Value.absent(),
    this.cardOpacity = const Value.absent(),
    this.blurAmount = const Value.absent(),
    this.fontScale = const Value.absent(),
    this.animationEnabled = const Value.absent(),
    this.shadowStrength = const Value.absent(),
    this.navigationBarColor = const Value.absent(),
    this.sidebarColor = const Value.absent(),
    this.eventColor = const Value.absent(),
    this.countdownColor = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        brightness = Value(brightness),
        primaryColor = Value(primaryColor),
        secondaryColor = Value(secondaryColor),
        backgroundColor = Value(backgroundColor),
        surfaceColor = Value(surfaceColor),
        textColor = Value(textColor),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ThemeConfigRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? brightness,
    Expression<int>? primaryColor,
    Expression<int>? secondaryColor,
    Expression<int>? backgroundColor,
    Expression<int>? surfaceColor,
    Expression<int>? textColor,
    Expression<double>? borderRadius,
    Expression<double>? cardOpacity,
    Expression<double>? blurAmount,
    Expression<double>? fontScale,
    Expression<bool>? animationEnabled,
    Expression<double>? shadowStrength,
    Expression<int>? navigationBarColor,
    Expression<int>? sidebarColor,
    Expression<int>? eventColor,
    Expression<int>? countdownColor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brightness != null) 'brightness': brightness,
      if (primaryColor != null) 'primary_color': primaryColor,
      if (secondaryColor != null) 'secondary_color': secondaryColor,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (surfaceColor != null) 'surface_color': surfaceColor,
      if (textColor != null) 'text_color': textColor,
      if (borderRadius != null) 'border_radius': borderRadius,
      if (cardOpacity != null) 'card_opacity': cardOpacity,
      if (blurAmount != null) 'blur_amount': blurAmount,
      if (fontScale != null) 'font_scale': fontScale,
      if (animationEnabled != null) 'animation_enabled': animationEnabled,
      if (shadowStrength != null) 'shadow_strength': shadowStrength,
      if (navigationBarColor != null)
        'navigation_bar_color': navigationBarColor,
      if (sidebarColor != null) 'sidebar_color': sidebarColor,
      if (eventColor != null) 'event_color': eventColor,
      if (countdownColor != null) 'countdown_color': countdownColor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThemeConfigsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? brightness,
      Value<int>? primaryColor,
      Value<int>? secondaryColor,
      Value<int>? backgroundColor,
      Value<int>? surfaceColor,
      Value<int>? textColor,
      Value<double>? borderRadius,
      Value<double>? cardOpacity,
      Value<double>? blurAmount,
      Value<double>? fontScale,
      Value<bool>? animationEnabled,
      Value<double>? shadowStrength,
      Value<int?>? navigationBarColor,
      Value<int?>? sidebarColor,
      Value<int?>? eventColor,
      Value<int?>? countdownColor,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ThemeConfigsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      borderRadius: borderRadius ?? this.borderRadius,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      blurAmount: blurAmount ?? this.blurAmount,
      fontScale: fontScale ?? this.fontScale,
      animationEnabled: animationEnabled ?? this.animationEnabled,
      shadowStrength: shadowStrength ?? this.shadowStrength,
      navigationBarColor: navigationBarColor ?? this.navigationBarColor,
      sidebarColor: sidebarColor ?? this.sidebarColor,
      eventColor: eventColor ?? this.eventColor,
      countdownColor: countdownColor ?? this.countdownColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brightness.present) {
      map['brightness'] = Variable<String>(brightness.value);
    }
    if (primaryColor.present) {
      map['primary_color'] = Variable<int>(primaryColor.value);
    }
    if (secondaryColor.present) {
      map['secondary_color'] = Variable<int>(secondaryColor.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<int>(backgroundColor.value);
    }
    if (surfaceColor.present) {
      map['surface_color'] = Variable<int>(surfaceColor.value);
    }
    if (textColor.present) {
      map['text_color'] = Variable<int>(textColor.value);
    }
    if (borderRadius.present) {
      map['border_radius'] = Variable<double>(borderRadius.value);
    }
    if (cardOpacity.present) {
      map['card_opacity'] = Variable<double>(cardOpacity.value);
    }
    if (blurAmount.present) {
      map['blur_amount'] = Variable<double>(blurAmount.value);
    }
    if (fontScale.present) {
      map['font_scale'] = Variable<double>(fontScale.value);
    }
    if (animationEnabled.present) {
      map['animation_enabled'] = Variable<bool>(animationEnabled.value);
    }
    if (shadowStrength.present) {
      map['shadow_strength'] = Variable<double>(shadowStrength.value);
    }
    if (navigationBarColor.present) {
      map['navigation_bar_color'] = Variable<int>(navigationBarColor.value);
    }
    if (sidebarColor.present) {
      map['sidebar_color'] = Variable<int>(sidebarColor.value);
    }
    if (eventColor.present) {
      map['event_color'] = Variable<int>(eventColor.value);
    }
    if (countdownColor.present) {
      map['countdown_color'] = Variable<int>(countdownColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThemeConfigsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brightness: $brightness, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('secondaryColor: $secondaryColor, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('surfaceColor: $surfaceColor, ')
          ..write('textColor: $textColor, ')
          ..write('borderRadius: $borderRadius, ')
          ..write('cardOpacity: $cardOpacity, ')
          ..write('blurAmount: $blurAmount, ')
          ..write('fontScale: $fontScale, ')
          ..write('animationEnabled: $animationEnabled, ')
          ..write('shadowStrength: $shadowStrength, ')
          ..write('navigationBarColor: $navigationBarColor, ')
          ..write('sidebarColor: $sidebarColor, ')
          ..write('eventColor: $eventColor, ')
          ..write('countdownColor: $countdownColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyDigestsTable extends DailyDigests
    with TableInfo<$DailyDigestsTable, DailyDigestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyDigestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
      'day_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, kind, dayKey, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_digests';
  @override
  VerificationContext validateIntegrity(Insertable<DailyDigestRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(_dayKeyMeta,
          dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta));
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyDigestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyDigestRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      dayKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_key'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DailyDigestsTable createAlias(String alias) {
    return $DailyDigestsTable(attachedDatabase, alias);
  }
}

class DailyDigestRow extends DataClass implements Insertable<DailyDigestRow> {
  final String id;
  final String kind;
  final String dayKey;
  final String content;
  final DateTime createdAt;
  const DailyDigestRow(
      {required this.id,
      required this.kind,
      required this.dayKey,
      required this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['day_key'] = Variable<String>(dayKey);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyDigestsCompanion toCompanion(bool nullToAbsent) {
    return DailyDigestsCompanion(
      id: Value(id),
      kind: Value(kind),
      dayKey: Value(dayKey),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory DailyDigestRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyDigestRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'dayKey': serializer.toJson<String>(dayKey),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyDigestRow copyWith(
          {String? id,
          String? kind,
          String? dayKey,
          String? content,
          DateTime? createdAt}) =>
      DailyDigestRow(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        dayKey: dayKey ?? this.dayKey,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  DailyDigestRow copyWithCompanion(DailyDigestsCompanion data) {
    return DailyDigestRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyDigestRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('dayKey: $dayKey, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, dayKey, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyDigestRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.dayKey == this.dayKey &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class DailyDigestsCompanion extends UpdateCompanion<DailyDigestRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> dayKey;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DailyDigestsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyDigestsCompanion.insert({
    required String id,
    required String kind,
    required String dayKey,
    required String content,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        dayKey = Value(dayKey),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<DailyDigestRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? dayKey,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (dayKey != null) 'day_key': dayKey,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyDigestsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String>? dayKey,
      Value<String>? content,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DailyDigestsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      dayKey: dayKey ?? this.dayKey,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyDigestsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('dayKey: $dayKey, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CalendarCategoriesTable calendarCategories =
      $CalendarCategoriesTable(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $CountdownsTable countdowns = $CountdownsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $AiPersonasTable aiPersonas = $AiPersonasTable(this);
  late final $AiProvidersTable aiProviders = $AiProvidersTable(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $ThemeConfigsTable themeConfigs = $ThemeConfigsTable(this);
  late final $DailyDigestsTable dailyDigests = $DailyDigestsTable(this);
  late final Index idxEventsStartTime = Index('idx_events_start_time',
      'CREATE INDEX idx_events_start_time ON calendar_events (start_time)');
  late final Index idxCountdownsTargetTime = Index('idx_countdowns_target_time',
      'CREATE INDEX idx_countdowns_target_time ON countdowns (target_time)');
  late final Index idxRemindersTriggerTime = Index('idx_reminders_trigger_time',
      'CREATE INDEX idx_reminders_trigger_time ON reminders (trigger_time)');
  late final Index idxChatMessagesSession = Index('idx_chat_messages_session',
      'CREATE INDEX idx_chat_messages_session ON chat_messages (session_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        calendarCategories,
        calendarEvents,
        countdowns,
        reminders,
        aiPersonas,
        aiProviders,
        chatSessions,
        chatMessages,
        themeConfigs,
        dailyDigests,
        idxEventsStartTime,
        idxCountdownsTargetTime,
        idxRemindersTriggerTime,
        idxChatMessagesSession
      ];
}

typedef $$CalendarCategoriesTableCreateCompanionBuilder
    = CalendarCategoriesCompanion Function({
  required String id,
  required String name,
  required int color,
  Value<String?> icon,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CalendarCategoriesTableUpdateCompanionBuilder
    = CalendarCategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> color,
  Value<String?> icon,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CalendarCategoriesTableReferences extends BaseReferences<
    _$AppDatabase, $CalendarCategoriesTable, CalendarCategoryRow> {
  $$CalendarCategoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEventRow>>
      _calendarEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.calendarEvents,
              aliasName: $_aliasNameGenerator(
                  db.calendarCategories.id, db.calendarEvents.categoryId));

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager($_db, $_db.calendarEvents)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CalendarCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarCategoriesTable> {
  $$CalendarCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> calendarEventsRefs(
      Expression<bool> Function($$CalendarEventsTableFilterComposer f) f) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableFilterComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CalendarCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarCategoriesTable> {
  $$CalendarCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CalendarCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarCategoriesTable> {
  $$CalendarCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> calendarEventsRefs<T extends Object>(
      Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CalendarCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalendarCategoriesTable,
    CalendarCategoryRow,
    $$CalendarCategoriesTableFilterComposer,
    $$CalendarCategoriesTableOrderingComposer,
    $$CalendarCategoriesTableAnnotationComposer,
    $$CalendarCategoriesTableCreateCompanionBuilder,
    $$CalendarCategoriesTableUpdateCompanionBuilder,
    (CalendarCategoryRow, $$CalendarCategoriesTableReferences),
    CalendarCategoryRow,
    PrefetchHooks Function({bool calendarEventsRefs})> {
  $$CalendarCategoriesTableTableManager(
      _$AppDatabase db, $CalendarCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarCategoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarCategoriesCompanion(
            id: id,
            name: name,
            color: color,
            icon: icon,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int color,
            Value<String?> icon = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarCategoriesCompanion.insert(
            id: id,
            name: name,
            color: color,
            icon: icon,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CalendarCategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({calendarEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (calendarEventsRefs) db.calendarEvents
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (calendarEventsRefs)
                    await $_getPrefetchedData<CalendarCategoryRow,
                            $CalendarCategoriesTable, CalendarEventRow>(
                        currentTable: table,
                        referencedTable: $$CalendarCategoriesTableReferences
                            ._calendarEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CalendarCategoriesTableReferences(db, table, p0)
                                .calendarEventsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CalendarCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalendarCategoriesTable,
    CalendarCategoryRow,
    $$CalendarCategoriesTableFilterComposer,
    $$CalendarCategoriesTableOrderingComposer,
    $$CalendarCategoriesTableAnnotationComposer,
    $$CalendarCategoriesTableCreateCompanionBuilder,
    $$CalendarCategoriesTableUpdateCompanionBuilder,
    (CalendarCategoryRow, $$CalendarCategoriesTableReferences),
    CalendarCategoryRow,
    PrefetchHooks Function({bool calendarEventsRefs})>;
typedef $$CalendarEventsTableCreateCompanionBuilder = CalendarEventsCompanion
    Function({
  required String id,
  required String title,
  Value<String?> description,
  required DateTime startTime,
  required DateTime endTime,
  Value<bool> allDay,
  Value<String?> location,
  Value<String?> categoryId,
  Value<int?> color,
  Value<String?> repeatRule,
  Value<DateTime?> repeatUntil,
  Value<int?> reminderMinutes,
  required EventStatus status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CalendarEventsTableUpdateCompanionBuilder = CalendarEventsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<bool> allDay,
  Value<String?> location,
  Value<String?> categoryId,
  Value<int?> color,
  Value<String?> repeatRule,
  Value<DateTime?> repeatUntil,
  Value<int?> reminderMinutes,
  Value<EventStatus> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CalendarEventsTableReferences extends BaseReferences<
    _$AppDatabase, $CalendarEventsTable, CalendarEventRow> {
  $$CalendarEventsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CalendarCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.calendarCategories.createAlias($_aliasNameGenerator(
          db.calendarEvents.categoryId, db.calendarCategories.id));

  $$CalendarCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager =
        $$CalendarCategoriesTableTableManager($_db, $_db.calendarCategories)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RemindersTable, List<ReminderRow>>
      _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.reminders,
          aliasName:
              $_aliasNameGenerator(db.calendarEvents.id, db.reminders.eventId));

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager($_db, $_db.reminders)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get repeatUntil => $composableBuilder(
      column: $table.repeatUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<EventStatus, EventStatus, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$CalendarCategoriesTableFilterComposer get categoryId {
    final $$CalendarCategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.calendarCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarCategoriesTableFilterComposer(
              $db: $db,
              $table: $db.calendarCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> remindersRefs(
      Expression<bool> Function($$RemindersTableFilterComposer f) f) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableFilterComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get repeatUntil => $composableBuilder(
      column: $table.repeatUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$CalendarCategoriesTableOrderingComposer get categoryId {
    final $$CalendarCategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.calendarCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarCategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.calendarCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => column);

  GeneratedColumn<DateTime> get repeatUntil => $composableBuilder(
      column: $table.repeatUntil, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
      column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CalendarCategoriesTableAnnotationComposer get categoryId {
    final $$CalendarCategoriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $db.calendarCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CalendarCategoriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.calendarCategories,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  Expression<T> remindersRefs<T extends Object>(
      Expression<T> Function($$RemindersTableAnnotationComposer a) f) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableAnnotationComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CalendarEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalendarEventsTable,
    CalendarEventRow,
    $$CalendarEventsTableFilterComposer,
    $$CalendarEventsTableOrderingComposer,
    $$CalendarEventsTableAnnotationComposer,
    $$CalendarEventsTableCreateCompanionBuilder,
    $$CalendarEventsTableUpdateCompanionBuilder,
    (CalendarEventRow, $$CalendarEventsTableReferences),
    CalendarEventRow,
    PrefetchHooks Function({bool categoryId, bool remindersRefs})> {
  $$CalendarEventsTableTableManager(
      _$AppDatabase db, $CalendarEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<bool> allDay = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<DateTime?> repeatUntil = const Value.absent(),
            Value<int?> reminderMinutes = const Value.absent(),
            Value<EventStatus> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarEventsCompanion(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            location: location,
            categoryId: categoryId,
            color: color,
            repeatRule: repeatRule,
            repeatUntil: repeatUntil,
            reminderMinutes: reminderMinutes,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required DateTime startTime,
            required DateTime endTime,
            Value<bool> allDay = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<DateTime?> repeatUntil = const Value.absent(),
            Value<int?> reminderMinutes = const Value.absent(),
            required EventStatus status,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarEventsCompanion.insert(
            id: id,
            title: title,
            description: description,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            location: location,
            categoryId: categoryId,
            color: color,
            repeatRule: repeatRule,
            repeatUntil: repeatUntil,
            reminderMinutes: reminderMinutes,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CalendarEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false, remindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (remindersRefs) db.reminders],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$CalendarEventsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$CalendarEventsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (remindersRefs)
                    await $_getPrefetchedData<CalendarEventRow,
                            $CalendarEventsTable, ReminderRow>(
                        currentTable: table,
                        referencedTable: $$CalendarEventsTableReferences
                            ._remindersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CalendarEventsTableReferences(db, table, p0)
                                .remindersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.eventId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CalendarEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalendarEventsTable,
    CalendarEventRow,
    $$CalendarEventsTableFilterComposer,
    $$CalendarEventsTableOrderingComposer,
    $$CalendarEventsTableAnnotationComposer,
    $$CalendarEventsTableCreateCompanionBuilder,
    $$CalendarEventsTableUpdateCompanionBuilder,
    (CalendarEventRow, $$CalendarEventsTableReferences),
    CalendarEventRow,
    PrefetchHooks Function({bool categoryId, bool remindersRefs})>;
typedef $$CountdownsTableCreateCompanionBuilder = CountdownsCompanion Function({
  required String id,
  required String title,
  required DateTime targetTime,
  Value<String?> description,
  Value<int?> color,
  Value<int?> backgroundColor,
  Value<String?> icon,
  Value<bool> isPinned,
  required CountdownDisplayStyle displayStyle,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CountdownsTableUpdateCompanionBuilder = CountdownsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<DateTime> targetTime,
  Value<String?> description,
  Value<int?> color,
  Value<int?> backgroundColor,
  Value<String?> icon,
  Value<bool> isPinned,
  Value<CountdownDisplayStyle> displayStyle,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CountdownsTableFilterComposer
    extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get targetTime => $composableBuilder(
      column: $table.targetTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CountdownDisplayStyle, CountdownDisplayStyle,
          String>
      get displayStyle => $composableBuilder(
          column: $table.displayStyle,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CountdownsTableOrderingComposer
    extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetTime => $composableBuilder(
      column: $table.targetTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayStyle => $composableBuilder(
      column: $table.displayStyle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CountdownsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get targetTime => $composableBuilder(
      column: $table.targetTime, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CountdownDisplayStyle, String>
      get displayStyle => $composableBuilder(
          column: $table.displayStyle, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CountdownsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CountdownsTable,
    CountdownRow,
    $$CountdownsTableFilterComposer,
    $$CountdownsTableOrderingComposer,
    $$CountdownsTableAnnotationComposer,
    $$CountdownsTableCreateCompanionBuilder,
    $$CountdownsTableUpdateCompanionBuilder,
    (
      CountdownRow,
      BaseReferences<_$AppDatabase, $CountdownsTable, CountdownRow>
    ),
    CountdownRow,
    PrefetchHooks Function()> {
  $$CountdownsTableTableManager(_$AppDatabase db, $CountdownsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountdownsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CountdownsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CountdownsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> targetTime = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<int?> backgroundColor = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<CountdownDisplayStyle> displayStyle = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CountdownsCompanion(
            id: id,
            title: title,
            targetTime: targetTime,
            description: description,
            color: color,
            backgroundColor: backgroundColor,
            icon: icon,
            isPinned: isPinned,
            displayStyle: displayStyle,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required DateTime targetTime,
            Value<String?> description = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<int?> backgroundColor = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            required CountdownDisplayStyle displayStyle,
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CountdownsCompanion.insert(
            id: id,
            title: title,
            targetTime: targetTime,
            description: description,
            color: color,
            backgroundColor: backgroundColor,
            icon: icon,
            isPinned: isPinned,
            displayStyle: displayStyle,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CountdownsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CountdownsTable,
    CountdownRow,
    $$CountdownsTableFilterComposer,
    $$CountdownsTableOrderingComposer,
    $$CountdownsTableAnnotationComposer,
    $$CountdownsTableCreateCompanionBuilder,
    $$CountdownsTableUpdateCompanionBuilder,
    (
      CountdownRow,
      BaseReferences<_$AppDatabase, $CountdownsTable, CountdownRow>
    ),
    CountdownRow,
    PrefetchHooks Function()>;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  Value<String?> eventId,
  required String title,
  required DateTime triggerTime,
  Value<String?> repeatRule,
  Value<bool> enabled,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String?> eventId,
  Value<String> title,
  Value<DateTime> triggerTime,
  Value<String?> repeatRule,
  Value<bool> enabled,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CalendarEventsTable _eventIdTable(_$AppDatabase db) =>
      db.calendarEvents.createAlias(
          $_aliasNameGenerator(db.reminders.eventId, db.calendarEvents.id));

  $$CalendarEventsTableProcessedTableManager? get eventId {
    final $_column = $_itemColumn<String>('event_id');
    if ($_column == null) return null;
    final manager = $$CalendarEventsTableTableManager($_db, $_db.calendarEvents)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get triggerTime => $composableBuilder(
      column: $table.triggerTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CalendarEventsTableFilterComposer get eventId {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableFilterComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get triggerTime => $composableBuilder(
      column: $table.triggerTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CalendarEventsTableOrderingComposer get eventId {
    final $$CalendarEventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableOrderingComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get triggerTime => $composableBuilder(
      column: $table.triggerTime, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CalendarEventsTableAnnotationComposer get eventId {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, $$RemindersTableReferences),
    ReminderRow,
    PrefetchHooks Function({bool eventId})> {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> eventId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> triggerTime = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion(
            id: id,
            eventId: eventId,
            title: title,
            triggerTime: triggerTime,
            repeatRule: repeatRule,
            enabled: enabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> eventId = const Value.absent(),
            required String title,
            required DateTime triggerTime,
            Value<String?> repeatRule = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion.insert(
            id: id,
            eventId: eventId,
            title: title,
            triggerTime: triggerTime,
            repeatRule: repeatRule,
            enabled: enabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RemindersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$RemindersTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$RemindersTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, $$RemindersTableReferences),
    ReminderRow,
    PrefetchHooks Function({bool eventId})>;
typedef $$AiPersonasTableCreateCompanionBuilder = AiPersonasCompanion Function({
  required String id,
  required String name,
  Value<String?> avatar,
  Value<int?> avatarColor,
  Value<String?> description,
  Value<String?> personality,
  Value<String?> speakingStyle,
  Value<String?> userNickname,
  Value<String?> systemPrompt,
  required List<String> enabledTools,
  Value<double> temperature,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AiPersonasTableUpdateCompanionBuilder = AiPersonasCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> avatar,
  Value<int?> avatarColor,
  Value<String?> description,
  Value<String?> personality,
  Value<String?> speakingStyle,
  Value<String?> userNickname,
  Value<String?> systemPrompt,
  Value<List<String>> enabledTools,
  Value<double> temperature,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$AiPersonasTableReferences
    extends BaseReferences<_$AppDatabase, $AiPersonasTable, AiPersonaRow> {
  $$AiPersonasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatSessionsTable, List<ChatSessionRow>>
      _chatSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chatSessions,
              aliasName: $_aliasNameGenerator(
                  db.aiPersonas.id, db.chatSessions.personaId));

  $$ChatSessionsTableProcessedTableManager get chatSessionsRefs {
    final manager = $$ChatSessionsTableTableManager($_db, $_db.chatSessions)
        .filter((f) => f.personaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AiPersonasTableFilterComposer
    extends Composer<_$AppDatabase, $AiPersonasTable> {
  $$AiPersonasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatar => $composableBuilder(
      column: $table.avatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avatarColor => $composableBuilder(
      column: $table.avatarColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personality => $composableBuilder(
      column: $table.personality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get speakingStyle => $composableBuilder(
      column: $table.speakingStyle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNickname => $composableBuilder(
      column: $table.userNickname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get enabledTools => $composableBuilder(
          column: $table.enabledTools,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> chatSessionsRefs(
      Expression<bool> Function($$ChatSessionsTableFilterComposer f) f) {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.personaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableFilterComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AiPersonasTableOrderingComposer
    extends Composer<_$AppDatabase, $AiPersonasTable> {
  $$AiPersonasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatar => $composableBuilder(
      column: $table.avatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avatarColor => $composableBuilder(
      column: $table.avatarColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personality => $composableBuilder(
      column: $table.personality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get speakingStyle => $composableBuilder(
      column: $table.speakingStyle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNickname => $composableBuilder(
      column: $table.userNickname,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enabledTools => $composableBuilder(
      column: $table.enabledTools,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AiPersonasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiPersonasTable> {
  $$AiPersonasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<int> get avatarColor => $composableBuilder(
      column: $table.avatarColor, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get personality => $composableBuilder(
      column: $table.personality, builder: (column) => column);

  GeneratedColumn<String> get speakingStyle => $composableBuilder(
      column: $table.speakingStyle, builder: (column) => column);

  GeneratedColumn<String> get userNickname => $composableBuilder(
      column: $table.userNickname, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get enabledTools =>
      $composableBuilder(
          column: $table.enabledTools, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> chatSessionsRefs<T extends Object>(
      Expression<T> Function($$ChatSessionsTableAnnotationComposer a) f) {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.personaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AiPersonasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiPersonasTable,
    AiPersonaRow,
    $$AiPersonasTableFilterComposer,
    $$AiPersonasTableOrderingComposer,
    $$AiPersonasTableAnnotationComposer,
    $$AiPersonasTableCreateCompanionBuilder,
    $$AiPersonasTableUpdateCompanionBuilder,
    (AiPersonaRow, $$AiPersonasTableReferences),
    AiPersonaRow,
    PrefetchHooks Function({bool chatSessionsRefs})> {
  $$AiPersonasTableTableManager(_$AppDatabase db, $AiPersonasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiPersonasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiPersonasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiPersonasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> avatar = const Value.absent(),
            Value<int?> avatarColor = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> personality = const Value.absent(),
            Value<String?> speakingStyle = const Value.absent(),
            Value<String?> userNickname = const Value.absent(),
            Value<String?> systemPrompt = const Value.absent(),
            Value<List<String>> enabledTools = const Value.absent(),
            Value<double> temperature = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiPersonasCompanion(
            id: id,
            name: name,
            avatar: avatar,
            avatarColor: avatarColor,
            description: description,
            personality: personality,
            speakingStyle: speakingStyle,
            userNickname: userNickname,
            systemPrompt: systemPrompt,
            enabledTools: enabledTools,
            temperature: temperature,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> avatar = const Value.absent(),
            Value<int?> avatarColor = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> personality = const Value.absent(),
            Value<String?> speakingStyle = const Value.absent(),
            Value<String?> userNickname = const Value.absent(),
            Value<String?> systemPrompt = const Value.absent(),
            required List<String> enabledTools,
            Value<double> temperature = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AiPersonasCompanion.insert(
            id: id,
            name: name,
            avatar: avatar,
            avatarColor: avatarColor,
            description: description,
            personality: personality,
            speakingStyle: speakingStyle,
            userNickname: userNickname,
            systemPrompt: systemPrompt,
            enabledTools: enabledTools,
            temperature: temperature,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AiPersonasTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({chatSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatSessionsRefs) db.chatSessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatSessionsRefs)
                    await $_getPrefetchedData<AiPersonaRow, $AiPersonasTable,
                            ChatSessionRow>(
                        currentTable: table,
                        referencedTable: $$AiPersonasTableReferences
                            ._chatSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AiPersonasTableReferences(db, table, p0)
                                .chatSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.personaId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AiPersonasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiPersonasTable,
    AiPersonaRow,
    $$AiPersonasTableFilterComposer,
    $$AiPersonasTableOrderingComposer,
    $$AiPersonasTableAnnotationComposer,
    $$AiPersonasTableCreateCompanionBuilder,
    $$AiPersonasTableUpdateCompanionBuilder,
    (AiPersonaRow, $$AiPersonasTableReferences),
    AiPersonaRow,
    PrefetchHooks Function({bool chatSessionsRefs})>;
typedef $$AiProvidersTableCreateCompanionBuilder = AiProvidersCompanion
    Function({
  required String id,
  required String name,
  required String baseUrl,
  Value<String?> apiKey,
  required String model,
  Value<double> temperature,
  Value<int?> maxTokens,
  Value<bool> streamingEnabled,
  Value<bool> isDefault,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AiProvidersTableUpdateCompanionBuilder = AiProvidersCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> baseUrl,
  Value<String?> apiKey,
  Value<String> model,
  Value<double> temperature,
  Value<int?> maxTokens,
  Value<bool> streamingEnabled,
  Value<bool> isDefault,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AiProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $AiProvidersTable> {
  $$AiProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxTokens => $composableBuilder(
      column: $table.maxTokens, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get streamingEnabled => $composableBuilder(
      column: $table.streamingEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AiProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $AiProvidersTable> {
  $$AiProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxTokens => $composableBuilder(
      column: $table.maxTokens, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get streamingEnabled => $composableBuilder(
      column: $table.streamingEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AiProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiProvidersTable> {
  $$AiProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => column);

  GeneratedColumn<int> get maxTokens =>
      $composableBuilder(column: $table.maxTokens, builder: (column) => column);

  GeneratedColumn<bool> get streamingEnabled => $composableBuilder(
      column: $table.streamingEnabled, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AiProvidersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiProvidersTable,
    AiProviderRow,
    $$AiProvidersTableFilterComposer,
    $$AiProvidersTableOrderingComposer,
    $$AiProvidersTableAnnotationComposer,
    $$AiProvidersTableCreateCompanionBuilder,
    $$AiProvidersTableUpdateCompanionBuilder,
    (
      AiProviderRow,
      BaseReferences<_$AppDatabase, $AiProvidersTable, AiProviderRow>
    ),
    AiProviderRow,
    PrefetchHooks Function()> {
  $$AiProvidersTableTableManager(_$AppDatabase db, $AiProvidersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> baseUrl = const Value.absent(),
            Value<String?> apiKey = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<double> temperature = const Value.absent(),
            Value<int?> maxTokens = const Value.absent(),
            Value<bool> streamingEnabled = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiProvidersCompanion(
            id: id,
            name: name,
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
            streamingEnabled: streamingEnabled,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String baseUrl,
            Value<String?> apiKey = const Value.absent(),
            required String model,
            Value<double> temperature = const Value.absent(),
            Value<int?> maxTokens = const Value.absent(),
            Value<bool> streamingEnabled = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AiProvidersCompanion.insert(
            id: id,
            name: name,
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
            streamingEnabled: streamingEnabled,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiProvidersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiProvidersTable,
    AiProviderRow,
    $$AiProvidersTableFilterComposer,
    $$AiProvidersTableOrderingComposer,
    $$AiProvidersTableAnnotationComposer,
    $$AiProvidersTableCreateCompanionBuilder,
    $$AiProvidersTableUpdateCompanionBuilder,
    (
      AiProviderRow,
      BaseReferences<_$AppDatabase, $AiProvidersTable, AiProviderRow>
    ),
    AiProviderRow,
    PrefetchHooks Function()>;
typedef $$ChatSessionsTableCreateCompanionBuilder = ChatSessionsCompanion
    Function({
  required String id,
  required String title,
  Value<String?> personaId,
  Value<String?> providerId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ChatSessionsTableUpdateCompanionBuilder = ChatSessionsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> personaId,
  Value<String?> providerId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ChatSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ChatSessionsTable, ChatSessionRow> {
  $$ChatSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AiPersonasTable _personaIdTable(_$AppDatabase db) =>
      db.aiPersonas.createAlias(
          $_aliasNameGenerator(db.chatSessions.personaId, db.aiPersonas.id));

  $$AiPersonasTableProcessedTableManager? get personaId {
    final $_column = $_itemColumn<String>('persona_id');
    if ($_column == null) return null;
    final manager = $$AiPersonasTableTableManager($_db, $_db.aiPersonas)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessageRow>>
      _chatMessagesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chatMessages,
              aliasName: $_aliasNameGenerator(
                  db.chatSessions.id, db.chatMessages.sessionId));

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager($_db, $_db.chatMessages)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChatSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$AiPersonasTableFilterComposer get personaId {
    final $$AiPersonasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personaId,
        referencedTable: $db.aiPersonas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiPersonasTableFilterComposer(
              $db: $db,
              $table: $db.aiPersonas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> chatMessagesRefs(
      Expression<bool> Function($$ChatMessagesTableFilterComposer f) f) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableFilterComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$AiPersonasTableOrderingComposer get personaId {
    final $$AiPersonasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personaId,
        referencedTable: $db.aiPersonas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiPersonasTableOrderingComposer(
              $db: $db,
              $table: $db.aiPersonas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AiPersonasTableAnnotationComposer get personaId {
    final $$AiPersonasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personaId,
        referencedTable: $db.aiPersonas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiPersonasTableAnnotationComposer(
              $db: $db,
              $table: $db.aiPersonas,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> chatMessagesRefs<T extends Object>(
      Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatMessages,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatMessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.chatMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSessionRow,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (ChatSessionRow, $$ChatSessionsTableReferences),
    ChatSessionRow,
    PrefetchHooks Function({bool personaId, bool chatMessagesRefs})> {
  $$ChatSessionsTableTableManager(_$AppDatabase db, $ChatSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> personaId = const Value.absent(),
            Value<String?> providerId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion(
            id: id,
            title: title,
            personaId: personaId,
            providerId: providerId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> personaId = const Value.absent(),
            Value<String?> providerId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion.insert(
            id: id,
            title: title,
            personaId: personaId,
            providerId: providerId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {personaId = false, chatMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatMessagesRefs) db.chatMessages],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (personaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.personaId,
                    referencedTable:
                        $$ChatSessionsTableReferences._personaIdTable(db),
                    referencedColumn:
                        $$ChatSessionsTableReferences._personaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatMessagesRefs)
                    await $_getPrefetchedData<ChatSessionRow,
                            $ChatSessionsTable, ChatMessageRow>(
                        currentTable: table,
                        referencedTable: $$ChatSessionsTableReferences
                            ._chatMessagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChatSessionsTableReferences(db, table, p0)
                                .chatMessagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChatSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSessionRow,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (ChatSessionRow, $$ChatSessionsTableReferences),
    ChatSessionRow,
    PrefetchHooks Function({bool personaId, bool chatMessagesRefs})>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  required String id,
  required String sessionId,
  required ChatRole role,
  required String content,
  Value<String?> toolName,
  Value<String?> toolCallId,
  Value<String?> toolArguments,
  Value<String?> toolResult,
  Value<String?> reasoningContent,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<String> id,
  Value<String> sessionId,
  Value<ChatRole> role,
  Value<String> content,
  Value<String?> toolName,
  Value<String?> toolCallId,
  Value<String?> toolArguments,
  Value<String?> toolResult,
  Value<String?> reasoningContent,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ChatMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.chatSessions.createAlias(
          $_aliasNameGenerator(db.chatMessages.sessionId, db.chatSessions.id));

  $$ChatSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$ChatSessionsTableTableManager($_db, $_db.chatSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ChatRole, ChatRole, String> get role =>
      $composableBuilder(
          column: $table.role,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toolName => $composableBuilder(
      column: $table.toolName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toolCallId => $composableBuilder(
      column: $table.toolCallId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toolArguments => $composableBuilder(
      column: $table.toolArguments, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toolResult => $composableBuilder(
      column: $table.toolResult, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasoningContent => $composableBuilder(
      column: $table.reasoningContent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ChatSessionsTableFilterComposer get sessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableFilterComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toolName => $composableBuilder(
      column: $table.toolName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toolCallId => $composableBuilder(
      column: $table.toolCallId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toolArguments => $composableBuilder(
      column: $table.toolArguments,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toolResult => $composableBuilder(
      column: $table.toolResult, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasoningContent => $composableBuilder(
      column: $table.reasoningContent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ChatSessionsTableOrderingComposer get sessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChatRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get toolName =>
      $composableBuilder(column: $table.toolName, builder: (column) => column);

  GeneratedColumn<String> get toolCallId => $composableBuilder(
      column: $table.toolCallId, builder: (column) => column);

  GeneratedColumn<String> get toolArguments => $composableBuilder(
      column: $table.toolArguments, builder: (column) => column);

  GeneratedColumn<String> get toolResult => $composableBuilder(
      column: $table.toolResult, builder: (column) => column);

  GeneratedColumn<String> get reasoningContent => $composableBuilder(
      column: $table.reasoningContent, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChatSessionsTableAnnotationComposer get sessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.chatSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessageRow,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessageRow, $$ChatMessagesTableReferences),
    ChatMessageRow,
    PrefetchHooks Function({bool sessionId})> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<ChatRole> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> toolName = const Value.absent(),
            Value<String?> toolCallId = const Value.absent(),
            Value<String?> toolArguments = const Value.absent(),
            Value<String?> toolResult = const Value.absent(),
            Value<String?> reasoningContent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            sessionId: sessionId,
            role: role,
            content: content,
            toolName: toolName,
            toolCallId: toolCallId,
            toolArguments: toolArguments,
            toolResult: toolResult,
            reasoningContent: reasoningContent,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required ChatRole role,
            required String content,
            Value<String?> toolName = const Value.absent(),
            Value<String?> toolCallId = const Value.absent(),
            Value<String?> toolArguments = const Value.absent(),
            Value<String?> toolResult = const Value.absent(),
            Value<String?> reasoningContent = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            sessionId: sessionId,
            role: role,
            content: content,
            toolName: toolName,
            toolCallId: toolCallId,
            toolArguments: toolArguments,
            toolResult: toolResult,
            reasoningContent: reasoningContent,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatMessagesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$ChatMessagesTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$ChatMessagesTableReferences._sessionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessageRow,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (ChatMessageRow, $$ChatMessagesTableReferences),
    ChatMessageRow,
    PrefetchHooks Function({bool sessionId})>;
typedef $$ThemeConfigsTableCreateCompanionBuilder = ThemeConfigsCompanion
    Function({
  required String id,
  required String name,
  required String brightness,
  required int primaryColor,
  required int secondaryColor,
  required int backgroundColor,
  required int surfaceColor,
  required int textColor,
  Value<double> borderRadius,
  Value<double> cardOpacity,
  Value<double> blurAmount,
  Value<double> fontScale,
  Value<bool> animationEnabled,
  Value<double> shadowStrength,
  Value<int?> navigationBarColor,
  Value<int?> sidebarColor,
  Value<int?> eventColor,
  Value<int?> countdownColor,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ThemeConfigsTableUpdateCompanionBuilder = ThemeConfigsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> brightness,
  Value<int> primaryColor,
  Value<int> secondaryColor,
  Value<int> backgroundColor,
  Value<int> surfaceColor,
  Value<int> textColor,
  Value<double> borderRadius,
  Value<double> cardOpacity,
  Value<double> blurAmount,
  Value<double> fontScale,
  Value<bool> animationEnabled,
  Value<double> shadowStrength,
  Value<int?> navigationBarColor,
  Value<int?> sidebarColor,
  Value<int?> eventColor,
  Value<int?> countdownColor,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ThemeConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ThemeConfigsTable> {
  $$ThemeConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get primaryColor => $composableBuilder(
      column: $table.primaryColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get secondaryColor => $composableBuilder(
      column: $table.secondaryColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surfaceColor => $composableBuilder(
      column: $table.surfaceColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get textColor => $composableBuilder(
      column: $table.textColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get borderRadius => $composableBuilder(
      column: $table.borderRadius, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cardOpacity => $composableBuilder(
      column: $table.cardOpacity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get blurAmount => $composableBuilder(
      column: $table.blurAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fontScale => $composableBuilder(
      column: $table.fontScale, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get animationEnabled => $composableBuilder(
      column: $table.animationEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shadowStrength => $composableBuilder(
      column: $table.shadowStrength,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get navigationBarColor => $composableBuilder(
      column: $table.navigationBarColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sidebarColor => $composableBuilder(
      column: $table.sidebarColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eventColor => $composableBuilder(
      column: $table.eventColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get countdownColor => $composableBuilder(
      column: $table.countdownColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ThemeConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThemeConfigsTable> {
  $$ThemeConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get primaryColor => $composableBuilder(
      column: $table.primaryColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get secondaryColor => $composableBuilder(
      column: $table.secondaryColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surfaceColor => $composableBuilder(
      column: $table.surfaceColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get textColor => $composableBuilder(
      column: $table.textColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get borderRadius => $composableBuilder(
      column: $table.borderRadius,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cardOpacity => $composableBuilder(
      column: $table.cardOpacity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get blurAmount => $composableBuilder(
      column: $table.blurAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fontScale => $composableBuilder(
      column: $table.fontScale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get animationEnabled => $composableBuilder(
      column: $table.animationEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shadowStrength => $composableBuilder(
      column: $table.shadowStrength,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get navigationBarColor => $composableBuilder(
      column: $table.navigationBarColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sidebarColor => $composableBuilder(
      column: $table.sidebarColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventColor => $composableBuilder(
      column: $table.eventColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get countdownColor => $composableBuilder(
      column: $table.countdownColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ThemeConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThemeConfigsTable> {
  $$ThemeConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => column);

  GeneratedColumn<int> get primaryColor => $composableBuilder(
      column: $table.primaryColor, builder: (column) => column);

  GeneratedColumn<int> get secondaryColor => $composableBuilder(
      column: $table.secondaryColor, builder: (column) => column);

  GeneratedColumn<int> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor, builder: (column) => column);

  GeneratedColumn<int> get surfaceColor => $composableBuilder(
      column: $table.surfaceColor, builder: (column) => column);

  GeneratedColumn<int> get textColor =>
      $composableBuilder(column: $table.textColor, builder: (column) => column);

  GeneratedColumn<double> get borderRadius => $composableBuilder(
      column: $table.borderRadius, builder: (column) => column);

  GeneratedColumn<double> get cardOpacity => $composableBuilder(
      column: $table.cardOpacity, builder: (column) => column);

  GeneratedColumn<double> get blurAmount => $composableBuilder(
      column: $table.blurAmount, builder: (column) => column);

  GeneratedColumn<double> get fontScale =>
      $composableBuilder(column: $table.fontScale, builder: (column) => column);

  GeneratedColumn<bool> get animationEnabled => $composableBuilder(
      column: $table.animationEnabled, builder: (column) => column);

  GeneratedColumn<double> get shadowStrength => $composableBuilder(
      column: $table.shadowStrength, builder: (column) => column);

  GeneratedColumn<int> get navigationBarColor => $composableBuilder(
      column: $table.navigationBarColor, builder: (column) => column);

  GeneratedColumn<int> get sidebarColor => $composableBuilder(
      column: $table.sidebarColor, builder: (column) => column);

  GeneratedColumn<int> get eventColor => $composableBuilder(
      column: $table.eventColor, builder: (column) => column);

  GeneratedColumn<int> get countdownColor => $composableBuilder(
      column: $table.countdownColor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ThemeConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ThemeConfigsTable,
    ThemeConfigRow,
    $$ThemeConfigsTableFilterComposer,
    $$ThemeConfigsTableOrderingComposer,
    $$ThemeConfigsTableAnnotationComposer,
    $$ThemeConfigsTableCreateCompanionBuilder,
    $$ThemeConfigsTableUpdateCompanionBuilder,
    (
      ThemeConfigRow,
      BaseReferences<_$AppDatabase, $ThemeConfigsTable, ThemeConfigRow>
    ),
    ThemeConfigRow,
    PrefetchHooks Function()> {
  $$ThemeConfigsTableTableManager(_$AppDatabase db, $ThemeConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThemeConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThemeConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThemeConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> brightness = const Value.absent(),
            Value<int> primaryColor = const Value.absent(),
            Value<int> secondaryColor = const Value.absent(),
            Value<int> backgroundColor = const Value.absent(),
            Value<int> surfaceColor = const Value.absent(),
            Value<int> textColor = const Value.absent(),
            Value<double> borderRadius = const Value.absent(),
            Value<double> cardOpacity = const Value.absent(),
            Value<double> blurAmount = const Value.absent(),
            Value<double> fontScale = const Value.absent(),
            Value<bool> animationEnabled = const Value.absent(),
            Value<double> shadowStrength = const Value.absent(),
            Value<int?> navigationBarColor = const Value.absent(),
            Value<int?> sidebarColor = const Value.absent(),
            Value<int?> eventColor = const Value.absent(),
            Value<int?> countdownColor = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ThemeConfigsCompanion(
            id: id,
            name: name,
            brightness: brightness,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            backgroundColor: backgroundColor,
            surfaceColor: surfaceColor,
            textColor: textColor,
            borderRadius: borderRadius,
            cardOpacity: cardOpacity,
            blurAmount: blurAmount,
            fontScale: fontScale,
            animationEnabled: animationEnabled,
            shadowStrength: shadowStrength,
            navigationBarColor: navigationBarColor,
            sidebarColor: sidebarColor,
            eventColor: eventColor,
            countdownColor: countdownColor,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String brightness,
            required int primaryColor,
            required int secondaryColor,
            required int backgroundColor,
            required int surfaceColor,
            required int textColor,
            Value<double> borderRadius = const Value.absent(),
            Value<double> cardOpacity = const Value.absent(),
            Value<double> blurAmount = const Value.absent(),
            Value<double> fontScale = const Value.absent(),
            Value<bool> animationEnabled = const Value.absent(),
            Value<double> shadowStrength = const Value.absent(),
            Value<int?> navigationBarColor = const Value.absent(),
            Value<int?> sidebarColor = const Value.absent(),
            Value<int?> eventColor = const Value.absent(),
            Value<int?> countdownColor = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ThemeConfigsCompanion.insert(
            id: id,
            name: name,
            brightness: brightness,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            backgroundColor: backgroundColor,
            surfaceColor: surfaceColor,
            textColor: textColor,
            borderRadius: borderRadius,
            cardOpacity: cardOpacity,
            blurAmount: blurAmount,
            fontScale: fontScale,
            animationEnabled: animationEnabled,
            shadowStrength: shadowStrength,
            navigationBarColor: navigationBarColor,
            sidebarColor: sidebarColor,
            eventColor: eventColor,
            countdownColor: countdownColor,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ThemeConfigsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ThemeConfigsTable,
    ThemeConfigRow,
    $$ThemeConfigsTableFilterComposer,
    $$ThemeConfigsTableOrderingComposer,
    $$ThemeConfigsTableAnnotationComposer,
    $$ThemeConfigsTableCreateCompanionBuilder,
    $$ThemeConfigsTableUpdateCompanionBuilder,
    (
      ThemeConfigRow,
      BaseReferences<_$AppDatabase, $ThemeConfigsTable, ThemeConfigRow>
    ),
    ThemeConfigRow,
    PrefetchHooks Function()>;
typedef $$DailyDigestsTableCreateCompanionBuilder = DailyDigestsCompanion
    Function({
  required String id,
  required String kind,
  required String dayKey,
  required String content,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DailyDigestsTableUpdateCompanionBuilder = DailyDigestsCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<String> dayKey,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DailyDigestsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyDigestsTable> {
  $$DailyDigestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayKey => $composableBuilder(
      column: $table.dayKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DailyDigestsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyDigestsTable> {
  $$DailyDigestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayKey => $composableBuilder(
      column: $table.dayKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyDigestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyDigestsTable> {
  $$DailyDigestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyDigestsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyDigestsTable,
    DailyDigestRow,
    $$DailyDigestsTableFilterComposer,
    $$DailyDigestsTableOrderingComposer,
    $$DailyDigestsTableAnnotationComposer,
    $$DailyDigestsTableCreateCompanionBuilder,
    $$DailyDigestsTableUpdateCompanionBuilder,
    (
      DailyDigestRow,
      BaseReferences<_$AppDatabase, $DailyDigestsTable, DailyDigestRow>
    ),
    DailyDigestRow,
    PrefetchHooks Function()> {
  $$DailyDigestsTableTableManager(_$AppDatabase db, $DailyDigestsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyDigestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyDigestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyDigestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> dayKey = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyDigestsCompanion(
            id: id,
            kind: kind,
            dayKey: dayKey,
            content: content,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required String dayKey,
            required String content,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyDigestsCompanion.insert(
            id: id,
            kind: kind,
            dayKey: dayKey,
            content: content,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyDigestsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyDigestsTable,
    DailyDigestRow,
    $$DailyDigestsTableFilterComposer,
    $$DailyDigestsTableOrderingComposer,
    $$DailyDigestsTableAnnotationComposer,
    $$DailyDigestsTableCreateCompanionBuilder,
    $$DailyDigestsTableUpdateCompanionBuilder,
    (
      DailyDigestRow,
      BaseReferences<_$AppDatabase, $DailyDigestsTable, DailyDigestRow>
    ),
    DailyDigestRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CalendarCategoriesTableTableManager get calendarCategories =>
      $$CalendarCategoriesTableTableManager(_db, _db.calendarCategories);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$CountdownsTableTableManager get countdowns =>
      $$CountdownsTableTableManager(_db, _db.countdowns);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$AiPersonasTableTableManager get aiPersonas =>
      $$AiPersonasTableTableManager(_db, _db.aiPersonas);
  $$AiProvidersTableTableManager get aiProviders =>
      $$AiProvidersTableTableManager(_db, _db.aiProviders);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$ThemeConfigsTableTableManager get themeConfigs =>
      $$ThemeConfigsTableTableManager(_db, _db.themeConfigs);
  $$DailyDigestsTableTableManager get dailyDigests =>
      $$DailyDigestsTableTableManager(_db, _db.dailyDigests);
}

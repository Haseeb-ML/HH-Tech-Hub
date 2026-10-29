// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_service.dart';

// ignore_for_file: type=lint
class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isIncomeMeta = const VerificationMeta(
    'isIncome',
  );
  @override
  late final GeneratedColumn<bool> isIncome = GeneratedColumn<bool>(
    'is_income',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_income" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    details,
    type,
    amount,
    date,
    isIncome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    } else if (isInserting) {
      context.missing(_detailsMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_income')) {
      context.handle(
        _isIncomeMeta,
        isIncome.isAcceptableOrUnknown(data['is_income']!, _isIncomeMeta),
      );
    } else if (isInserting) {
      context.missing(_isIncomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      isIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_income'],
      )!,
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionsTableData extends DataClass
    implements Insertable<TransactionsTableData> {
  final int id;
  final String details;
  final String type;
  final double amount;
  final String date;
  final bool isIncome;
  const TransactionsTableData({
    required this.id,
    required this.details,
    required this.type,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['details'] = Variable<String>(details);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<String>(date);
    map['is_income'] = Variable<bool>(isIncome);
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      details: Value(details),
      type: Value(type),
      amount: Value(amount),
      date: Value(date),
      isIncome: Value(isIncome),
    );
  }

  factory TransactionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsTableData(
      id: serializer.fromJson<int>(json['id']),
      details: serializer.fromJson<String>(json['details']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      isIncome: serializer.fromJson<bool>(json['isIncome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'details': serializer.toJson<String>(details),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<String>(date),
      'isIncome': serializer.toJson<bool>(isIncome),
    };
  }

  TransactionsTableData copyWith({
    int? id,
    String? details,
    String? type,
    double? amount,
    String? date,
    bool? isIncome,
  }) => TransactionsTableData(
    id: id ?? this.id,
    details: details ?? this.details,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    isIncome: isIncome ?? this.isIncome,
  );
  TransactionsTableData copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      details: data.details.present ? data.details.value : this.details,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      isIncome: data.isIncome.present ? data.isIncome.value : this.isIncome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableData(')
          ..write('id: $id, ')
          ..write('details: $details, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('isIncome: $isIncome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, details, type, amount, date, isIncome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsTableData &&
          other.id == this.id &&
          other.details == this.details &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.isIncome == this.isIncome);
}

class TransactionsTableCompanion
    extends UpdateCompanion<TransactionsTableData> {
  final Value<int> id;
  final Value<String> details;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> date;
  final Value<bool> isIncome;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.details = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.isIncome = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    this.id = const Value.absent(),
    required String details,
    required String type,
    required double amount,
    required String date,
    required bool isIncome,
  }) : details = Value(details),
       type = Value(type),
       amount = Value(amount),
       date = Value(date),
       isIncome = Value(isIncome);
  static Insertable<TransactionsTableData> custom({
    Expression<int>? id,
    Expression<String>? details,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? date,
    Expression<bool>? isIncome,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (details != null) 'details': details,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (isIncome != null) 'is_income': isIncome,
    });
  }

  TransactionsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? details,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? date,
    Value<bool>? isIncome,
  }) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      details: details ?? this.details,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (isIncome.present) {
      map['is_income'] = Variable<bool>(isIncome.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('details: $details, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('isIncome: $isIncome')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTableTable extends ActivitiesTable
    with TableInfo<$ActivitiesTableTable, ActivitiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    timestamp,
    iconName,
    colorHex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivitiesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivitiesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivitiesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
    );
  }

  @override
  $ActivitiesTableTable createAlias(String alias) {
    return $ActivitiesTableTable(attachedDatabase, alias);
  }
}

class ActivitiesTableData extends DataClass
    implements Insertable<ActivitiesTableData> {
  final int id;
  final String content;
  final String timestamp;
  final String iconName;
  final String colorHex;
  const ActivitiesTableData({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.iconName,
    required this.colorHex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<String>(timestamp);
    map['icon_name'] = Variable<String>(iconName);
    map['color_hex'] = Variable<String>(colorHex);
    return map;
  }

  ActivitiesTableCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesTableCompanion(
      id: Value(id),
      content: Value(content),
      timestamp: Value(timestamp),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
    );
  }

  factory ActivitiesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivitiesTableData(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<String>(timestamp),
      'iconName': serializer.toJson<String>(iconName),
      'colorHex': serializer.toJson<String>(colorHex),
    };
  }

  ActivitiesTableData copyWith({
    int? id,
    String? content,
    String? timestamp,
    String? iconName,
    String? colorHex,
  }) => ActivitiesTableData(
    id: id ?? this.id,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    iconName: iconName ?? this.iconName,
    colorHex: colorHex ?? this.colorHex,
  );
  ActivitiesTableData copyWithCompanion(ActivitiesTableCompanion data) {
    return ActivitiesTableData(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesTableData(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, timestamp, iconName, colorHex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivitiesTableData &&
          other.id == this.id &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.iconName == this.iconName &&
          other.colorHex == this.colorHex);
}

class ActivitiesTableCompanion extends UpdateCompanion<ActivitiesTableData> {
  final Value<int> id;
  final Value<String> content;
  final Value<String> timestamp;
  final Value<String> iconName;
  final Value<String> colorHex;
  const ActivitiesTableCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
  });
  ActivitiesTableCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required String timestamp,
    required String iconName,
    required String colorHex,
  }) : content = Value(content),
       timestamp = Value(timestamp),
       iconName = Value(iconName),
       colorHex = Value(colorHex);
  static Insertable<ActivitiesTableData> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? timestamp,
    Expression<String>? iconName,
    Expression<String>? colorHex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (iconName != null) 'icon_name': iconName,
      if (colorHex != null) 'color_hex': colorHex,
    });
  }

  ActivitiesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<String>? timestamp,
    Value<String>? iconName,
    Value<String>? colorHex,
  }) {
    return ActivitiesTableCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesTableCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }
}

class $TasksTableTable extends TasksTable
    with TableInfo<$TasksTableTable, TasksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assigneeMeta = const VerificationMeta(
    'assignee',
  );
  @override
  late final GeneratedColumn<String> assignee = GeneratedColumn<String>(
    'assignee',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dueDate,
    assignee,
    isCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('assignee')) {
      context.handle(
        _assigneeMeta,
        assignee.isAcceptableOrUnknown(data['assignee']!, _assigneeMeta),
      );
    } else if (isInserting) {
      context.missing(_assigneeMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCompletedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TasksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      assignee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $TasksTableTable createAlias(String alias) {
    return $TasksTableTable(attachedDatabase, alias);
  }
}

class TasksTableData extends DataClass implements Insertable<TasksTableData> {
  final int id;
  final String name;
  final String dueDate;
  final String assignee;
  final bool isCompleted;
  const TasksTableData({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.assignee,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['due_date'] = Variable<String>(dueDate);
    map['assignee'] = Variable<String>(assignee);
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  TasksTableCompanion toCompanion(bool nullToAbsent) {
    return TasksTableCompanion(
      id: Value(id),
      name: Value(name),
      dueDate: Value(dueDate),
      assignee: Value(assignee),
      isCompleted: Value(isCompleted),
    );
  }

  factory TasksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasksTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      assignee: serializer.fromJson<String>(json['assignee']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'dueDate': serializer.toJson<String>(dueDate),
      'assignee': serializer.toJson<String>(assignee),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  TasksTableData copyWith({
    int? id,
    String? name,
    String? dueDate,
    String? assignee,
    bool? isCompleted,
  }) => TasksTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    dueDate: dueDate ?? this.dueDate,
    assignee: assignee ?? this.assignee,
    isCompleted: isCompleted ?? this.isCompleted,
  );
  TasksTableData copyWithCompanion(TasksTableCompanion data) {
    return TasksTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      assignee: data.assignee.present ? data.assignee.value : this.assignee,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dueDate: $dueDate, ')
          ..write('assignee: $assignee, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, dueDate, assignee, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasksTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.dueDate == this.dueDate &&
          other.assignee == this.assignee &&
          other.isCompleted == this.isCompleted);
}

class TasksTableCompanion extends UpdateCompanion<TasksTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> dueDate;
  final Value<String> assignee;
  final Value<bool> isCompleted;
  const TasksTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.assignee = const Value.absent(),
    this.isCompleted = const Value.absent(),
  });
  TasksTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String dueDate,
    required String assignee,
    required bool isCompleted,
  }) : name = Value(name),
       dueDate = Value(dueDate),
       assignee = Value(assignee),
       isCompleted = Value(isCompleted);
  static Insertable<TasksTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? dueDate,
    Expression<String>? assignee,
    Expression<bool>? isCompleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dueDate != null) 'due_date': dueDate,
      if (assignee != null) 'assignee': assignee,
      if (isCompleted != null) 'is_completed': isCompleted,
    });
  }

  TasksTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? dueDate,
    Value<String>? assignee,
    Value<bool>? isCompleted,
  }) {
    return TasksTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      assignee: assignee ?? this.assignee,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (assignee.present) {
      map['assignee'] = Variable<String>(assignee.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dueDate: $dueDate, ')
          ..write('assignee: $assignee, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }
}

class $StockAlertsTableTable extends StockAlertsTable
    with TableInfo<$StockAlertsTableTable, StockAlertsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockAlertsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _assetNameMeta = const VerificationMeta(
    'assetName',
  );
  @override
  late final GeneratedColumn<String> assetName = GeneratedColumn<String>(
    'asset_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStatusMeta = const VerificationMeta(
    'currentStatus',
  );
  @override
  late final GeneratedColumn<String> currentStatus = GeneratedColumn<String>(
    'current_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendationMeta = const VerificationMeta(
    'recommendation',
  );
  @override
  late final GeneratedColumn<String> recommendation = GeneratedColumn<String>(
    'recommendation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bgHexMeta = const VerificationMeta('bgHex');
  @override
  late final GeneratedColumn<String> bgHex = GeneratedColumn<String>(
    'bg_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetName,
    currentStatus,
    recommendation,
    colorHex,
    bgHex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_alerts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockAlertsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_name')) {
      context.handle(
        _assetNameMeta,
        assetName.isAcceptableOrUnknown(data['asset_name']!, _assetNameMeta),
      );
    } else if (isInserting) {
      context.missing(_assetNameMeta);
    }
    if (data.containsKey('current_status')) {
      context.handle(
        _currentStatusMeta,
        currentStatus.isAcceptableOrUnknown(
          data['current_status']!,
          _currentStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentStatusMeta);
    }
    if (data.containsKey('recommendation')) {
      context.handle(
        _recommendationMeta,
        recommendation.isAcceptableOrUnknown(
          data['recommendation']!,
          _recommendationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendationMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('bg_hex')) {
      context.handle(
        _bgHexMeta,
        bgHex.isAcceptableOrUnknown(data['bg_hex']!, _bgHexMeta),
      );
    } else if (isInserting) {
      context.missing(_bgHexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockAlertsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockAlertsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_name'],
      )!,
      currentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_status'],
      )!,
      recommendation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommendation'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      bgHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bg_hex'],
      )!,
    );
  }

  @override
  $StockAlertsTableTable createAlias(String alias) {
    return $StockAlertsTableTable(attachedDatabase, alias);
  }
}

class StockAlertsTableData extends DataClass
    implements Insertable<StockAlertsTableData> {
  final int id;
  final String assetName;
  final String currentStatus;
  final String recommendation;
  final String colorHex;
  final String bgHex;
  const StockAlertsTableData({
    required this.id,
    required this.assetName,
    required this.currentStatus,
    required this.recommendation,
    required this.colorHex,
    required this.bgHex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['asset_name'] = Variable<String>(assetName);
    map['current_status'] = Variable<String>(currentStatus);
    map['recommendation'] = Variable<String>(recommendation);
    map['color_hex'] = Variable<String>(colorHex);
    map['bg_hex'] = Variable<String>(bgHex);
    return map;
  }

  StockAlertsTableCompanion toCompanion(bool nullToAbsent) {
    return StockAlertsTableCompanion(
      id: Value(id),
      assetName: Value(assetName),
      currentStatus: Value(currentStatus),
      recommendation: Value(recommendation),
      colorHex: Value(colorHex),
      bgHex: Value(bgHex),
    );
  }

  factory StockAlertsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockAlertsTableData(
      id: serializer.fromJson<int>(json['id']),
      assetName: serializer.fromJson<String>(json['assetName']),
      currentStatus: serializer.fromJson<String>(json['currentStatus']),
      recommendation: serializer.fromJson<String>(json['recommendation']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      bgHex: serializer.fromJson<String>(json['bgHex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetName': serializer.toJson<String>(assetName),
      'currentStatus': serializer.toJson<String>(currentStatus),
      'recommendation': serializer.toJson<String>(recommendation),
      'colorHex': serializer.toJson<String>(colorHex),
      'bgHex': serializer.toJson<String>(bgHex),
    };
  }

  StockAlertsTableData copyWith({
    int? id,
    String? assetName,
    String? currentStatus,
    String? recommendation,
    String? colorHex,
    String? bgHex,
  }) => StockAlertsTableData(
    id: id ?? this.id,
    assetName: assetName ?? this.assetName,
    currentStatus: currentStatus ?? this.currentStatus,
    recommendation: recommendation ?? this.recommendation,
    colorHex: colorHex ?? this.colorHex,
    bgHex: bgHex ?? this.bgHex,
  );
  StockAlertsTableData copyWithCompanion(StockAlertsTableCompanion data) {
    return StockAlertsTableData(
      id: data.id.present ? data.id.value : this.id,
      assetName: data.assetName.present ? data.assetName.value : this.assetName,
      currentStatus: data.currentStatus.present
          ? data.currentStatus.value
          : this.currentStatus,
      recommendation: data.recommendation.present
          ? data.recommendation.value
          : this.recommendation,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      bgHex: data.bgHex.present ? data.bgHex.value : this.bgHex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockAlertsTableData(')
          ..write('id: $id, ')
          ..write('assetName: $assetName, ')
          ..write('currentStatus: $currentStatus, ')
          ..write('recommendation: $recommendation, ')
          ..write('colorHex: $colorHex, ')
          ..write('bgHex: $bgHex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetName,
    currentStatus,
    recommendation,
    colorHex,
    bgHex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockAlertsTableData &&
          other.id == this.id &&
          other.assetName == this.assetName &&
          other.currentStatus == this.currentStatus &&
          other.recommendation == this.recommendation &&
          other.colorHex == this.colorHex &&
          other.bgHex == this.bgHex);
}

class StockAlertsTableCompanion extends UpdateCompanion<StockAlertsTableData> {
  final Value<int> id;
  final Value<String> assetName;
  final Value<String> currentStatus;
  final Value<String> recommendation;
  final Value<String> colorHex;
  final Value<String> bgHex;
  const StockAlertsTableCompanion({
    this.id = const Value.absent(),
    this.assetName = const Value.absent(),
    this.currentStatus = const Value.absent(),
    this.recommendation = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.bgHex = const Value.absent(),
  });
  StockAlertsTableCompanion.insert({
    this.id = const Value.absent(),
    required String assetName,
    required String currentStatus,
    required String recommendation,
    required String colorHex,
    required String bgHex,
  }) : assetName = Value(assetName),
       currentStatus = Value(currentStatus),
       recommendation = Value(recommendation),
       colorHex = Value(colorHex),
       bgHex = Value(bgHex);
  static Insertable<StockAlertsTableData> custom({
    Expression<int>? id,
    Expression<String>? assetName,
    Expression<String>? currentStatus,
    Expression<String>? recommendation,
    Expression<String>? colorHex,
    Expression<String>? bgHex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetName != null) 'asset_name': assetName,
      if (currentStatus != null) 'current_status': currentStatus,
      if (recommendation != null) 'recommendation': recommendation,
      if (colorHex != null) 'color_hex': colorHex,
      if (bgHex != null) 'bg_hex': bgHex,
    });
  }

  StockAlertsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? assetName,
    Value<String>? currentStatus,
    Value<String>? recommendation,
    Value<String>? colorHex,
    Value<String>? bgHex,
  }) {
    return StockAlertsTableCompanion(
      id: id ?? this.id,
      assetName: assetName ?? this.assetName,
      currentStatus: currentStatus ?? this.currentStatus,
      recommendation: recommendation ?? this.recommendation,
      colorHex: colorHex ?? this.colorHex,
      bgHex: bgHex ?? this.bgHex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetName.present) {
      map['asset_name'] = Variable<String>(assetName.value);
    }
    if (currentStatus.present) {
      map['current_status'] = Variable<String>(currentStatus.value);
    }
    if (recommendation.present) {
      map['recommendation'] = Variable<String>(recommendation.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (bgHex.present) {
      map['bg_hex'] = Variable<String>(bgHex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockAlertsTableCompanion(')
          ..write('id: $id, ')
          ..write('assetName: $assetName, ')
          ..write('currentStatus: $currentStatus, ')
          ..write('recommendation: $recommendation, ')
          ..write('colorHex: $colorHex, ')
          ..write('bgHex: $bgHex')
          ..write(')'))
        .toString();
  }
}

class $ClientsTableTable extends ClientsTable
    with TableInfo<$ClientsTableTable, ClientsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactPersonMeta = const VerificationMeta(
    'contactPerson',
  );
  @override
  late final GeneratedColumn<String> contactPerson = GeneratedColumn<String>(
    'contact_person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _industryMeta = const VerificationMeta(
    'industry',
  );
  @override
  late final GeneratedColumn<String> industry = GeneratedColumn<String>(
    'industry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalProjectsMeta = const VerificationMeta(
    'totalProjects',
  );
  @override
  late final GeneratedColumn<int> totalProjects = GeneratedColumn<int>(
    'total_projects',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _advancedPaymentMeta = const VerificationMeta(
    'advancedPayment',
  );
  @override
  late final GeneratedColumn<double> advancedPayment = GeneratedColumn<double>(
    'advanced_payment',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullPaymentMeta = const VerificationMeta(
    'fullPayment',
  );
  @override
  late final GeneratedColumn<double> fullPayment = GeneratedColumn<double>(
    'full_payment',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    contactPerson,
    email,
    phone,
    status,
    industry,
    totalProjects,
    advancedPayment,
    fullPayment,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('contact_person')) {
      context.handle(
        _contactPersonMeta,
        contactPerson.isAcceptableOrUnknown(
          data['contact_person']!,
          _contactPersonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactPersonMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('industry')) {
      context.handle(
        _industryMeta,
        industry.isAcceptableOrUnknown(data['industry']!, _industryMeta),
      );
    } else if (isInserting) {
      context.missing(_industryMeta);
    }
    if (data.containsKey('total_projects')) {
      context.handle(
        _totalProjectsMeta,
        totalProjects.isAcceptableOrUnknown(
          data['total_projects']!,
          _totalProjectsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalProjectsMeta);
    }
    if (data.containsKey('advanced_payment')) {
      context.handle(
        _advancedPaymentMeta,
        advancedPayment.isAcceptableOrUnknown(
          data['advanced_payment']!,
          _advancedPaymentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_advancedPaymentMeta);
    }
    if (data.containsKey('full_payment')) {
      context.handle(
        _fullPaymentMeta,
        fullPayment.isAcceptableOrUnknown(
          data['full_payment']!,
          _fullPaymentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fullPaymentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contactPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      industry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}industry'],
      )!,
      totalProjects: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_projects'],
      )!,
      advancedPayment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}advanced_payment'],
      )!,
      fullPayment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}full_payment'],
      )!,
    );
  }

  @override
  $ClientsTableTable createAlias(String alias) {
    return $ClientsTableTable(attachedDatabase, alias);
  }
}

class ClientsTableData extends DataClass
    implements Insertable<ClientsTableData> {
  final String id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String status;
  final String industry;
  final int totalProjects;
  final double advancedPayment;
  final double fullPayment;
  const ClientsTableData({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.status,
    required this.industry,
    required this.totalProjects,
    required this.advancedPayment,
    required this.fullPayment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['contact_person'] = Variable<String>(contactPerson);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['status'] = Variable<String>(status);
    map['industry'] = Variable<String>(industry);
    map['total_projects'] = Variable<int>(totalProjects);
    map['advanced_payment'] = Variable<double>(advancedPayment);
    map['full_payment'] = Variable<double>(fullPayment);
    return map;
  }

  ClientsTableCompanion toCompanion(bool nullToAbsent) {
    return ClientsTableCompanion(
      id: Value(id),
      name: Value(name),
      contactPerson: Value(contactPerson),
      email: Value(email),
      phone: Value(phone),
      status: Value(status),
      industry: Value(industry),
      totalProjects: Value(totalProjects),
      advancedPayment: Value(advancedPayment),
      fullPayment: Value(fullPayment),
    );
  }

  factory ClientsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      contactPerson: serializer.fromJson<String>(json['contactPerson']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      status: serializer.fromJson<String>(json['status']),
      industry: serializer.fromJson<String>(json['industry']),
      totalProjects: serializer.fromJson<int>(json['totalProjects']),
      advancedPayment: serializer.fromJson<double>(json['advancedPayment']),
      fullPayment: serializer.fromJson<double>(json['fullPayment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'contactPerson': serializer.toJson<String>(contactPerson),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'status': serializer.toJson<String>(status),
      'industry': serializer.toJson<String>(industry),
      'totalProjects': serializer.toJson<int>(totalProjects),
      'advancedPayment': serializer.toJson<double>(advancedPayment),
      'fullPayment': serializer.toJson<double>(fullPayment),
    };
  }

  ClientsTableData copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? email,
    String? phone,
    String? status,
    String? industry,
    int? totalProjects,
    double? advancedPayment,
    double? fullPayment,
  }) => ClientsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    contactPerson: contactPerson ?? this.contactPerson,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    status: status ?? this.status,
    industry: industry ?? this.industry,
    totalProjects: totalProjects ?? this.totalProjects,
    advancedPayment: advancedPayment ?? this.advancedPayment,
    fullPayment: fullPayment ?? this.fullPayment,
  );
  ClientsTableData copyWithCompanion(ClientsTableCompanion data) {
    return ClientsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      contactPerson: data.contactPerson.present
          ? data.contactPerson.value
          : this.contactPerson,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      status: data.status.present ? data.status.value : this.status,
      industry: data.industry.present ? data.industry.value : this.industry,
      totalProjects: data.totalProjects.present
          ? data.totalProjects.value
          : this.totalProjects,
      advancedPayment: data.advancedPayment.present
          ? data.advancedPayment.value
          : this.advancedPayment,
      fullPayment: data.fullPayment.present
          ? data.fullPayment.value
          : this.fullPayment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('industry: $industry, ')
          ..write('totalProjects: $totalProjects, ')
          ..write('advancedPayment: $advancedPayment, ')
          ..write('fullPayment: $fullPayment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    contactPerson,
    email,
    phone,
    status,
    industry,
    totalProjects,
    advancedPayment,
    fullPayment,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.contactPerson == this.contactPerson &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.status == this.status &&
          other.industry == this.industry &&
          other.totalProjects == this.totalProjects &&
          other.advancedPayment == this.advancedPayment &&
          other.fullPayment == this.fullPayment);
}

class ClientsTableCompanion extends UpdateCompanion<ClientsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> contactPerson;
  final Value<String> email;
  final Value<String> phone;
  final Value<String> status;
  final Value<String> industry;
  final Value<int> totalProjects;
  final Value<double> advancedPayment;
  final Value<double> fullPayment;
  final Value<int> rowid;
  const ClientsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.status = const Value.absent(),
    this.industry = const Value.absent(),
    this.totalProjects = const Value.absent(),
    this.advancedPayment = const Value.absent(),
    this.fullPayment = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsTableCompanion.insert({
    required String id,
    required String name,
    required String contactPerson,
    required String email,
    required String phone,
    required String status,
    required String industry,
    required int totalProjects,
    required double advancedPayment,
    required double fullPayment,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       contactPerson = Value(contactPerson),
       email = Value(email),
       phone = Value(phone),
       status = Value(status),
       industry = Value(industry),
       totalProjects = Value(totalProjects),
       advancedPayment = Value(advancedPayment),
       fullPayment = Value(fullPayment);
  static Insertable<ClientsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? contactPerson,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? status,
    Expression<String>? industry,
    Expression<int>? totalProjects,
    Expression<double>? advancedPayment,
    Expression<double>? fullPayment,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (status != null) 'status': status,
      if (industry != null) 'industry': industry,
      if (totalProjects != null) 'total_projects': totalProjects,
      if (advancedPayment != null) 'advanced_payment': advancedPayment,
      if (fullPayment != null) 'full_payment': fullPayment,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? contactPerson,
    Value<String>? email,
    Value<String>? phone,
    Value<String>? status,
    Value<String>? industry,
    Value<int>? totalProjects,
    Value<double>? advancedPayment,
    Value<double>? fullPayment,
    Value<int>? rowid,
  }) {
    return ClientsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      industry: industry ?? this.industry,
      totalProjects: totalProjects ?? this.totalProjects,
      advancedPayment: advancedPayment ?? this.advancedPayment,
      fullPayment: fullPayment ?? this.fullPayment,
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
    if (contactPerson.present) {
      map['contact_person'] = Variable<String>(contactPerson.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (industry.present) {
      map['industry'] = Variable<String>(industry.value);
    }
    if (totalProjects.present) {
      map['total_projects'] = Variable<int>(totalProjects.value);
    }
    if (advancedPayment.present) {
      map['advanced_payment'] = Variable<double>(advancedPayment.value);
    }
    if (fullPayment.present) {
      map['full_payment'] = Variable<double>(fullPayment.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('industry: $industry, ')
          ..write('totalProjects: $totalProjects, ')
          ..write('advancedPayment: $advancedPayment, ')
          ..write('fullPayment: $fullPayment, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BankAccountsTableTable extends BankAccountsTable
    with TableInfo<$BankAccountsTableTable, BankAccountsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BankAccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNumberMeta = const VerificationMeta(
    'accountNumber',
  );
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
    'account_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _openingBalanceDateMeta =
      const VerificationMeta('openingBalanceDate');
  @override
  late final GeneratedColumn<String> openingBalanceDate =
      GeneratedColumn<String>(
        'opening_balance_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Company'),
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    accountNumber,
    bankName,
    balance,
    status,
    openingBalance,
    openingBalanceDate,
    accountScope,
    ownerName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bank_accounts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BankAccountsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('account_number')) {
      context.handle(
        _accountNumberMeta,
        accountNumber.isAcceptableOrUnknown(
          data['account_number']!,
          _accountNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNumberMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance_date')) {
      context.handle(
        _openingBalanceDateMeta,
        openingBalanceDate.isAcceptableOrUnknown(
          data['opening_balance_date']!,
          _openingBalanceDateMeta,
        ),
      );
    }
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BankAccountsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BankAccountsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      accountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_number'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_balance'],
      )!,
      openingBalanceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_balance_date'],
      )!,
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      )!,
    );
  }

  @override
  $BankAccountsTableTable createAlias(String alias) {
    return $BankAccountsTableTable(attachedDatabase, alias);
  }
}

class BankAccountsTableData extends DataClass
    implements Insertable<BankAccountsTableData> {
  final String id;
  final String name;
  final String type;
  final String accountNumber;
  final String bankName;
  final double balance;
  final String status;
  final double openingBalance;
  final String openingBalanceDate;
  final String accountScope;
  final String ownerName;
  const BankAccountsTableData({
    required this.id,
    required this.name,
    required this.type,
    required this.accountNumber,
    required this.bankName,
    required this.balance,
    required this.status,
    required this.openingBalance,
    required this.openingBalanceDate,
    required this.accountScope,
    required this.ownerName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['account_number'] = Variable<String>(accountNumber);
    map['bank_name'] = Variable<String>(bankName);
    map['balance'] = Variable<double>(balance);
    map['status'] = Variable<String>(status);
    map['opening_balance'] = Variable<double>(openingBalance);
    map['opening_balance_date'] = Variable<String>(openingBalanceDate);
    map['account_scope'] = Variable<String>(accountScope);
    map['owner_name'] = Variable<String>(ownerName);
    return map;
  }

  BankAccountsTableCompanion toCompanion(bool nullToAbsent) {
    return BankAccountsTableCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      accountNumber: Value(accountNumber),
      bankName: Value(bankName),
      balance: Value(balance),
      status: Value(status),
      openingBalance: Value(openingBalance),
      openingBalanceDate: Value(openingBalanceDate),
      accountScope: Value(accountScope),
      ownerName: Value(ownerName),
    );
  }

  factory BankAccountsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BankAccountsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      accountNumber: serializer.fromJson<String>(json['accountNumber']),
      bankName: serializer.fromJson<String>(json['bankName']),
      balance: serializer.fromJson<double>(json['balance']),
      status: serializer.fromJson<String>(json['status']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      openingBalanceDate: serializer.fromJson<String>(
        json['openingBalanceDate'],
      ),
      accountScope: serializer.fromJson<String>(json['accountScope']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'accountNumber': serializer.toJson<String>(accountNumber),
      'bankName': serializer.toJson<String>(bankName),
      'balance': serializer.toJson<double>(balance),
      'status': serializer.toJson<String>(status),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'openingBalanceDate': serializer.toJson<String>(openingBalanceDate),
      'accountScope': serializer.toJson<String>(accountScope),
      'ownerName': serializer.toJson<String>(ownerName),
    };
  }

  BankAccountsTableData copyWith({
    String? id,
    String? name,
    String? type,
    String? accountNumber,
    String? bankName,
    double? balance,
    String? status,
    double? openingBalance,
    String? openingBalanceDate,
    String? accountScope,
    String? ownerName,
  }) => BankAccountsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    accountNumber: accountNumber ?? this.accountNumber,
    bankName: bankName ?? this.bankName,
    balance: balance ?? this.balance,
    status: status ?? this.status,
    openingBalance: openingBalance ?? this.openingBalance,
    openingBalanceDate: openingBalanceDate ?? this.openingBalanceDate,
    accountScope: accountScope ?? this.accountScope,
    ownerName: ownerName ?? this.ownerName,
  );
  BankAccountsTableData copyWithCompanion(BankAccountsTableCompanion data) {
    return BankAccountsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      accountNumber: data.accountNumber.present
          ? data.accountNumber.value
          : this.accountNumber,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      balance: data.balance.present ? data.balance.value : this.balance,
      status: data.status.present ? data.status.value : this.status,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      openingBalanceDate: data.openingBalanceDate.present
          ? data.openingBalanceDate.value
          : this.openingBalanceDate,
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BankAccountsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('bankName: $bankName, ')
          ..write('balance: $balance, ')
          ..write('status: $status, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceDate: $openingBalanceDate, ')
          ..write('accountScope: $accountScope, ')
          ..write('ownerName: $ownerName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    accountNumber,
    bankName,
    balance,
    status,
    openingBalance,
    openingBalanceDate,
    accountScope,
    ownerName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BankAccountsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.accountNumber == this.accountNumber &&
          other.bankName == this.bankName &&
          other.balance == this.balance &&
          other.status == this.status &&
          other.openingBalance == this.openingBalance &&
          other.openingBalanceDate == this.openingBalanceDate &&
          other.accountScope == this.accountScope &&
          other.ownerName == this.ownerName);
}

class BankAccountsTableCompanion
    extends UpdateCompanion<BankAccountsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> accountNumber;
  final Value<String> bankName;
  final Value<double> balance;
  final Value<String> status;
  final Value<double> openingBalance;
  final Value<String> openingBalanceDate;
  final Value<String> accountScope;
  final Value<String> ownerName;
  final Value<int> rowid;
  const BankAccountsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.bankName = const Value.absent(),
    this.balance = const Value.absent(),
    this.status = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingBalanceDate = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BankAccountsTableCompanion.insert({
    required String id,
    required String name,
    required String type,
    required String accountNumber,
    required String bankName,
    required double balance,
    required String status,
    this.openingBalance = const Value.absent(),
    this.openingBalanceDate = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       accountNumber = Value(accountNumber),
       bankName = Value(bankName),
       balance = Value(balance),
       status = Value(status);
  static Insertable<BankAccountsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? accountNumber,
    Expression<String>? bankName,
    Expression<double>? balance,
    Expression<String>? status,
    Expression<double>? openingBalance,
    Expression<String>? openingBalanceDate,
    Expression<String>? accountScope,
    Expression<String>? ownerName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (accountNumber != null) 'account_number': accountNumber,
      if (bankName != null) 'bank_name': bankName,
      if (balance != null) 'balance': balance,
      if (status != null) 'status': status,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (openingBalanceDate != null)
        'opening_balance_date': openingBalanceDate,
      if (accountScope != null) 'account_scope': accountScope,
      if (ownerName != null) 'owner_name': ownerName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BankAccountsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? accountNumber,
    Value<String>? bankName,
    Value<double>? balance,
    Value<String>? status,
    Value<double>? openingBalance,
    Value<String>? openingBalanceDate,
    Value<String>? accountScope,
    Value<String>? ownerName,
    Value<int>? rowid,
  }) {
    return BankAccountsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceDate: openingBalanceDate ?? this.openingBalanceDate,
      accountScope: accountScope ?? this.accountScope,
      ownerName: ownerName ?? this.ownerName,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (openingBalanceDate.present) {
      map['opening_balance_date'] = Variable<String>(openingBalanceDate.value);
    }
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BankAccountsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('bankName: $bankName, ')
          ..write('balance: $balance, ')
          ..write('status: $status, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceDate: $openingBalanceDate, ')
          ..write('accountScope: $accountScope, ')
          ..write('ownerName: $ownerName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseRecordsTableTable extends ExpenseRecordsTable
    with TableInfo<$ExpenseRecordsTableTable, ExpenseRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorNameMeta = const VerificationMeta(
    'vendorName',
  );
  @override
  late final GeneratedColumn<String> vendorName = GeneratedColumn<String>(
    'vendor_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    amount,
    accountId,
    category,
    vendorName,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('vendor_name')) {
      context.handle(
        _vendorNameMeta,
        vendorName.isAcceptableOrUnknown(data['vendor_name']!, _vendorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRecordsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      vendorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $ExpenseRecordsTableTable createAlias(String alias) {
    return $ExpenseRecordsTableTable(attachedDatabase, alias);
  }
}

class ExpenseRecordsTableData extends DataClass
    implements Insertable<ExpenseRecordsTableData> {
  final String id;
  final String date;
  final double amount;
  final String accountId;
  final String category;
  final String vendorName;
  final String description;
  const ExpenseRecordsTableData({
    required this.id,
    required this.date,
    required this.amount,
    required this.accountId,
    required this.category,
    required this.vendorName,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['amount'] = Variable<double>(amount);
    map['account_id'] = Variable<String>(accountId);
    map['category'] = Variable<String>(category);
    map['vendor_name'] = Variable<String>(vendorName);
    map['description'] = Variable<String>(description);
    return map;
  }

  ExpenseRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return ExpenseRecordsTableCompanion(
      id: Value(id),
      date: Value(date),
      amount: Value(amount),
      accountId: Value(accountId),
      category: Value(category),
      vendorName: Value(vendorName),
      description: Value(description),
    );
  }

  factory ExpenseRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      accountId: serializer.fromJson<String>(json['accountId']),
      category: serializer.fromJson<String>(json['category']),
      vendorName: serializer.fromJson<String>(json['vendorName']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'amount': serializer.toJson<double>(amount),
      'accountId': serializer.toJson<String>(accountId),
      'category': serializer.toJson<String>(category),
      'vendorName': serializer.toJson<String>(vendorName),
      'description': serializer.toJson<String>(description),
    };
  }

  ExpenseRecordsTableData copyWith({
    String? id,
    String? date,
    double? amount,
    String? accountId,
    String? category,
    String? vendorName,
    String? description,
  }) => ExpenseRecordsTableData(
    id: id ?? this.id,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    accountId: accountId ?? this.accountId,
    category: category ?? this.category,
    vendorName: vendorName ?? this.vendorName,
    description: description ?? this.description,
  );
  ExpenseRecordsTableData copyWithCompanion(ExpenseRecordsTableCompanion data) {
    return ExpenseRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      category: data.category.present ? data.category.value : this.category,
      vendorName: data.vendorName.present
          ? data.vendorName.value
          : this.vendorName,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRecordsTableData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('category: $category, ')
          ..write('vendorName: $vendorName, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    amount,
    accountId,
    category,
    vendorName,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRecordsTableData &&
          other.id == this.id &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.accountId == this.accountId &&
          other.category == this.category &&
          other.vendorName == this.vendorName &&
          other.description == this.description);
}

class ExpenseRecordsTableCompanion
    extends UpdateCompanion<ExpenseRecordsTableData> {
  final Value<String> id;
  final Value<String> date;
  final Value<double> amount;
  final Value<String> accountId;
  final Value<String> category;
  final Value<String> vendorName;
  final Value<String> description;
  final Value<int> rowid;
  const ExpenseRecordsTableCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.accountId = const Value.absent(),
    this.category = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseRecordsTableCompanion.insert({
    required String id,
    required String date,
    required double amount,
    required String accountId,
    required String category,
    required String vendorName,
    required String description,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       amount = Value(amount),
       accountId = Value(accountId),
       category = Value(category),
       vendorName = Value(vendorName),
       description = Value(description);
  static Insertable<ExpenseRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<double>? amount,
    Expression<String>? accountId,
    Expression<String>? category,
    Expression<String>? vendorName,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (accountId != null) 'account_id': accountId,
      if (category != null) 'category': category,
      if (vendorName != null) 'vendor_name': vendorName,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseRecordsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<double>? amount,
    Value<String>? accountId,
    Value<String>? category,
    Value<String>? vendorName,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return ExpenseRecordsTableCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      vendorName: vendorName ?? this.vendorName,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (vendorName.present) {
      map['vendor_name'] = Variable<String>(vendorName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('category: $category, ')
          ..write('vendorName: $vendorName, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncomeRecordsTableTable extends IncomeRecordsTable
    with TableInfo<$IncomeRecordsTableTable, IncomeRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectPaymentTypeMeta =
      const VerificationMeta('projectPaymentType');
  @override
  late final GeneratedColumn<String> projectPaymentType =
      GeneratedColumn<String>(
        'project_payment_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    clientId,
    clientName,
    amount,
    accountId,
    invoiceNumber,
    description,
    status,
    projectId,
    projectName,
    projectPaymentType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('project_payment_type')) {
      context.handle(
        _projectPaymentTypeMeta,
        projectPaymentType.isAcceptableOrUnknown(
          data['project_payment_type']!,
          _projectPaymentTypeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncomeRecordsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      ),
      projectPaymentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_payment_type'],
      ),
    );
  }

  @override
  $IncomeRecordsTableTable createAlias(String alias) {
    return $IncomeRecordsTableTable(attachedDatabase, alias);
  }
}

class IncomeRecordsTableData extends DataClass
    implements Insertable<IncomeRecordsTableData> {
  final String id;
  final String date;
  final String clientId;
  final String clientName;
  final double amount;
  final String accountId;
  final String invoiceNumber;
  final String description;
  final String status;
  final String? projectId;
  final String? projectName;
  final String? projectPaymentType;
  const IncomeRecordsTableData({
    required this.id,
    required this.date,
    required this.clientId,
    required this.clientName,
    required this.amount,
    required this.accountId,
    required this.invoiceNumber,
    required this.description,
    required this.status,
    this.projectId,
    this.projectName,
    this.projectPaymentType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['client_id'] = Variable<String>(clientId);
    map['client_name'] = Variable<String>(clientName);
    map['amount'] = Variable<double>(amount);
    map['account_id'] = Variable<String>(accountId);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['description'] = Variable<String>(description);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    if (!nullToAbsent || projectPaymentType != null) {
      map['project_payment_type'] = Variable<String>(projectPaymentType);
    }
    return map;
  }

  IncomeRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return IncomeRecordsTableCompanion(
      id: Value(id),
      date: Value(date),
      clientId: Value(clientId),
      clientName: Value(clientName),
      amount: Value(amount),
      accountId: Value(accountId),
      invoiceNumber: Value(invoiceNumber),
      description: Value(description),
      status: Value(status),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      projectPaymentType: projectPaymentType == null && nullToAbsent
          ? const Value.absent()
          : Value(projectPaymentType),
    );
  }

  factory IncomeRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      clientId: serializer.fromJson<String>(json['clientId']),
      clientName: serializer.fromJson<String>(json['clientName']),
      amount: serializer.fromJson<double>(json['amount']),
      accountId: serializer.fromJson<String>(json['accountId']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      description: serializer.fromJson<String>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      projectPaymentType: serializer.fromJson<String?>(
        json['projectPaymentType'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'clientId': serializer.toJson<String>(clientId),
      'clientName': serializer.toJson<String>(clientName),
      'amount': serializer.toJson<double>(amount),
      'accountId': serializer.toJson<String>(accountId),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'description': serializer.toJson<String>(description),
      'status': serializer.toJson<String>(status),
      'projectId': serializer.toJson<String?>(projectId),
      'projectName': serializer.toJson<String?>(projectName),
      'projectPaymentType': serializer.toJson<String?>(projectPaymentType),
    };
  }

  IncomeRecordsTableData copyWith({
    String? id,
    String? date,
    String? clientId,
    String? clientName,
    double? amount,
    String? accountId,
    String? invoiceNumber,
    String? description,
    String? status,
    Value<String?> projectId = const Value.absent(),
    Value<String?> projectName = const Value.absent(),
    Value<String?> projectPaymentType = const Value.absent(),
  }) => IncomeRecordsTableData(
    id: id ?? this.id,
    date: date ?? this.date,
    clientId: clientId ?? this.clientId,
    clientName: clientName ?? this.clientName,
    amount: amount ?? this.amount,
    accountId: accountId ?? this.accountId,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    description: description ?? this.description,
    status: status ?? this.status,
    projectId: projectId.present ? projectId.value : this.projectId,
    projectName: projectName.present ? projectName.value : this.projectName,
    projectPaymentType: projectPaymentType.present
        ? projectPaymentType.value
        : this.projectPaymentType,
  );
  IncomeRecordsTableData copyWithCompanion(IncomeRecordsTableCompanion data) {
    return IncomeRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      amount: data.amount.present ? data.amount.value : this.amount,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      projectPaymentType: data.projectPaymentType.present
          ? data.projectPaymentType.value
          : this.projectPaymentType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeRecordsTableData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('projectPaymentType: $projectPaymentType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    clientId,
    clientName,
    amount,
    accountId,
    invoiceNumber,
    description,
    status,
    projectId,
    projectName,
    projectPaymentType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeRecordsTableData &&
          other.id == this.id &&
          other.date == this.date &&
          other.clientId == this.clientId &&
          other.clientName == this.clientName &&
          other.amount == this.amount &&
          other.accountId == this.accountId &&
          other.invoiceNumber == this.invoiceNumber &&
          other.description == this.description &&
          other.status == this.status &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.projectPaymentType == this.projectPaymentType);
}

class IncomeRecordsTableCompanion
    extends UpdateCompanion<IncomeRecordsTableData> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> clientId;
  final Value<String> clientName;
  final Value<double> amount;
  final Value<String> accountId;
  final Value<String> invoiceNumber;
  final Value<String> description;
  final Value<String> status;
  final Value<String?> projectId;
  final Value<String?> projectName;
  final Value<String?> projectPaymentType;
  final Value<int> rowid;
  const IncomeRecordsTableCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.amount = const Value.absent(),
    this.accountId = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.projectPaymentType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncomeRecordsTableCompanion.insert({
    required String id,
    required String date,
    required String clientId,
    required String clientName,
    required double amount,
    required String accountId,
    required String invoiceNumber,
    required String description,
    required String status,
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.projectPaymentType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       clientId = Value(clientId),
       clientName = Value(clientName),
       amount = Value(amount),
       accountId = Value(accountId),
       invoiceNumber = Value(invoiceNumber),
       description = Value(description),
       status = Value(status);
  static Insertable<IncomeRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? clientId,
    Expression<String>? clientName,
    Expression<double>? amount,
    Expression<String>? accountId,
    Expression<String>? invoiceNumber,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<String>? projectPaymentType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (clientId != null) 'client_id': clientId,
      if (clientName != null) 'client_name': clientName,
      if (amount != null) 'amount': amount,
      if (accountId != null) 'account_id': accountId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (projectPaymentType != null)
        'project_payment_type': projectPaymentType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncomeRecordsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? clientId,
    Value<String>? clientName,
    Value<double>? amount,
    Value<String>? accountId,
    Value<String>? invoiceNumber,
    Value<String>? description,
    Value<String>? status,
    Value<String?>? projectId,
    Value<String?>? projectName,
    Value<String?>? projectPaymentType,
    Value<int>? rowid,
  }) {
    return IncomeRecordsTableCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      description: description ?? this.description,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectPaymentType: projectPaymentType ?? this.projectPaymentType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (projectPaymentType.present) {
      map['project_payment_type'] = Variable<String>(projectPaymentType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('projectPaymentType: $projectPaymentType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTableTable extends LedgerEntriesTable
    with TableInfo<$LedgerEntriesTableTable, LedgerEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    accountId,
    accountName,
    type,
    category,
    amount,
    reference,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $LedgerEntriesTableTable createAlias(String alias) {
    return $LedgerEntriesTableTable(attachedDatabase, alias);
  }
}

class LedgerEntriesTableData extends DataClass
    implements Insertable<LedgerEntriesTableData> {
  final String id;
  final String date;
  final String accountId;
  final String accountName;
  final String type;
  final String category;
  final double amount;
  final String reference;
  final String description;
  const LedgerEntriesTableData({
    required this.id,
    required this.date,
    required this.accountId,
    required this.accountName,
    required this.type,
    required this.category,
    required this.amount,
    required this.reference,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['account_id'] = Variable<String>(accountId);
    map['account_name'] = Variable<String>(accountName);
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<double>(amount);
    map['reference'] = Variable<String>(reference);
    map['description'] = Variable<String>(description);
    return map;
  }

  LedgerEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesTableCompanion(
      id: Value(id),
      date: Value(date),
      accountId: Value(accountId),
      accountName: Value(accountName),
      type: Value(type),
      category: Value(category),
      amount: Value(amount),
      reference: Value(reference),
      description: Value(description),
    );
  }

  factory LedgerEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      accountId: serializer.fromJson<String>(json['accountId']),
      accountName: serializer.fromJson<String>(json['accountName']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      reference: serializer.fromJson<String>(json['reference']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'accountId': serializer.toJson<String>(accountId),
      'accountName': serializer.toJson<String>(accountName),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double>(amount),
      'reference': serializer.toJson<String>(reference),
      'description': serializer.toJson<String>(description),
    };
  }

  LedgerEntriesTableData copyWith({
    String? id,
    String? date,
    String? accountId,
    String? accountName,
    String? type,
    String? category,
    double? amount,
    String? reference,
    String? description,
  }) => LedgerEntriesTableData(
    id: id ?? this.id,
    date: date ?? this.date,
    accountId: accountId ?? this.accountId,
    accountName: accountName ?? this.accountName,
    type: type ?? this.type,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    reference: reference ?? this.reference,
    description: description ?? this.description,
  );
  LedgerEntriesTableData copyWithCompanion(LedgerEntriesTableCompanion data) {
    return LedgerEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      reference: data.reference.present ? data.reference.value : this.reference,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesTableData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('reference: $reference, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    accountId,
    accountName,
    type,
    category,
    amount,
    reference,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntriesTableData &&
          other.id == this.id &&
          other.date == this.date &&
          other.accountId == this.accountId &&
          other.accountName == this.accountName &&
          other.type == this.type &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.reference == this.reference &&
          other.description == this.description);
}

class LedgerEntriesTableCompanion
    extends UpdateCompanion<LedgerEntriesTableData> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> accountId;
  final Value<String> accountName;
  final Value<String> type;
  final Value<String> category;
  final Value<double> amount;
  final Value<String> reference;
  final Value<String> description;
  final Value<int> rowid;
  const LedgerEntriesTableCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountName = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.reference = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesTableCompanion.insert({
    required String id,
    required String date,
    required String accountId,
    required String accountName,
    required String type,
    required String category,
    required double amount,
    required String reference,
    required String description,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       accountId = Value(accountId),
       accountName = Value(accountName),
       type = Value(type),
       category = Value(category),
       amount = Value(amount),
       reference = Value(reference),
       description = Value(description);
  static Insertable<LedgerEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? accountId,
    Expression<String>? accountName,
    Expression<String>? type,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? reference,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (accountId != null) 'account_id': accountId,
      if (accountName != null) 'account_name': accountName,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (reference != null) 'reference': reference,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? accountId,
    Value<String>? accountName,
    Value<String>? type,
    Value<String>? category,
    Value<double>? amount,
    Value<String>? reference,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return LedgerEntriesTableCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('reference: $reference, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoanRecordsTableTable extends LoanRecordsTable
    with TableInfo<$LoanRecordsTableTable, LoanRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoanRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _borrowerNameMeta = const VerificationMeta(
    'borrowerName',
  );
  @override
  late final GeneratedColumn<String> borrowerName = GeneratedColumn<String>(
    'borrower_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remainingBalanceMeta = const VerificationMeta(
    'remainingBalance',
  );
  @override
  late final GeneratedColumn<double> remainingBalance = GeneratedColumn<double>(
    'remaining_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<Map<String, dynamic>>,
    String
  >
  repayments =
      GeneratedColumn<String>(
        'repayments',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<Map<String, dynamic>>>(
        $LoanRecordsTableTable.$converterrepayments,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    borrowerName,
    type,
    amount,
    remainingBalance,
    startDate,
    endDate,
    status,
    description,
    repayments,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loan_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoanRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('borrower_name')) {
      context.handle(
        _borrowerNameMeta,
        borrowerName.isAcceptableOrUnknown(
          data['borrower_name']!,
          _borrowerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_borrowerNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('remaining_balance')) {
      context.handle(
        _remainingBalanceMeta,
        remainingBalance.isAcceptableOrUnknown(
          data['remaining_balance']!,
          _remainingBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remainingBalanceMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoanRecordsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      borrowerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}borrower_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      remainingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_balance'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      repayments: $LoanRecordsTableTable.$converterrepayments.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repayments'],
        )!,
      ),
    );
  }

  @override
  $LoanRecordsTableTable createAlias(String alias) {
    return $LoanRecordsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Map<String, dynamic>>, String>
  $converterrepayments = const LoanRepaymentListConverter();
}

class LoanRecordsTableData extends DataClass
    implements Insertable<LoanRecordsTableData> {
  final String id;
  final String borrowerName;
  final String type;
  final double amount;
  final double remainingBalance;
  final String startDate;
  final String endDate;
  final String status;
  final String description;
  final List<Map<String, dynamic>> repayments;
  const LoanRecordsTableData({
    required this.id,
    required this.borrowerName,
    required this.type,
    required this.amount,
    required this.remainingBalance,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.description,
    required this.repayments,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['borrower_name'] = Variable<String>(borrowerName);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['remaining_balance'] = Variable<double>(remainingBalance);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['status'] = Variable<String>(status);
    map['description'] = Variable<String>(description);
    {
      map['repayments'] = Variable<String>(
        $LoanRecordsTableTable.$converterrepayments.toSql(repayments),
      );
    }
    return map;
  }

  LoanRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return LoanRecordsTableCompanion(
      id: Value(id),
      borrowerName: Value(borrowerName),
      type: Value(type),
      amount: Value(amount),
      remainingBalance: Value(remainingBalance),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      description: Value(description),
      repayments: Value(repayments),
    );
  }

  factory LoanRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      borrowerName: serializer.fromJson<String>(json['borrowerName']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      remainingBalance: serializer.fromJson<double>(json['remainingBalance']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      status: serializer.fromJson<String>(json['status']),
      description: serializer.fromJson<String>(json['description']),
      repayments: serializer.fromJson<List<Map<String, dynamic>>>(
        json['repayments'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'borrowerName': serializer.toJson<String>(borrowerName),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'remainingBalance': serializer.toJson<double>(remainingBalance),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'status': serializer.toJson<String>(status),
      'description': serializer.toJson<String>(description),
      'repayments': serializer.toJson<List<Map<String, dynamic>>>(repayments),
    };
  }

  LoanRecordsTableData copyWith({
    String? id,
    String? borrowerName,
    String? type,
    double? amount,
    double? remainingBalance,
    String? startDate,
    String? endDate,
    String? status,
    String? description,
    List<Map<String, dynamic>>? repayments,
  }) => LoanRecordsTableData(
    id: id ?? this.id,
    borrowerName: borrowerName ?? this.borrowerName,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    remainingBalance: remainingBalance ?? this.remainingBalance,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    status: status ?? this.status,
    description: description ?? this.description,
    repayments: repayments ?? this.repayments,
  );
  LoanRecordsTableData copyWithCompanion(LoanRecordsTableCompanion data) {
    return LoanRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      borrowerName: data.borrowerName.present
          ? data.borrowerName.value
          : this.borrowerName,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      remainingBalance: data.remainingBalance.present
          ? data.remainingBalance.value
          : this.remainingBalance,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      status: data.status.present ? data.status.value : this.status,
      description: data.description.present
          ? data.description.value
          : this.description,
      repayments: data.repayments.present
          ? data.repayments.value
          : this.repayments,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanRecordsTableData(')
          ..write('id: $id, ')
          ..write('borrowerName: $borrowerName, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('remainingBalance: $remainingBalance, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('repayments: $repayments')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    borrowerName,
    type,
    amount,
    remainingBalance,
    startDate,
    endDate,
    status,
    description,
    repayments,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanRecordsTableData &&
          other.id == this.id &&
          other.borrowerName == this.borrowerName &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.remainingBalance == this.remainingBalance &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.status == this.status &&
          other.description == this.description &&
          other.repayments == this.repayments);
}

class LoanRecordsTableCompanion extends UpdateCompanion<LoanRecordsTableData> {
  final Value<String> id;
  final Value<String> borrowerName;
  final Value<String> type;
  final Value<double> amount;
  final Value<double> remainingBalance;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> status;
  final Value<String> description;
  final Value<List<Map<String, dynamic>>> repayments;
  final Value<int> rowid;
  const LoanRecordsTableCompanion({
    this.id = const Value.absent(),
    this.borrowerName = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.remainingBalance = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    this.repayments = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoanRecordsTableCompanion.insert({
    required String id,
    required String borrowerName,
    required String type,
    required double amount,
    required double remainingBalance,
    required String startDate,
    required String endDate,
    required String status,
    required String description,
    required List<Map<String, dynamic>> repayments,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       borrowerName = Value(borrowerName),
       type = Value(type),
       amount = Value(amount),
       remainingBalance = Value(remainingBalance),
       startDate = Value(startDate),
       endDate = Value(endDate),
       status = Value(status),
       description = Value(description),
       repayments = Value(repayments);
  static Insertable<LoanRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? borrowerName,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<double>? remainingBalance,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? status,
    Expression<String>? description,
    Expression<String>? repayments,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (borrowerName != null) 'borrower_name': borrowerName,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (remainingBalance != null) 'remaining_balance': remainingBalance,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      if (description != null) 'description': description,
      if (repayments != null) 'repayments': repayments,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoanRecordsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? borrowerName,
    Value<String>? type,
    Value<double>? amount,
    Value<double>? remainingBalance,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<String>? status,
    Value<String>? description,
    Value<List<Map<String, dynamic>>>? repayments,
    Value<int>? rowid,
  }) {
    return LoanRecordsTableCompanion(
      id: id ?? this.id,
      borrowerName: borrowerName ?? this.borrowerName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      repayments: repayments ?? this.repayments,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (borrowerName.present) {
      map['borrower_name'] = Variable<String>(borrowerName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (remainingBalance.present) {
      map['remaining_balance'] = Variable<double>(remainingBalance.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (repayments.present) {
      map['repayments'] = Variable<String>(
        $LoanRecordsTableTable.$converterrepayments.toSql(repayments.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoanRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('borrowerName: $borrowerName, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('remainingBalance: $remainingBalance, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('repayments: $repayments, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdvanceRecordsTableTable extends AdvanceRecordsTable
    with TableInfo<$AdvanceRecordsTableTable, AdvanceRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvanceRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeNameMeta = const VerificationMeta(
    'employeeName',
  );
  @override
  late final GeneratedColumn<String> employeeName = GeneratedColumn<String>(
    'employee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestDateMeta = const VerificationMeta(
    'requestDate',
  );
  @override
  late final GeneratedColumn<String> requestDate = GeneratedColumn<String>(
    'request_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repaymentMonthsMeta = const VerificationMeta(
    'repaymentMonths',
  );
  @override
  late final GeneratedColumn<int> repaymentMonths = GeneratedColumn<int>(
    'repayment_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountRepaidMeta = const VerificationMeta(
    'amountRepaid',
  );
  @override
  late final GeneratedColumn<double> amountRepaid = GeneratedColumn<double>(
    'amount_repaid',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employeeId,
    employeeName,
    amount,
    requestDate,
    reason,
    repaymentMonths,
    amountRepaid,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advance_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvanceRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('employee_name')) {
      context.handle(
        _employeeNameMeta,
        employeeName.isAcceptableOrUnknown(
          data['employee_name']!,
          _employeeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('request_date')) {
      context.handle(
        _requestDateMeta,
        requestDate.isAcceptableOrUnknown(
          data['request_date']!,
          _requestDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestDateMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('repayment_months')) {
      context.handle(
        _repaymentMonthsMeta,
        repaymentMonths.isAcceptableOrUnknown(
          data['repayment_months']!,
          _repaymentMonthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repaymentMonthsMeta);
    }
    if (data.containsKey('amount_repaid')) {
      context.handle(
        _amountRepaidMeta,
        amountRepaid.isAcceptableOrUnknown(
          data['amount_repaid']!,
          _amountRepaidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountRepaidMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdvanceRecordsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvanceRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      employeeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      requestDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_date'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      repaymentMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repayment_months'],
      )!,
      amountRepaid: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_repaid'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $AdvanceRecordsTableTable createAlias(String alias) {
    return $AdvanceRecordsTableTable(attachedDatabase, alias);
  }
}

class AdvanceRecordsTableData extends DataClass
    implements Insertable<AdvanceRecordsTableData> {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String requestDate;
  final String reason;
  final int repaymentMonths;
  final double amountRepaid;
  final String status;
  const AdvanceRecordsTableData({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.requestDate,
    required this.reason,
    required this.repaymentMonths,
    required this.amountRepaid,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['employee_id'] = Variable<String>(employeeId);
    map['employee_name'] = Variable<String>(employeeName);
    map['amount'] = Variable<double>(amount);
    map['request_date'] = Variable<String>(requestDate);
    map['reason'] = Variable<String>(reason);
    map['repayment_months'] = Variable<int>(repaymentMonths);
    map['amount_repaid'] = Variable<double>(amountRepaid);
    map['status'] = Variable<String>(status);
    return map;
  }

  AdvanceRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return AdvanceRecordsTableCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      employeeName: Value(employeeName),
      amount: Value(amount),
      requestDate: Value(requestDate),
      reason: Value(reason),
      repaymentMonths: Value(repaymentMonths),
      amountRepaid: Value(amountRepaid),
      status: Value(status),
    );
  }

  factory AdvanceRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvanceRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      employeeName: serializer.fromJson<String>(json['employeeName']),
      amount: serializer.fromJson<double>(json['amount']),
      requestDate: serializer.fromJson<String>(json['requestDate']),
      reason: serializer.fromJson<String>(json['reason']),
      repaymentMonths: serializer.fromJson<int>(json['repaymentMonths']),
      amountRepaid: serializer.fromJson<double>(json['amountRepaid']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'employeeId': serializer.toJson<String>(employeeId),
      'employeeName': serializer.toJson<String>(employeeName),
      'amount': serializer.toJson<double>(amount),
      'requestDate': serializer.toJson<String>(requestDate),
      'reason': serializer.toJson<String>(reason),
      'repaymentMonths': serializer.toJson<int>(repaymentMonths),
      'amountRepaid': serializer.toJson<double>(amountRepaid),
      'status': serializer.toJson<String>(status),
    };
  }

  AdvanceRecordsTableData copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    String? requestDate,
    String? reason,
    int? repaymentMonths,
    double? amountRepaid,
    String? status,
  }) => AdvanceRecordsTableData(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    employeeName: employeeName ?? this.employeeName,
    amount: amount ?? this.amount,
    requestDate: requestDate ?? this.requestDate,
    reason: reason ?? this.reason,
    repaymentMonths: repaymentMonths ?? this.repaymentMonths,
    amountRepaid: amountRepaid ?? this.amountRepaid,
    status: status ?? this.status,
  );
  AdvanceRecordsTableData copyWithCompanion(AdvanceRecordsTableCompanion data) {
    return AdvanceRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      employeeName: data.employeeName.present
          ? data.employeeName.value
          : this.employeeName,
      amount: data.amount.present ? data.amount.value : this.amount,
      requestDate: data.requestDate.present
          ? data.requestDate.value
          : this.requestDate,
      reason: data.reason.present ? data.reason.value : this.reason,
      repaymentMonths: data.repaymentMonths.present
          ? data.repaymentMonths.value
          : this.repaymentMonths,
      amountRepaid: data.amountRepaid.present
          ? data.amountRepaid.value
          : this.amountRepaid,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvanceRecordsTableData(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('amount: $amount, ')
          ..write('requestDate: $requestDate, ')
          ..write('reason: $reason, ')
          ..write('repaymentMonths: $repaymentMonths, ')
          ..write('amountRepaid: $amountRepaid, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    employeeName,
    amount,
    requestDate,
    reason,
    repaymentMonths,
    amountRepaid,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvanceRecordsTableData &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.employeeName == this.employeeName &&
          other.amount == this.amount &&
          other.requestDate == this.requestDate &&
          other.reason == this.reason &&
          other.repaymentMonths == this.repaymentMonths &&
          other.amountRepaid == this.amountRepaid &&
          other.status == this.status);
}

class AdvanceRecordsTableCompanion
    extends UpdateCompanion<AdvanceRecordsTableData> {
  final Value<String> id;
  final Value<String> employeeId;
  final Value<String> employeeName;
  final Value<double> amount;
  final Value<String> requestDate;
  final Value<String> reason;
  final Value<int> repaymentMonths;
  final Value<double> amountRepaid;
  final Value<String> status;
  final Value<int> rowid;
  const AdvanceRecordsTableCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.employeeName = const Value.absent(),
    this.amount = const Value.absent(),
    this.requestDate = const Value.absent(),
    this.reason = const Value.absent(),
    this.repaymentMonths = const Value.absent(),
    this.amountRepaid = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdvanceRecordsTableCompanion.insert({
    required String id,
    required String employeeId,
    required String employeeName,
    required double amount,
    required String requestDate,
    required String reason,
    required int repaymentMonths,
    required double amountRepaid,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       employeeId = Value(employeeId),
       employeeName = Value(employeeName),
       amount = Value(amount),
       requestDate = Value(requestDate),
       reason = Value(reason),
       repaymentMonths = Value(repaymentMonths),
       amountRepaid = Value(amountRepaid),
       status = Value(status);
  static Insertable<AdvanceRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? employeeId,
    Expression<String>? employeeName,
    Expression<double>? amount,
    Expression<String>? requestDate,
    Expression<String>? reason,
    Expression<int>? repaymentMonths,
    Expression<double>? amountRepaid,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (amount != null) 'amount': amount,
      if (requestDate != null) 'request_date': requestDate,
      if (reason != null) 'reason': reason,
      if (repaymentMonths != null) 'repayment_months': repaymentMonths,
      if (amountRepaid != null) 'amount_repaid': amountRepaid,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdvanceRecordsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? employeeId,
    Value<String>? employeeName,
    Value<double>? amount,
    Value<String>? requestDate,
    Value<String>? reason,
    Value<int>? repaymentMonths,
    Value<double>? amountRepaid,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return AdvanceRecordsTableCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      requestDate: requestDate ?? this.requestDate,
      reason: reason ?? this.reason,
      repaymentMonths: repaymentMonths ?? this.repaymentMonths,
      amountRepaid: amountRepaid ?? this.amountRepaid,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (employeeName.present) {
      map['employee_name'] = Variable<String>(employeeName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (requestDate.present) {
      map['request_date'] = Variable<String>(requestDate.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (repaymentMonths.present) {
      map['repayment_months'] = Variable<int>(repaymentMonths.value);
    }
    if (amountRepaid.present) {
      map['amount_repaid'] = Variable<double>(amountRepaid.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvanceRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('amount: $amount, ')
          ..write('requestDate: $requestDate, ')
          ..write('reason: $reason, ')
          ..write('repaymentMonths: $repaymentMonths, ')
          ..write('amountRepaid: $amountRepaid, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordsTableTable extends AttendanceRecordsTable
    with TableInfo<$AttendanceRecordsTableTable, AttendanceRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeNameMeta = const VerificationMeta(
    'employeeName',
  );
  @override
  late final GeneratedColumn<String> employeeName = GeneratedColumn<String>(
    'employee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkInMeta = const VerificationMeta(
    'checkIn',
  );
  @override
  late final GeneratedColumn<String> checkIn = GeneratedColumn<String>(
    'check_in',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkOutMeta = const VerificationMeta(
    'checkOut',
  );
  @override
  late final GeneratedColumn<String> checkOut = GeneratedColumn<String>(
    'check_out',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employeeId,
    employeeName,
    date,
    status,
    checkIn,
    checkOut,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('employee_name')) {
      context.handle(
        _employeeNameMeta,
        employeeName.isAcceptableOrUnknown(
          data['employee_name']!,
          _employeeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('check_in')) {
      context.handle(
        _checkInMeta,
        checkIn.isAcceptableOrUnknown(data['check_in']!, _checkInMeta),
      );
    }
    if (data.containsKey('check_out')) {
      context.handle(
        _checkOutMeta,
        checkOut.isAcceptableOrUnknown(data['check_out']!, _checkOutMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceRecordsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      employeeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      checkIn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}check_in'],
      ),
      checkOut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}check_out'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $AttendanceRecordsTableTable createAlias(String alias) {
    return $AttendanceRecordsTableTable(attachedDatabase, alias);
  }
}

class AttendanceRecordsTableData extends DataClass
    implements Insertable<AttendanceRecordsTableData> {
  final String id;
  final String employeeId;
  final String employeeName;
  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String? notes;
  const AttendanceRecordsTableData({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['employee_id'] = Variable<String>(employeeId);
    map['employee_name'] = Variable<String>(employeeName);
    map['date'] = Variable<String>(date);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || checkIn != null) {
      map['check_in'] = Variable<String>(checkIn);
    }
    if (!nullToAbsent || checkOut != null) {
      map['check_out'] = Variable<String>(checkOut);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  AttendanceRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordsTableCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      employeeName: Value(employeeName),
      date: Value(date),
      status: Value(status),
      checkIn: checkIn == null && nullToAbsent
          ? const Value.absent()
          : Value(checkIn),
      checkOut: checkOut == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOut),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory AttendanceRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      employeeName: serializer.fromJson<String>(json['employeeName']),
      date: serializer.fromJson<String>(json['date']),
      status: serializer.fromJson<String>(json['status']),
      checkIn: serializer.fromJson<String?>(json['checkIn']),
      checkOut: serializer.fromJson<String?>(json['checkOut']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'employeeId': serializer.toJson<String>(employeeId),
      'employeeName': serializer.toJson<String>(employeeName),
      'date': serializer.toJson<String>(date),
      'status': serializer.toJson<String>(status),
      'checkIn': serializer.toJson<String?>(checkIn),
      'checkOut': serializer.toJson<String?>(checkOut),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  AttendanceRecordsTableData copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? date,
    String? status,
    Value<String?> checkIn = const Value.absent(),
    Value<String?> checkOut = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => AttendanceRecordsTableData(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    employeeName: employeeName ?? this.employeeName,
    date: date ?? this.date,
    status: status ?? this.status,
    checkIn: checkIn.present ? checkIn.value : this.checkIn,
    checkOut: checkOut.present ? checkOut.value : this.checkOut,
    notes: notes.present ? notes.value : this.notes,
  );
  AttendanceRecordsTableData copyWithCompanion(
    AttendanceRecordsTableCompanion data,
  ) {
    return AttendanceRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      employeeName: data.employeeName.present
          ? data.employeeName.value
          : this.employeeName,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      checkIn: data.checkIn.present ? data.checkIn.value : this.checkIn,
      checkOut: data.checkOut.present ? data.checkOut.value : this.checkOut,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsTableData(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('checkIn: $checkIn, ')
          ..write('checkOut: $checkOut, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    employeeName,
    date,
    status,
    checkIn,
    checkOut,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecordsTableData &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.employeeName == this.employeeName &&
          other.date == this.date &&
          other.status == this.status &&
          other.checkIn == this.checkIn &&
          other.checkOut == this.checkOut &&
          other.notes == this.notes);
}

class AttendanceRecordsTableCompanion
    extends UpdateCompanion<AttendanceRecordsTableData> {
  final Value<String> id;
  final Value<String> employeeId;
  final Value<String> employeeName;
  final Value<String> date;
  final Value<String> status;
  final Value<String?> checkIn;
  final Value<String?> checkOut;
  final Value<String?> notes;
  final Value<int> rowid;
  const AttendanceRecordsTableCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.employeeName = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.checkIn = const Value.absent(),
    this.checkOut = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceRecordsTableCompanion.insert({
    required String id,
    required String employeeId,
    required String employeeName,
    required String date,
    required String status,
    this.checkIn = const Value.absent(),
    this.checkOut = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       employeeId = Value(employeeId),
       employeeName = Value(employeeName),
       date = Value(date),
       status = Value(status);
  static Insertable<AttendanceRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? employeeId,
    Expression<String>? employeeName,
    Expression<String>? date,
    Expression<String>? status,
    Expression<String>? checkIn,
    Expression<String>? checkOut,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (checkIn != null) 'check_in': checkIn,
      if (checkOut != null) 'check_out': checkOut,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceRecordsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? employeeId,
    Value<String>? employeeName,
    Value<String>? date,
    Value<String>? status,
    Value<String?>? checkIn,
    Value<String?>? checkOut,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return AttendanceRecordsTableCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      status: status ?? this.status,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (employeeName.present) {
      map['employee_name'] = Variable<String>(employeeName.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (checkIn.present) {
      map['check_in'] = Variable<String>(checkIn.value);
    }
    if (checkOut.present) {
      map['check_out'] = Variable<String>(checkOut.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('checkIn: $checkIn, ')
          ..write('checkOut: $checkOut, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTableTable extends EmployeesTable
    with TableInfo<$EmployeesTableTable, EmployeesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> phones =
      GeneratedColumn<String>(
        'phones',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($EmployeesTableTable.$converterphones);
  static const VerificationMeta _cnicMeta = const VerificationMeta('cnic');
  @override
  late final GeneratedColumn<String> cnic = GeneratedColumn<String>(
    'cnic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _designationMeta = const VerificationMeta(
    'designation',
  );
  @override
  late final GeneratedColumn<String> designation = GeneratedColumn<String>(
    'designation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departmentMeta = const VerificationMeta(
    'department',
  );
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joiningDateMeta = const VerificationMeta(
    'joiningDate',
  );
  @override
  late final GeneratedColumn<String> joiningDate = GeneratedColumn<String>(
    'joining_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leavingDateMeta = const VerificationMeta(
    'leavingDate',
  );
  @override
  late final GeneratedColumn<String> leavingDate = GeneratedColumn<String>(
    'leaving_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryTypeMeta = const VerificationMeta(
    'salaryType',
  );
  @override
  late final GeneratedColumn<String> salaryType = GeneratedColumn<String>(
    'salary_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseSalaryMeta = const VerificationMeta(
    'baseSalary',
  );
  @override
  late final GeneratedColumn<double> baseSalary = GeneratedColumn<double>(
    'base_salary',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    phones,
    cnic,
    designation,
    department,
    joiningDate,
    leavingDate,
    status,
    salaryType,
    baseSalary,
    paymentMethod,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('cnic')) {
      context.handle(
        _cnicMeta,
        cnic.isAcceptableOrUnknown(data['cnic']!, _cnicMeta),
      );
    }
    if (data.containsKey('designation')) {
      context.handle(
        _designationMeta,
        designation.isAcceptableOrUnknown(
          data['designation']!,
          _designationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_designationMeta);
    }
    if (data.containsKey('department')) {
      context.handle(
        _departmentMeta,
        department.isAcceptableOrUnknown(data['department']!, _departmentMeta),
      );
    } else if (isInserting) {
      context.missing(_departmentMeta);
    }
    if (data.containsKey('joining_date')) {
      context.handle(
        _joiningDateMeta,
        joiningDate.isAcceptableOrUnknown(
          data['joining_date']!,
          _joiningDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_joiningDateMeta);
    }
    if (data.containsKey('leaving_date')) {
      context.handle(
        _leavingDateMeta,
        leavingDate.isAcceptableOrUnknown(
          data['leaving_date']!,
          _leavingDateMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('salary_type')) {
      context.handle(
        _salaryTypeMeta,
        salaryType.isAcceptableOrUnknown(data['salary_type']!, _salaryTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_salaryTypeMeta);
    }
    if (data.containsKey('base_salary')) {
      context.handle(
        _baseSalaryMeta,
        baseSalary.isAcceptableOrUnknown(data['base_salary']!, _baseSalaryMeta),
      );
    } else if (isInserting) {
      context.missing(_baseSalaryMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phones: $EmployeesTableTable.$converterphones.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}phones'],
        )!,
      ),
      cnic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cnic'],
      )!,
      designation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}designation'],
      )!,
      department: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department'],
      )!,
      joiningDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joining_date'],
      )!,
      leavingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}leaving_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      salaryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary_type'],
      )!,
      baseSalary: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_salary'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
    );
  }

  @override
  $EmployeesTableTable createAlias(String alias) {
    return $EmployeesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterphones =
      const StringListConverter();
}

class EmployeesTableData extends DataClass
    implements Insertable<EmployeesTableData> {
  final String id;
  final String name;
  final String email;
  final List<String> phones;
  final String cnic;
  final String designation;
  final String department;
  final String joiningDate;
  final String? leavingDate;
  final String status;
  final String salaryType;
  final double baseSalary;
  final String paymentMethod;
  const EmployeesTableData({
    required this.id,
    required this.name,
    required this.email,
    required this.phones,
    required this.cnic,
    required this.designation,
    required this.department,
    required this.joiningDate,
    this.leavingDate,
    required this.status,
    required this.salaryType,
    required this.baseSalary,
    required this.paymentMethod,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    {
      map['phones'] = Variable<String>(
        $EmployeesTableTable.$converterphones.toSql(phones),
      );
    }
    map['cnic'] = Variable<String>(cnic);
    map['designation'] = Variable<String>(designation);
    map['department'] = Variable<String>(department);
    map['joining_date'] = Variable<String>(joiningDate);
    if (!nullToAbsent || leavingDate != null) {
      map['leaving_date'] = Variable<String>(leavingDate);
    }
    map['status'] = Variable<String>(status);
    map['salary_type'] = Variable<String>(salaryType);
    map['base_salary'] = Variable<double>(baseSalary);
    map['payment_method'] = Variable<String>(paymentMethod);
    return map;
  }

  EmployeesTableCompanion toCompanion(bool nullToAbsent) {
    return EmployeesTableCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      phones: Value(phones),
      cnic: Value(cnic),
      designation: Value(designation),
      department: Value(department),
      joiningDate: Value(joiningDate),
      leavingDate: leavingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(leavingDate),
      status: Value(status),
      salaryType: Value(salaryType),
      baseSalary: Value(baseSalary),
      paymentMethod: Value(paymentMethod),
    );
  }

  factory EmployeesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      phones: serializer.fromJson<List<String>>(json['phones']),
      cnic: serializer.fromJson<String>(json['cnic']),
      designation: serializer.fromJson<String>(json['designation']),
      department: serializer.fromJson<String>(json['department']),
      joiningDate: serializer.fromJson<String>(json['joiningDate']),
      leavingDate: serializer.fromJson<String?>(json['leavingDate']),
      status: serializer.fromJson<String>(json['status']),
      salaryType: serializer.fromJson<String>(json['salaryType']),
      baseSalary: serializer.fromJson<double>(json['baseSalary']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'phones': serializer.toJson<List<String>>(phones),
      'cnic': serializer.toJson<String>(cnic),
      'designation': serializer.toJson<String>(designation),
      'department': serializer.toJson<String>(department),
      'joiningDate': serializer.toJson<String>(joiningDate),
      'leavingDate': serializer.toJson<String?>(leavingDate),
      'status': serializer.toJson<String>(status),
      'salaryType': serializer.toJson<String>(salaryType),
      'baseSalary': serializer.toJson<double>(baseSalary),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
    };
  }

  EmployeesTableData copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? phones,
    String? cnic,
    String? designation,
    String? department,
    String? joiningDate,
    Value<String?> leavingDate = const Value.absent(),
    String? status,
    String? salaryType,
    double? baseSalary,
    String? paymentMethod,
  }) => EmployeesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phones: phones ?? this.phones,
    cnic: cnic ?? this.cnic,
    designation: designation ?? this.designation,
    department: department ?? this.department,
    joiningDate: joiningDate ?? this.joiningDate,
    leavingDate: leavingDate.present ? leavingDate.value : this.leavingDate,
    status: status ?? this.status,
    salaryType: salaryType ?? this.salaryType,
    baseSalary: baseSalary ?? this.baseSalary,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );
  EmployeesTableData copyWithCompanion(EmployeesTableCompanion data) {
    return EmployeesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phones: data.phones.present ? data.phones.value : this.phones,
      cnic: data.cnic.present ? data.cnic.value : this.cnic,
      designation: data.designation.present
          ? data.designation.value
          : this.designation,
      department: data.department.present
          ? data.department.value
          : this.department,
      joiningDate: data.joiningDate.present
          ? data.joiningDate.value
          : this.joiningDate,
      leavingDate: data.leavingDate.present
          ? data.leavingDate.value
          : this.leavingDate,
      status: data.status.present ? data.status.value : this.status,
      salaryType: data.salaryType.present
          ? data.salaryType.value
          : this.salaryType,
      baseSalary: data.baseSalary.present
          ? data.baseSalary.value
          : this.baseSalary,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phones: $phones, ')
          ..write('cnic: $cnic, ')
          ..write('designation: $designation, ')
          ..write('department: $department, ')
          ..write('joiningDate: $joiningDate, ')
          ..write('leavingDate: $leavingDate, ')
          ..write('status: $status, ')
          ..write('salaryType: $salaryType, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('paymentMethod: $paymentMethod')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    phones,
    cnic,
    designation,
    department,
    joiningDate,
    leavingDate,
    status,
    salaryType,
    baseSalary,
    paymentMethod,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.phones == this.phones &&
          other.cnic == this.cnic &&
          other.designation == this.designation &&
          other.department == this.department &&
          other.joiningDate == this.joiningDate &&
          other.leavingDate == this.leavingDate &&
          other.status == this.status &&
          other.salaryType == this.salaryType &&
          other.baseSalary == this.baseSalary &&
          other.paymentMethod == this.paymentMethod);
}

class EmployeesTableCompanion extends UpdateCompanion<EmployeesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<List<String>> phones;
  final Value<String> cnic;
  final Value<String> designation;
  final Value<String> department;
  final Value<String> joiningDate;
  final Value<String?> leavingDate;
  final Value<String> status;
  final Value<String> salaryType;
  final Value<double> baseSalary;
  final Value<String> paymentMethod;
  final Value<int> rowid;
  const EmployeesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phones = const Value.absent(),
    this.cnic = const Value.absent(),
    this.designation = const Value.absent(),
    this.department = const Value.absent(),
    this.joiningDate = const Value.absent(),
    this.leavingDate = const Value.absent(),
    this.status = const Value.absent(),
    this.salaryType = const Value.absent(),
    this.baseSalary = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeesTableCompanion.insert({
    required String id,
    required String name,
    required String email,
    required List<String> phones,
    this.cnic = const Value.absent(),
    required String designation,
    required String department,
    required String joiningDate,
    this.leavingDate = const Value.absent(),
    required String status,
    required String salaryType,
    required double baseSalary,
    required String paymentMethod,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       email = Value(email),
       phones = Value(phones),
       designation = Value(designation),
       department = Value(department),
       joiningDate = Value(joiningDate),
       status = Value(status),
       salaryType = Value(salaryType),
       baseSalary = Value(baseSalary),
       paymentMethod = Value(paymentMethod);
  static Insertable<EmployeesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phones,
    Expression<String>? cnic,
    Expression<String>? designation,
    Expression<String>? department,
    Expression<String>? joiningDate,
    Expression<String>? leavingDate,
    Expression<String>? status,
    Expression<String>? salaryType,
    Expression<double>? baseSalary,
    Expression<String>? paymentMethod,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phones != null) 'phones': phones,
      if (cnic != null) 'cnic': cnic,
      if (designation != null) 'designation': designation,
      if (department != null) 'department': department,
      if (joiningDate != null) 'joining_date': joiningDate,
      if (leavingDate != null) 'leaving_date': leavingDate,
      if (status != null) 'status': status,
      if (salaryType != null) 'salary_type': salaryType,
      if (baseSalary != null) 'base_salary': baseSalary,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? email,
    Value<List<String>>? phones,
    Value<String>? cnic,
    Value<String>? designation,
    Value<String>? department,
    Value<String>? joiningDate,
    Value<String?>? leavingDate,
    Value<String>? status,
    Value<String>? salaryType,
    Value<double>? baseSalary,
    Value<String>? paymentMethod,
    Value<int>? rowid,
  }) {
    return EmployeesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phones: phones ?? this.phones,
      cnic: cnic ?? this.cnic,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      joiningDate: joiningDate ?? this.joiningDate,
      leavingDate: leavingDate ?? this.leavingDate,
      status: status ?? this.status,
      salaryType: salaryType ?? this.salaryType,
      baseSalary: baseSalary ?? this.baseSalary,
      paymentMethod: paymentMethod ?? this.paymentMethod,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phones.present) {
      map['phones'] = Variable<String>(
        $EmployeesTableTable.$converterphones.toSql(phones.value),
      );
    }
    if (cnic.present) {
      map['cnic'] = Variable<String>(cnic.value);
    }
    if (designation.present) {
      map['designation'] = Variable<String>(designation.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (joiningDate.present) {
      map['joining_date'] = Variable<String>(joiningDate.value);
    }
    if (leavingDate.present) {
      map['leaving_date'] = Variable<String>(leavingDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (salaryType.present) {
      map['salary_type'] = Variable<String>(salaryType.value);
    }
    if (baseSalary.present) {
      map['base_salary'] = Variable<double>(baseSalary.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phones: $phones, ')
          ..write('cnic: $cnic, ')
          ..write('designation: $designation, ')
          ..write('department: $department, ')
          ..write('joiningDate: $joiningDate, ')
          ..write('leavingDate: $leavingDate, ')
          ..write('status: $status, ')
          ..write('salaryType: $salaryType, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalaryRecordsTableTable extends SalaryRecordsTable
    with TableInfo<$SalaryRecordsTableTable, SalaryRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalaryRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeNameMeta = const VerificationMeta(
    'employeeName',
  );
  @override
  late final GeneratedColumn<String> employeeName = GeneratedColumn<String>(
    'employee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payPeriodMeta = const VerificationMeta(
    'payPeriod',
  );
  @override
  late final GeneratedColumn<String> payPeriod = GeneratedColumn<String>(
    'pay_period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseSalaryMeta = const VerificationMeta(
    'baseSalary',
  );
  @override
  late final GeneratedColumn<double> baseSalary = GeneratedColumn<double>(
    'base_salary',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowancesMeta = const VerificationMeta(
    'allowances',
  );
  @override
  late final GeneratedColumn<double> allowances = GeneratedColumn<double>(
    'allowances',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deductionsMeta = const VerificationMeta(
    'deductions',
  );
  @override
  late final GeneratedColumn<double> deductions = GeneratedColumn<double>(
    'deductions',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netPaidMeta = const VerificationMeta(
    'netPaid',
  );
  @override
  late final GeneratedColumn<double> netPaid = GeneratedColumn<double>(
    'net_paid',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<String> paymentDate = GeneratedColumn<String>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employeeId,
    employeeName,
    payPeriod,
    baseSalary,
    allowances,
    deductions,
    netPaid,
    paymentDate,
    status,
    paymentMethod,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'salary_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalaryRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('employee_name')) {
      context.handle(
        _employeeNameMeta,
        employeeName.isAcceptableOrUnknown(
          data['employee_name']!,
          _employeeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNameMeta);
    }
    if (data.containsKey('pay_period')) {
      context.handle(
        _payPeriodMeta,
        payPeriod.isAcceptableOrUnknown(data['pay_period']!, _payPeriodMeta),
      );
    } else if (isInserting) {
      context.missing(_payPeriodMeta);
    }
    if (data.containsKey('base_salary')) {
      context.handle(
        _baseSalaryMeta,
        baseSalary.isAcceptableOrUnknown(data['base_salary']!, _baseSalaryMeta),
      );
    } else if (isInserting) {
      context.missing(_baseSalaryMeta);
    }
    if (data.containsKey('allowances')) {
      context.handle(
        _allowancesMeta,
        allowances.isAcceptableOrUnknown(data['allowances']!, _allowancesMeta),
      );
    } else if (isInserting) {
      context.missing(_allowancesMeta);
    }
    if (data.containsKey('deductions')) {
      context.handle(
        _deductionsMeta,
        deductions.isAcceptableOrUnknown(data['deductions']!, _deductionsMeta),
      );
    } else if (isInserting) {
      context.missing(_deductionsMeta);
    }
    if (data.containsKey('net_paid')) {
      context.handle(
        _netPaidMeta,
        netPaid.isAcceptableOrUnknown(data['net_paid']!, _netPaidMeta),
      );
    } else if (isInserting) {
      context.missing(_netPaidMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalaryRecordsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalaryRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      employeeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_name'],
      )!,
      payPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pay_period'],
      )!,
      baseSalary: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_salary'],
      )!,
      allowances: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}allowances'],
      )!,
      deductions: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deductions'],
      )!,
      netPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}net_paid'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
    );
  }

  @override
  $SalaryRecordsTableTable createAlias(String alias) {
    return $SalaryRecordsTableTable(attachedDatabase, alias);
  }
}

class SalaryRecordsTableData extends DataClass
    implements Insertable<SalaryRecordsTableData> {
  final String id;
  final String employeeId;
  final String employeeName;
  final String payPeriod;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double netPaid;
  final String paymentDate;
  final String status;
  final String paymentMethod;
  const SalaryRecordsTableData({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.payPeriod,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.netPaid,
    required this.paymentDate,
    required this.status,
    required this.paymentMethod,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['employee_id'] = Variable<String>(employeeId);
    map['employee_name'] = Variable<String>(employeeName);
    map['pay_period'] = Variable<String>(payPeriod);
    map['base_salary'] = Variable<double>(baseSalary);
    map['allowances'] = Variable<double>(allowances);
    map['deductions'] = Variable<double>(deductions);
    map['net_paid'] = Variable<double>(netPaid);
    map['payment_date'] = Variable<String>(paymentDate);
    map['status'] = Variable<String>(status);
    map['payment_method'] = Variable<String>(paymentMethod);
    return map;
  }

  SalaryRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return SalaryRecordsTableCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      employeeName: Value(employeeName),
      payPeriod: Value(payPeriod),
      baseSalary: Value(baseSalary),
      allowances: Value(allowances),
      deductions: Value(deductions),
      netPaid: Value(netPaid),
      paymentDate: Value(paymentDate),
      status: Value(status),
      paymentMethod: Value(paymentMethod),
    );
  }

  factory SalaryRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalaryRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      employeeName: serializer.fromJson<String>(json['employeeName']),
      payPeriod: serializer.fromJson<String>(json['payPeriod']),
      baseSalary: serializer.fromJson<double>(json['baseSalary']),
      allowances: serializer.fromJson<double>(json['allowances']),
      deductions: serializer.fromJson<double>(json['deductions']),
      netPaid: serializer.fromJson<double>(json['netPaid']),
      paymentDate: serializer.fromJson<String>(json['paymentDate']),
      status: serializer.fromJson<String>(json['status']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'employeeId': serializer.toJson<String>(employeeId),
      'employeeName': serializer.toJson<String>(employeeName),
      'payPeriod': serializer.toJson<String>(payPeriod),
      'baseSalary': serializer.toJson<double>(baseSalary),
      'allowances': serializer.toJson<double>(allowances),
      'deductions': serializer.toJson<double>(deductions),
      'netPaid': serializer.toJson<double>(netPaid),
      'paymentDate': serializer.toJson<String>(paymentDate),
      'status': serializer.toJson<String>(status),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
    };
  }

  SalaryRecordsTableData copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? payPeriod,
    double? baseSalary,
    double? allowances,
    double? deductions,
    double? netPaid,
    String? paymentDate,
    String? status,
    String? paymentMethod,
  }) => SalaryRecordsTableData(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    employeeName: employeeName ?? this.employeeName,
    payPeriod: payPeriod ?? this.payPeriod,
    baseSalary: baseSalary ?? this.baseSalary,
    allowances: allowances ?? this.allowances,
    deductions: deductions ?? this.deductions,
    netPaid: netPaid ?? this.netPaid,
    paymentDate: paymentDate ?? this.paymentDate,
    status: status ?? this.status,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );
  SalaryRecordsTableData copyWithCompanion(SalaryRecordsTableCompanion data) {
    return SalaryRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      employeeName: data.employeeName.present
          ? data.employeeName.value
          : this.employeeName,
      payPeriod: data.payPeriod.present ? data.payPeriod.value : this.payPeriod,
      baseSalary: data.baseSalary.present
          ? data.baseSalary.value
          : this.baseSalary,
      allowances: data.allowances.present
          ? data.allowances.value
          : this.allowances,
      deductions: data.deductions.present
          ? data.deductions.value
          : this.deductions,
      netPaid: data.netPaid.present ? data.netPaid.value : this.netPaid,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      status: data.status.present ? data.status.value : this.status,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalaryRecordsTableData(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('payPeriod: $payPeriod, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('allowances: $allowances, ')
          ..write('deductions: $deductions, ')
          ..write('netPaid: $netPaid, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    employeeName,
    payPeriod,
    baseSalary,
    allowances,
    deductions,
    netPaid,
    paymentDate,
    status,
    paymentMethod,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalaryRecordsTableData &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.employeeName == this.employeeName &&
          other.payPeriod == this.payPeriod &&
          other.baseSalary == this.baseSalary &&
          other.allowances == this.allowances &&
          other.deductions == this.deductions &&
          other.netPaid == this.netPaid &&
          other.paymentDate == this.paymentDate &&
          other.status == this.status &&
          other.paymentMethod == this.paymentMethod);
}

class SalaryRecordsTableCompanion
    extends UpdateCompanion<SalaryRecordsTableData> {
  final Value<String> id;
  final Value<String> employeeId;
  final Value<String> employeeName;
  final Value<String> payPeriod;
  final Value<double> baseSalary;
  final Value<double> allowances;
  final Value<double> deductions;
  final Value<double> netPaid;
  final Value<String> paymentDate;
  final Value<String> status;
  final Value<String> paymentMethod;
  final Value<int> rowid;
  const SalaryRecordsTableCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.employeeName = const Value.absent(),
    this.payPeriod = const Value.absent(),
    this.baseSalary = const Value.absent(),
    this.allowances = const Value.absent(),
    this.deductions = const Value.absent(),
    this.netPaid = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalaryRecordsTableCompanion.insert({
    required String id,
    required String employeeId,
    required String employeeName,
    required String payPeriod,
    required double baseSalary,
    required double allowances,
    required double deductions,
    required double netPaid,
    required String paymentDate,
    required String status,
    required String paymentMethod,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       employeeId = Value(employeeId),
       employeeName = Value(employeeName),
       payPeriod = Value(payPeriod),
       baseSalary = Value(baseSalary),
       allowances = Value(allowances),
       deductions = Value(deductions),
       netPaid = Value(netPaid),
       paymentDate = Value(paymentDate),
       status = Value(status),
       paymentMethod = Value(paymentMethod);
  static Insertable<SalaryRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? employeeId,
    Expression<String>? employeeName,
    Expression<String>? payPeriod,
    Expression<double>? baseSalary,
    Expression<double>? allowances,
    Expression<double>? deductions,
    Expression<double>? netPaid,
    Expression<String>? paymentDate,
    Expression<String>? status,
    Expression<String>? paymentMethod,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (payPeriod != null) 'pay_period': payPeriod,
      if (baseSalary != null) 'base_salary': baseSalary,
      if (allowances != null) 'allowances': allowances,
      if (deductions != null) 'deductions': deductions,
      if (netPaid != null) 'net_paid': netPaid,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (status != null) 'status': status,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalaryRecordsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? employeeId,
    Value<String>? employeeName,
    Value<String>? payPeriod,
    Value<double>? baseSalary,
    Value<double>? allowances,
    Value<double>? deductions,
    Value<double>? netPaid,
    Value<String>? paymentDate,
    Value<String>? status,
    Value<String>? paymentMethod,
    Value<int>? rowid,
  }) {
    return SalaryRecordsTableCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      payPeriod: payPeriod ?? this.payPeriod,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      netPaid: netPaid ?? this.netPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (employeeName.present) {
      map['employee_name'] = Variable<String>(employeeName.value);
    }
    if (payPeriod.present) {
      map['pay_period'] = Variable<String>(payPeriod.value);
    }
    if (baseSalary.present) {
      map['base_salary'] = Variable<double>(baseSalary.value);
    }
    if (allowances.present) {
      map['allowances'] = Variable<double>(allowances.value);
    }
    if (deductions.present) {
      map['deductions'] = Variable<double>(deductions.value);
    }
    if (netPaid.present) {
      map['net_paid'] = Variable<double>(netPaid.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<String>(paymentDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalaryRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('payPeriod: $payPeriod, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('allowances: $allowances, ')
          ..write('deductions: $deductions, ')
          ..write('netPaid: $netPaid, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTableTable extends AssetsTable
    with TableInfo<$AssetsTableTable, AssetsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedToIdMeta = const VerificationMeta(
    'assignedToId',
  );
  @override
  late final GeneratedColumn<String> assignedToId = GeneratedColumn<String>(
    'assigned_to_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assignedToNameMeta = const VerificationMeta(
    'assignedToName',
  );
  @override
  late final GeneratedColumn<String> assignedToName = GeneratedColumn<String>(
    'assigned_to_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    serialNumber,
    purchaseDate,
    cost,
    status,
    condition,
    assignedToId,
    assignedToName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serialNumberMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    } else if (isInserting) {
      context.missing(_conditionMeta);
    }
    if (data.containsKey('assigned_to_id')) {
      context.handle(
        _assignedToIdMeta,
        assignedToId.isAcceptableOrUnknown(
          data['assigned_to_id']!,
          _assignedToIdMeta,
        ),
      );
    }
    if (data.containsKey('assigned_to_name')) {
      context.handle(
        _assignedToNameMeta,
        assignedToName.isAcceptableOrUnknown(
          data['assigned_to_name']!,
          _assignedToNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      )!,
      assignedToId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_to_id'],
      ),
      assignedToName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_to_name'],
      ),
    );
  }

  @override
  $AssetsTableTable createAlias(String alias) {
    return $AssetsTableTable(attachedDatabase, alias);
  }
}

class AssetsTableData extends DataClass implements Insertable<AssetsTableData> {
  final String id;
  final String name;
  final String type;
  final String serialNumber;
  final String purchaseDate;
  final double cost;
  final String status;
  final String condition;
  final String? assignedToId;
  final String? assignedToName;
  const AssetsTableData({
    required this.id,
    required this.name,
    required this.type,
    required this.serialNumber,
    required this.purchaseDate,
    required this.cost,
    required this.status,
    required this.condition,
    this.assignedToId,
    this.assignedToName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['serial_number'] = Variable<String>(serialNumber);
    map['purchase_date'] = Variable<String>(purchaseDate);
    map['cost'] = Variable<double>(cost);
    map['status'] = Variable<String>(status);
    map['condition'] = Variable<String>(condition);
    if (!nullToAbsent || assignedToId != null) {
      map['assigned_to_id'] = Variable<String>(assignedToId);
    }
    if (!nullToAbsent || assignedToName != null) {
      map['assigned_to_name'] = Variable<String>(assignedToName);
    }
    return map;
  }

  AssetsTableCompanion toCompanion(bool nullToAbsent) {
    return AssetsTableCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      serialNumber: Value(serialNumber),
      purchaseDate: Value(purchaseDate),
      cost: Value(cost),
      status: Value(status),
      condition: Value(condition),
      assignedToId: assignedToId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedToId),
      assignedToName: assignedToName == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedToName),
    );
  }

  factory AssetsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      serialNumber: serializer.fromJson<String>(json['serialNumber']),
      purchaseDate: serializer.fromJson<String>(json['purchaseDate']),
      cost: serializer.fromJson<double>(json['cost']),
      status: serializer.fromJson<String>(json['status']),
      condition: serializer.fromJson<String>(json['condition']),
      assignedToId: serializer.fromJson<String?>(json['assignedToId']),
      assignedToName: serializer.fromJson<String?>(json['assignedToName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'serialNumber': serializer.toJson<String>(serialNumber),
      'purchaseDate': serializer.toJson<String>(purchaseDate),
      'cost': serializer.toJson<double>(cost),
      'status': serializer.toJson<String>(status),
      'condition': serializer.toJson<String>(condition),
      'assignedToId': serializer.toJson<String?>(assignedToId),
      'assignedToName': serializer.toJson<String?>(assignedToName),
    };
  }

  AssetsTableData copyWith({
    String? id,
    String? name,
    String? type,
    String? serialNumber,
    String? purchaseDate,
    double? cost,
    String? status,
    String? condition,
    Value<String?> assignedToId = const Value.absent(),
    Value<String?> assignedToName = const Value.absent(),
  }) => AssetsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    serialNumber: serialNumber ?? this.serialNumber,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    cost: cost ?? this.cost,
    status: status ?? this.status,
    condition: condition ?? this.condition,
    assignedToId: assignedToId.present ? assignedToId.value : this.assignedToId,
    assignedToName: assignedToName.present
        ? assignedToName.value
        : this.assignedToName,
  );
  AssetsTableData copyWithCompanion(AssetsTableCompanion data) {
    return AssetsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      cost: data.cost.present ? data.cost.value : this.cost,
      status: data.status.present ? data.status.value : this.status,
      condition: data.condition.present ? data.condition.value : this.condition,
      assignedToId: data.assignedToId.present
          ? data.assignedToId.value
          : this.assignedToId,
      assignedToName: data.assignedToName.present
          ? data.assignedToName.value
          : this.assignedToName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('cost: $cost, ')
          ..write('status: $status, ')
          ..write('condition: $condition, ')
          ..write('assignedToId: $assignedToId, ')
          ..write('assignedToName: $assignedToName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    serialNumber,
    purchaseDate,
    cost,
    status,
    condition,
    assignedToId,
    assignedToName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.serialNumber == this.serialNumber &&
          other.purchaseDate == this.purchaseDate &&
          other.cost == this.cost &&
          other.status == this.status &&
          other.condition == this.condition &&
          other.assignedToId == this.assignedToId &&
          other.assignedToName == this.assignedToName);
}

class AssetsTableCompanion extends UpdateCompanion<AssetsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> serialNumber;
  final Value<String> purchaseDate;
  final Value<double> cost;
  final Value<String> status;
  final Value<String> condition;
  final Value<String?> assignedToId;
  final Value<String?> assignedToName;
  final Value<int> rowid;
  const AssetsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.cost = const Value.absent(),
    this.status = const Value.absent(),
    this.condition = const Value.absent(),
    this.assignedToId = const Value.absent(),
    this.assignedToName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsTableCompanion.insert({
    required String id,
    required String name,
    required String type,
    required String serialNumber,
    required String purchaseDate,
    required double cost,
    required String status,
    required String condition,
    this.assignedToId = const Value.absent(),
    this.assignedToName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       serialNumber = Value(serialNumber),
       purchaseDate = Value(purchaseDate),
       cost = Value(cost),
       status = Value(status),
       condition = Value(condition);
  static Insertable<AssetsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? serialNumber,
    Expression<String>? purchaseDate,
    Expression<double>? cost,
    Expression<String>? status,
    Expression<String>? condition,
    Expression<String>? assignedToId,
    Expression<String>? assignedToName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (cost != null) 'cost': cost,
      if (status != null) 'status': status,
      if (condition != null) 'condition': condition,
      if (assignedToId != null) 'assigned_to_id': assignedToId,
      if (assignedToName != null) 'assigned_to_name': assignedToName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? serialNumber,
    Value<String>? purchaseDate,
    Value<double>? cost,
    Value<String>? status,
    Value<String>? condition,
    Value<String?>? assignedToId,
    Value<String?>? assignedToName,
    Value<int>? rowid,
  }) {
    return AssetsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (assignedToId.present) {
      map['assigned_to_id'] = Variable<String>(assignedToId.value);
    }
    if (assignedToName.present) {
      map['assigned_to_name'] = Variable<String>(assignedToName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('cost: $cost, ')
          ..write('status: $status, ')
          ..write('condition: $condition, ')
          ..write('assignedToId: $assignedToId, ')
          ..write('assignedToName: $assignedToName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTableTable extends InventoryItemsTable
    with TableInfo<$InventoryItemsTableTable, InventoryItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minQuantityMeta = const VerificationMeta(
    'minQuantity',
  );
  @override
  late final GeneratedColumn<int> minQuantity = GeneratedColumn<int>(
    'min_quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerUnitMeta = const VerificationMeta(
    'pricePerUnit',
  );
  @override
  late final GeneratedColumn<double> pricePerUnit = GeneratedColumn<double>(
    'price_per_unit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastRestockedDateMeta = const VerificationMeta(
    'lastRestockedDate',
  );
  @override
  late final GeneratedColumn<String> lastRestockedDate =
      GeneratedColumn<String>(
        'last_restocked_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    quantity,
    minQuantity,
    unit,
    pricePerUnit,
    lastRestockedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('min_quantity')) {
      context.handle(
        _minQuantityMeta,
        minQuantity.isAcceptableOrUnknown(
          data['min_quantity']!,
          _minQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minQuantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('price_per_unit')) {
      context.handle(
        _pricePerUnitMeta,
        pricePerUnit.isAcceptableOrUnknown(
          data['price_per_unit']!,
          _pricePerUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerUnitMeta);
    }
    if (data.containsKey('last_restocked_date')) {
      context.handle(
        _lastRestockedDateMeta,
        lastRestockedDate.isAcceptableOrUnknown(
          data['last_restocked_date']!,
          _lastRestockedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastRestockedDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItemsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      minQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      pricePerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_unit'],
      )!,
      lastRestockedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_restocked_date'],
      )!,
    );
  }

  @override
  $InventoryItemsTableTable createAlias(String alias) {
    return $InventoryItemsTableTable(attachedDatabase, alias);
  }
}

class InventoryItemsTableData extends DataClass
    implements Insertable<InventoryItemsTableData> {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final int minQuantity;
  final String unit;
  final double pricePerUnit;
  final String lastRestockedDate;
  const InventoryItemsTableData({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    required this.pricePerUnit,
    required this.lastRestockedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['quantity'] = Variable<int>(quantity);
    map['min_quantity'] = Variable<int>(minQuantity);
    map['unit'] = Variable<String>(unit);
    map['price_per_unit'] = Variable<double>(pricePerUnit);
    map['last_restocked_date'] = Variable<String>(lastRestockedDate);
    return map;
  }

  InventoryItemsTableCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsTableCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      quantity: Value(quantity),
      minQuantity: Value(minQuantity),
      unit: Value(unit),
      pricePerUnit: Value(pricePerUnit),
      lastRestockedDate: Value(lastRestockedDate),
    );
  }

  factory InventoryItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      quantity: serializer.fromJson<int>(json['quantity']),
      minQuantity: serializer.fromJson<int>(json['minQuantity']),
      unit: serializer.fromJson<String>(json['unit']),
      pricePerUnit: serializer.fromJson<double>(json['pricePerUnit']),
      lastRestockedDate: serializer.fromJson<String>(json['lastRestockedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'quantity': serializer.toJson<int>(quantity),
      'minQuantity': serializer.toJson<int>(minQuantity),
      'unit': serializer.toJson<String>(unit),
      'pricePerUnit': serializer.toJson<double>(pricePerUnit),
      'lastRestockedDate': serializer.toJson<String>(lastRestockedDate),
    };
  }

  InventoryItemsTableData copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    int? minQuantity,
    String? unit,
    double? pricePerUnit,
    String? lastRestockedDate,
  }) => InventoryItemsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    minQuantity: minQuantity ?? this.minQuantity,
    unit: unit ?? this.unit,
    pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    lastRestockedDate: lastRestockedDate ?? this.lastRestockedDate,
  );
  InventoryItemsTableData copyWithCompanion(InventoryItemsTableCompanion data) {
    return InventoryItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      minQuantity: data.minQuantity.present
          ? data.minQuantity.value
          : this.minQuantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      pricePerUnit: data.pricePerUnit.present
          ? data.pricePerUnit.value
          : this.pricePerUnit,
      lastRestockedDate: data.lastRestockedDate.present
          ? data.lastRestockedDate.value
          : this.lastRestockedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('unit: $unit, ')
          ..write('pricePerUnit: $pricePerUnit, ')
          ..write('lastRestockedDate: $lastRestockedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    quantity,
    minQuantity,
    unit,
    pricePerUnit,
    lastRestockedDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItemsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.quantity == this.quantity &&
          other.minQuantity == this.minQuantity &&
          other.unit == this.unit &&
          other.pricePerUnit == this.pricePerUnit &&
          other.lastRestockedDate == this.lastRestockedDate);
}

class InventoryItemsTableCompanion
    extends UpdateCompanion<InventoryItemsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<int> quantity;
  final Value<int> minQuantity;
  final Value<String> unit;
  final Value<double> pricePerUnit;
  final Value<String> lastRestockedDate;
  final Value<int> rowid;
  const InventoryItemsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.quantity = const Value.absent(),
    this.minQuantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.pricePerUnit = const Value.absent(),
    this.lastRestockedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsTableCompanion.insert({
    required String id,
    required String name,
    required String category,
    required int quantity,
    required int minQuantity,
    required String unit,
    required double pricePerUnit,
    required String lastRestockedDate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       quantity = Value(quantity),
       minQuantity = Value(minQuantity),
       unit = Value(unit),
       pricePerUnit = Value(pricePerUnit),
       lastRestockedDate = Value(lastRestockedDate);
  static Insertable<InventoryItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? quantity,
    Expression<int>? minQuantity,
    Expression<String>? unit,
    Expression<double>? pricePerUnit,
    Expression<String>? lastRestockedDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (minQuantity != null) 'min_quantity': minQuantity,
      if (unit != null) 'unit': unit,
      if (pricePerUnit != null) 'price_per_unit': pricePerUnit,
      if (lastRestockedDate != null) 'last_restocked_date': lastRestockedDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<int>? quantity,
    Value<int>? minQuantity,
    Value<String>? unit,
    Value<double>? pricePerUnit,
    Value<String>? lastRestockedDate,
    Value<int>? rowid,
  }) {
    return InventoryItemsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      lastRestockedDate: lastRestockedDate ?? this.lastRestockedDate,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (minQuantity.present) {
      map['min_quantity'] = Variable<int>(minQuantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (pricePerUnit.present) {
      map['price_per_unit'] = Variable<double>(pricePerUnit.value);
    }
    if (lastRestockedDate.present) {
      map['last_restocked_date'] = Variable<String>(lastRestockedDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('unit: $unit, ')
          ..write('pricePerUnit: $pricePerUnit, ')
          ..write('lastRestockedDate: $lastRestockedDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTableTable extends ProjectsTable
    with TableInfo<$ProjectsTableTable, ProjectsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<double> budget = GeneratedColumn<double>(
    'budget',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _advancedPaymentMeta = const VerificationMeta(
    'advancedPayment',
  );
  @override
  late final GeneratedColumn<double> advancedPayment = GeneratedColumn<double>(
    'advanced_payment',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partialPaymentsMeta = const VerificationMeta(
    'partialPayments',
  );
  @override
  late final GeneratedColumn<double> partialPayments = GeneratedColumn<double>(
    'partial_payments',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalPaymentMeta = const VerificationMeta(
    'finalPayment',
  );
  @override
  late final GeneratedColumn<double> finalPayment = GeneratedColumn<double>(
    'final_payment',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankAccountIdMeta = const VerificationMeta(
    'bankAccountId',
  );
  @override
  late final GeneratedColumn<String> bankAccountId = GeneratedColumn<String>(
    'bank_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankAccountNameMeta = const VerificationMeta(
    'bankAccountName',
  );
  @override
  late final GeneratedColumn<String> bankAccountName = GeneratedColumn<String>(
    'bank_account_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountHolderMeta = const VerificationMeta(
    'accountHolder',
  );
  @override
  late final GeneratedColumn<String> accountHolder = GeneratedColumn<String>(
    'account_holder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  teamMembers = GeneratedColumn<String>(
    'team_members',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($ProjectsTableTable.$converterteamMembers);
  static const VerificationMeta _clientPaymentSourceMeta =
      const VerificationMeta('clientPaymentSource');
  @override
  late final GeneratedColumn<String> clientPaymentSource =
      GeneratedColumn<String>(
        'client_payment_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    clientId,
    clientName,
    startDate,
    endDate,
    status,
    budget,
    advancedPayment,
    partialPayments,
    finalPayment,
    paymentStatus,
    bankAccountId,
    bankAccountName,
    accountHolder,
    teamMembers,
    clientPaymentSource,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    } else if (isInserting) {
      context.missing(_budgetMeta);
    }
    if (data.containsKey('advanced_payment')) {
      context.handle(
        _advancedPaymentMeta,
        advancedPayment.isAcceptableOrUnknown(
          data['advanced_payment']!,
          _advancedPaymentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_advancedPaymentMeta);
    }
    if (data.containsKey('partial_payments')) {
      context.handle(
        _partialPaymentsMeta,
        partialPayments.isAcceptableOrUnknown(
          data['partial_payments']!,
          _partialPaymentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partialPaymentsMeta);
    }
    if (data.containsKey('final_payment')) {
      context.handle(
        _finalPaymentMeta,
        finalPayment.isAcceptableOrUnknown(
          data['final_payment']!,
          _finalPaymentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finalPaymentMeta);
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentStatusMeta);
    }
    if (data.containsKey('bank_account_id')) {
      context.handle(
        _bankAccountIdMeta,
        bankAccountId.isAcceptableOrUnknown(
          data['bank_account_id']!,
          _bankAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bankAccountIdMeta);
    }
    if (data.containsKey('bank_account_name')) {
      context.handle(
        _bankAccountNameMeta,
        bankAccountName.isAcceptableOrUnknown(
          data['bank_account_name']!,
          _bankAccountNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bankAccountNameMeta);
    }
    if (data.containsKey('account_holder')) {
      context.handle(
        _accountHolderMeta,
        accountHolder.isAcceptableOrUnknown(
          data['account_holder']!,
          _accountHolderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountHolderMeta);
    }
    if (data.containsKey('client_payment_source')) {
      context.handle(
        _clientPaymentSourceMeta,
        clientPaymentSource.isAcceptableOrUnknown(
          data['client_payment_source']!,
          _clientPaymentSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientPaymentSourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}budget'],
      )!,
      advancedPayment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}advanced_payment'],
      )!,
      partialPayments: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}partial_payments'],
      )!,
      finalPayment: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}final_payment'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      bankAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account_id'],
      )!,
      bankAccountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account_name'],
      )!,
      accountHolder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_holder'],
      )!,
      teamMembers: $ProjectsTableTable.$converterteamMembers.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}team_members'],
        )!,
      ),
      clientPaymentSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_payment_source'],
      )!,
    );
  }

  @override
  $ProjectsTableTable createAlias(String alias) {
    return $ProjectsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterteamMembers =
      const StringListConverter();
}

class ProjectsTableData extends DataClass
    implements Insertable<ProjectsTableData> {
  final String id;
  final String name;
  final String description;
  final String clientId;
  final String clientName;
  final String startDate;
  final String endDate;
  final String status;
  final double budget;
  final double advancedPayment;
  final double partialPayments;
  final double finalPayment;
  final String paymentStatus;
  final String bankAccountId;
  final String bankAccountName;
  final String accountHolder;
  final List<String> teamMembers;
  final String clientPaymentSource;
  const ProjectsTableData({
    required this.id,
    required this.name,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.budget,
    required this.advancedPayment,
    required this.partialPayments,
    required this.finalPayment,
    required this.paymentStatus,
    required this.bankAccountId,
    required this.bankAccountName,
    required this.accountHolder,
    required this.teamMembers,
    required this.clientPaymentSource,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['client_id'] = Variable<String>(clientId);
    map['client_name'] = Variable<String>(clientName);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['status'] = Variable<String>(status);
    map['budget'] = Variable<double>(budget);
    map['advanced_payment'] = Variable<double>(advancedPayment);
    map['partial_payments'] = Variable<double>(partialPayments);
    map['final_payment'] = Variable<double>(finalPayment);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['bank_account_id'] = Variable<String>(bankAccountId);
    map['bank_account_name'] = Variable<String>(bankAccountName);
    map['account_holder'] = Variable<String>(accountHolder);
    {
      map['team_members'] = Variable<String>(
        $ProjectsTableTable.$converterteamMembers.toSql(teamMembers),
      );
    }
    map['client_payment_source'] = Variable<String>(clientPaymentSource);
    return map;
  }

  ProjectsTableCompanion toCompanion(bool nullToAbsent) {
    return ProjectsTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      clientId: Value(clientId),
      clientName: Value(clientName),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      budget: Value(budget),
      advancedPayment: Value(advancedPayment),
      partialPayments: Value(partialPayments),
      finalPayment: Value(finalPayment),
      paymentStatus: Value(paymentStatus),
      bankAccountId: Value(bankAccountId),
      bankAccountName: Value(bankAccountName),
      accountHolder: Value(accountHolder),
      teamMembers: Value(teamMembers),
      clientPaymentSource: Value(clientPaymentSource),
    );
  }

  factory ProjectsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      clientId: serializer.fromJson<String>(json['clientId']),
      clientName: serializer.fromJson<String>(json['clientName']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      status: serializer.fromJson<String>(json['status']),
      budget: serializer.fromJson<double>(json['budget']),
      advancedPayment: serializer.fromJson<double>(json['advancedPayment']),
      partialPayments: serializer.fromJson<double>(json['partialPayments']),
      finalPayment: serializer.fromJson<double>(json['finalPayment']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      bankAccountId: serializer.fromJson<String>(json['bankAccountId']),
      bankAccountName: serializer.fromJson<String>(json['bankAccountName']),
      accountHolder: serializer.fromJson<String>(json['accountHolder']),
      teamMembers: serializer.fromJson<List<String>>(json['teamMembers']),
      clientPaymentSource: serializer.fromJson<String>(
        json['clientPaymentSource'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'clientId': serializer.toJson<String>(clientId),
      'clientName': serializer.toJson<String>(clientName),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'status': serializer.toJson<String>(status),
      'budget': serializer.toJson<double>(budget),
      'advancedPayment': serializer.toJson<double>(advancedPayment),
      'partialPayments': serializer.toJson<double>(partialPayments),
      'finalPayment': serializer.toJson<double>(finalPayment),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'bankAccountId': serializer.toJson<String>(bankAccountId),
      'bankAccountName': serializer.toJson<String>(bankAccountName),
      'accountHolder': serializer.toJson<String>(accountHolder),
      'teamMembers': serializer.toJson<List<String>>(teamMembers),
      'clientPaymentSource': serializer.toJson<String>(clientPaymentSource),
    };
  }

  ProjectsTableData copyWith({
    String? id,
    String? name,
    String? description,
    String? clientId,
    String? clientName,
    String? startDate,
    String? endDate,
    String? status,
    double? budget,
    double? advancedPayment,
    double? partialPayments,
    double? finalPayment,
    String? paymentStatus,
    String? bankAccountId,
    String? bankAccountName,
    String? accountHolder,
    List<String>? teamMembers,
    String? clientPaymentSource,
  }) => ProjectsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    clientId: clientId ?? this.clientId,
    clientName: clientName ?? this.clientName,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    status: status ?? this.status,
    budget: budget ?? this.budget,
    advancedPayment: advancedPayment ?? this.advancedPayment,
    partialPayments: partialPayments ?? this.partialPayments,
    finalPayment: finalPayment ?? this.finalPayment,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    bankAccountId: bankAccountId ?? this.bankAccountId,
    bankAccountName: bankAccountName ?? this.bankAccountName,
    accountHolder: accountHolder ?? this.accountHolder,
    teamMembers: teamMembers ?? this.teamMembers,
    clientPaymentSource: clientPaymentSource ?? this.clientPaymentSource,
  );
  ProjectsTableData copyWithCompanion(ProjectsTableCompanion data) {
    return ProjectsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      status: data.status.present ? data.status.value : this.status,
      budget: data.budget.present ? data.budget.value : this.budget,
      advancedPayment: data.advancedPayment.present
          ? data.advancedPayment.value
          : this.advancedPayment,
      partialPayments: data.partialPayments.present
          ? data.partialPayments.value
          : this.partialPayments,
      finalPayment: data.finalPayment.present
          ? data.finalPayment.value
          : this.finalPayment,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      bankAccountId: data.bankAccountId.present
          ? data.bankAccountId.value
          : this.bankAccountId,
      bankAccountName: data.bankAccountName.present
          ? data.bankAccountName.value
          : this.bankAccountName,
      accountHolder: data.accountHolder.present
          ? data.accountHolder.value
          : this.accountHolder,
      teamMembers: data.teamMembers.present
          ? data.teamMembers.value
          : this.teamMembers,
      clientPaymentSource: data.clientPaymentSource.present
          ? data.clientPaymentSource.value
          : this.clientPaymentSource,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('budget: $budget, ')
          ..write('advancedPayment: $advancedPayment, ')
          ..write('partialPayments: $partialPayments, ')
          ..write('finalPayment: $finalPayment, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('bankAccountId: $bankAccountId, ')
          ..write('bankAccountName: $bankAccountName, ')
          ..write('accountHolder: $accountHolder, ')
          ..write('teamMembers: $teamMembers, ')
          ..write('clientPaymentSource: $clientPaymentSource')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    clientId,
    clientName,
    startDate,
    endDate,
    status,
    budget,
    advancedPayment,
    partialPayments,
    finalPayment,
    paymentStatus,
    bankAccountId,
    bankAccountName,
    accountHolder,
    teamMembers,
    clientPaymentSource,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.clientId == this.clientId &&
          other.clientName == this.clientName &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.status == this.status &&
          other.budget == this.budget &&
          other.advancedPayment == this.advancedPayment &&
          other.partialPayments == this.partialPayments &&
          other.finalPayment == this.finalPayment &&
          other.paymentStatus == this.paymentStatus &&
          other.bankAccountId == this.bankAccountId &&
          other.bankAccountName == this.bankAccountName &&
          other.accountHolder == this.accountHolder &&
          other.teamMembers == this.teamMembers &&
          other.clientPaymentSource == this.clientPaymentSource);
}

class ProjectsTableCompanion extends UpdateCompanion<ProjectsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> clientId;
  final Value<String> clientName;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> status;
  final Value<double> budget;
  final Value<double> advancedPayment;
  final Value<double> partialPayments;
  final Value<double> finalPayment;
  final Value<String> paymentStatus;
  final Value<String> bankAccountId;
  final Value<String> bankAccountName;
  final Value<String> accountHolder;
  final Value<List<String>> teamMembers;
  final Value<String> clientPaymentSource;
  final Value<int> rowid;
  const ProjectsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.budget = const Value.absent(),
    this.advancedPayment = const Value.absent(),
    this.partialPayments = const Value.absent(),
    this.finalPayment = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.bankAccountId = const Value.absent(),
    this.bankAccountName = const Value.absent(),
    this.accountHolder = const Value.absent(),
    this.teamMembers = const Value.absent(),
    this.clientPaymentSource = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsTableCompanion.insert({
    required String id,
    required String name,
    required String description,
    required String clientId,
    required String clientName,
    required String startDate,
    required String endDate,
    required String status,
    required double budget,
    required double advancedPayment,
    required double partialPayments,
    required double finalPayment,
    required String paymentStatus,
    required String bankAccountId,
    required String bankAccountName,
    required String accountHolder,
    required List<String> teamMembers,
    required String clientPaymentSource,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       clientId = Value(clientId),
       clientName = Value(clientName),
       startDate = Value(startDate),
       endDate = Value(endDate),
       status = Value(status),
       budget = Value(budget),
       advancedPayment = Value(advancedPayment),
       partialPayments = Value(partialPayments),
       finalPayment = Value(finalPayment),
       paymentStatus = Value(paymentStatus),
       bankAccountId = Value(bankAccountId),
       bankAccountName = Value(bankAccountName),
       accountHolder = Value(accountHolder),
       teamMembers = Value(teamMembers),
       clientPaymentSource = Value(clientPaymentSource);
  static Insertable<ProjectsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? clientId,
    Expression<String>? clientName,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? status,
    Expression<double>? budget,
    Expression<double>? advancedPayment,
    Expression<double>? partialPayments,
    Expression<double>? finalPayment,
    Expression<String>? paymentStatus,
    Expression<String>? bankAccountId,
    Expression<String>? bankAccountName,
    Expression<String>? accountHolder,
    Expression<String>? teamMembers,
    Expression<String>? clientPaymentSource,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (clientId != null) 'client_id': clientId,
      if (clientName != null) 'client_name': clientName,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      if (budget != null) 'budget': budget,
      if (advancedPayment != null) 'advanced_payment': advancedPayment,
      if (partialPayments != null) 'partial_payments': partialPayments,
      if (finalPayment != null) 'final_payment': finalPayment,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (bankAccountId != null) 'bank_account_id': bankAccountId,
      if (bankAccountName != null) 'bank_account_name': bankAccountName,
      if (accountHolder != null) 'account_holder': accountHolder,
      if (teamMembers != null) 'team_members': teamMembers,
      if (clientPaymentSource != null)
        'client_payment_source': clientPaymentSource,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? clientId,
    Value<String>? clientName,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<String>? status,
    Value<double>? budget,
    Value<double>? advancedPayment,
    Value<double>? partialPayments,
    Value<double>? finalPayment,
    Value<String>? paymentStatus,
    Value<String>? bankAccountId,
    Value<String>? bankAccountName,
    Value<String>? accountHolder,
    Value<List<String>>? teamMembers,
    Value<String>? clientPaymentSource,
    Value<int>? rowid,
  }) {
    return ProjectsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      advancedPayment: advancedPayment ?? this.advancedPayment,
      partialPayments: partialPayments ?? this.partialPayments,
      finalPayment: finalPayment ?? this.finalPayment,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      accountHolder: accountHolder ?? this.accountHolder,
      teamMembers: teamMembers ?? this.teamMembers,
      clientPaymentSource: clientPaymentSource ?? this.clientPaymentSource,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (budget.present) {
      map['budget'] = Variable<double>(budget.value);
    }
    if (advancedPayment.present) {
      map['advanced_payment'] = Variable<double>(advancedPayment.value);
    }
    if (partialPayments.present) {
      map['partial_payments'] = Variable<double>(partialPayments.value);
    }
    if (finalPayment.present) {
      map['final_payment'] = Variable<double>(finalPayment.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (bankAccountId.present) {
      map['bank_account_id'] = Variable<String>(bankAccountId.value);
    }
    if (bankAccountName.present) {
      map['bank_account_name'] = Variable<String>(bankAccountName.value);
    }
    if (accountHolder.present) {
      map['account_holder'] = Variable<String>(accountHolder.value);
    }
    if (teamMembers.present) {
      map['team_members'] = Variable<String>(
        $ProjectsTableTable.$converterteamMembers.toSql(teamMembers.value),
      );
    }
    if (clientPaymentSource.present) {
      map['client_payment_source'] = Variable<String>(
        clientPaymentSource.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('budget: $budget, ')
          ..write('advancedPayment: $advancedPayment, ')
          ..write('partialPayments: $partialPayments, ')
          ..write('finalPayment: $finalPayment, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('bankAccountId: $bankAccountId, ')
          ..write('bankAccountName: $bankAccountName, ')
          ..write('accountHolder: $accountHolder, ')
          ..write('teamMembers: $teamMembers, ')
          ..write('clientPaymentSource: $clientPaymentSource, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectTasksTableTable extends ProjectTasksTable
    with TableInfo<$ProjectTasksTableTable, ProjectTasksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectTasksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assigneeIdMeta = const VerificationMeta(
    'assigneeId',
  );
  @override
  late final GeneratedColumn<String> assigneeId = GeneratedColumn<String>(
    'assignee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assigneeNameMeta = const VerificationMeta(
    'assigneeName',
  );
  @override
  late final GeneratedColumn<String> assigneeName = GeneratedColumn<String>(
    'assignee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    projectName,
    title,
    description,
    assigneeId,
    assigneeName,
    dueDate,
    priority,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_tasks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectTasksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('assignee_id')) {
      context.handle(
        _assigneeIdMeta,
        assigneeId.isAcceptableOrUnknown(data['assignee_id']!, _assigneeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assigneeIdMeta);
    }
    if (data.containsKey('assignee_name')) {
      context.handle(
        _assigneeNameMeta,
        assigneeName.isAcceptableOrUnknown(
          data['assignee_name']!,
          _assigneeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assigneeNameMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectTasksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectTasksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      assigneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_id'],
      )!,
      assigneeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_name'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ProjectTasksTableTable createAlias(String alias) {
    return $ProjectTasksTableTable(attachedDatabase, alias);
  }
}

class ProjectTasksTableData extends DataClass
    implements Insertable<ProjectTasksTableData> {
  final String id;
  final String projectId;
  final String projectName;
  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final String dueDate;
  final String priority;
  final String status;
  const ProjectTasksTableData({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.dueDate,
    required this.priority,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['project_name'] = Variable<String>(projectName);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['assignee_id'] = Variable<String>(assigneeId);
    map['assignee_name'] = Variable<String>(assigneeName);
    map['due_date'] = Variable<String>(dueDate);
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    return map;
  }

  ProjectTasksTableCompanion toCompanion(bool nullToAbsent) {
    return ProjectTasksTableCompanion(
      id: Value(id),
      projectId: Value(projectId),
      projectName: Value(projectName),
      title: Value(title),
      description: Value(description),
      assigneeId: Value(assigneeId),
      assigneeName: Value(assigneeName),
      dueDate: Value(dueDate),
      priority: Value(priority),
      status: Value(status),
    );
  }

  factory ProjectTasksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectTasksTableData(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      projectName: serializer.fromJson<String>(json['projectName']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      assigneeId: serializer.fromJson<String>(json['assigneeId']),
      assigneeName: serializer.fromJson<String>(json['assigneeName']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'projectName': serializer.toJson<String>(projectName),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'assigneeId': serializer.toJson<String>(assigneeId),
      'assigneeName': serializer.toJson<String>(assigneeName),
      'dueDate': serializer.toJson<String>(dueDate),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
    };
  }

  ProjectTasksTableData copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? title,
    String? description,
    String? assigneeId,
    String? assigneeName,
    String? dueDate,
    String? priority,
    String? status,
  }) => ProjectTasksTableData(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    projectName: projectName ?? this.projectName,
    title: title ?? this.title,
    description: description ?? this.description,
    assigneeId: assigneeId ?? this.assigneeId,
    assigneeName: assigneeName ?? this.assigneeName,
    dueDate: dueDate ?? this.dueDate,
    priority: priority ?? this.priority,
    status: status ?? this.status,
  );
  ProjectTasksTableData copyWithCompanion(ProjectTasksTableCompanion data) {
    return ProjectTasksTableData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      assigneeId: data.assigneeId.present
          ? data.assigneeId.value
          : this.assigneeId,
      assigneeName: data.assigneeName.present
          ? data.assigneeName.value
          : this.assigneeName,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectTasksTableData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('assigneeName: $assigneeName, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    projectName,
    title,
    description,
    assigneeId,
    assigneeName,
    dueDate,
    priority,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectTasksTableData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.title == this.title &&
          other.description == this.description &&
          other.assigneeId == this.assigneeId &&
          other.assigneeName == this.assigneeName &&
          other.dueDate == this.dueDate &&
          other.priority == this.priority &&
          other.status == this.status);
}

class ProjectTasksTableCompanion
    extends UpdateCompanion<ProjectTasksTableData> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> projectName;
  final Value<String> title;
  final Value<String> description;
  final Value<String> assigneeId;
  final Value<String> assigneeName;
  final Value<String> dueDate;
  final Value<String> priority;
  final Value<String> status;
  final Value<int> rowid;
  const ProjectTasksTableCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.assigneeId = const Value.absent(),
    this.assigneeName = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectTasksTableCompanion.insert({
    required String id,
    required String projectId,
    required String projectName,
    required String title,
    required String description,
    required String assigneeId,
    required String assigneeName,
    required String dueDate,
    required String priority,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       projectName = Value(projectName),
       title = Value(title),
       description = Value(description),
       assigneeId = Value(assigneeId),
       assigneeName = Value(assigneeName),
       dueDate = Value(dueDate),
       priority = Value(priority),
       status = Value(status);
  static Insertable<ProjectTasksTableData> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? assigneeId,
    Expression<String>? assigneeName,
    Expression<String>? dueDate,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (assigneeId != null) 'assignee_id': assigneeId,
      if (assigneeName != null) 'assignee_name': assigneeName,
      if (dueDate != null) 'due_date': dueDate,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectTasksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? projectName,
    Value<String>? title,
    Value<String>? description,
    Value<String>? assigneeId,
    Value<String>? assigneeName,
    Value<String>? dueDate,
    Value<String>? priority,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return ProjectTasksTableCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (assigneeId.present) {
      map['assignee_id'] = Variable<String>(assigneeId.value);
    }
    if (assigneeName.present) {
      map['assignee_name'] = Variable<String>(assigneeName.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectTasksTableCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('assigneeName: $assigneeName, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimesheetEntriesTableTable extends TimesheetEntriesTable
    with TableInfo<$TimesheetEntriesTableTable, TimesheetEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimesheetEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeNameMeta = const VerificationMeta(
    'employeeName',
  );
  @override
  late final GeneratedColumn<String> employeeName = GeneratedColumn<String>(
    'employee_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskTitleMeta = const VerificationMeta(
    'taskTitle',
  );
  @override
  late final GeneratedColumn<String> taskTitle = GeneratedColumn<String>(
    'task_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
    'hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employeeId,
    employeeName,
    projectId,
    projectName,
    taskTitle,
    date,
    hours,
    description,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timesheet_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimesheetEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('employee_name')) {
      context.handle(
        _employeeNameMeta,
        employeeName.isAcceptableOrUnknown(
          data['employee_name']!,
          _employeeNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_employeeNameMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectNameMeta);
    }
    if (data.containsKey('task_title')) {
      context.handle(
        _taskTitleMeta,
        taskTitle.isAcceptableOrUnknown(data['task_title']!, _taskTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_taskTitleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    } else if (isInserting) {
      context.missing(_hoursMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimesheetEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimesheetEntriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      employeeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_name'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      )!,
      taskTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $TimesheetEntriesTableTable createAlias(String alias) {
    return $TimesheetEntriesTableTable(attachedDatabase, alias);
  }
}

class TimesheetEntriesTableData extends DataClass
    implements Insertable<TimesheetEntriesTableData> {
  final String id;
  final String employeeId;
  final String employeeName;
  final String projectId;
  final String projectName;
  final String taskTitle;
  final String date;
  final double hours;
  final String description;
  final String status;
  const TimesheetEntriesTableData({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.projectId,
    required this.projectName,
    required this.taskTitle,
    required this.date,
    required this.hours,
    required this.description,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['employee_id'] = Variable<String>(employeeId);
    map['employee_name'] = Variable<String>(employeeName);
    map['project_id'] = Variable<String>(projectId);
    map['project_name'] = Variable<String>(projectName);
    map['task_title'] = Variable<String>(taskTitle);
    map['date'] = Variable<String>(date);
    map['hours'] = Variable<double>(hours);
    map['description'] = Variable<String>(description);
    map['status'] = Variable<String>(status);
    return map;
  }

  TimesheetEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return TimesheetEntriesTableCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      employeeName: Value(employeeName),
      projectId: Value(projectId),
      projectName: Value(projectName),
      taskTitle: Value(taskTitle),
      date: Value(date),
      hours: Value(hours),
      description: Value(description),
      status: Value(status),
    );
  }

  factory TimesheetEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimesheetEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      employeeName: serializer.fromJson<String>(json['employeeName']),
      projectId: serializer.fromJson<String>(json['projectId']),
      projectName: serializer.fromJson<String>(json['projectName']),
      taskTitle: serializer.fromJson<String>(json['taskTitle']),
      date: serializer.fromJson<String>(json['date']),
      hours: serializer.fromJson<double>(json['hours']),
      description: serializer.fromJson<String>(json['description']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'employeeId': serializer.toJson<String>(employeeId),
      'employeeName': serializer.toJson<String>(employeeName),
      'projectId': serializer.toJson<String>(projectId),
      'projectName': serializer.toJson<String>(projectName),
      'taskTitle': serializer.toJson<String>(taskTitle),
      'date': serializer.toJson<String>(date),
      'hours': serializer.toJson<double>(hours),
      'description': serializer.toJson<String>(description),
      'status': serializer.toJson<String>(status),
    };
  }

  TimesheetEntriesTableData copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? projectId,
    String? projectName,
    String? taskTitle,
    String? date,
    double? hours,
    String? description,
    String? status,
  }) => TimesheetEntriesTableData(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    employeeName: employeeName ?? this.employeeName,
    projectId: projectId ?? this.projectId,
    projectName: projectName ?? this.projectName,
    taskTitle: taskTitle ?? this.taskTitle,
    date: date ?? this.date,
    hours: hours ?? this.hours,
    description: description ?? this.description,
    status: status ?? this.status,
  );
  TimesheetEntriesTableData copyWithCompanion(
    TimesheetEntriesTableCompanion data,
  ) {
    return TimesheetEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      employeeName: data.employeeName.present
          ? data.employeeName.value
          : this.employeeName,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      taskTitle: data.taskTitle.present ? data.taskTitle.value : this.taskTitle,
      date: data.date.present ? data.date.value : this.date,
      hours: data.hours.present ? data.hours.value : this.hours,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimesheetEntriesTableData(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('date: $date, ')
          ..write('hours: $hours, ')
          ..write('description: $description, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    employeeName,
    projectId,
    projectName,
    taskTitle,
    date,
    hours,
    description,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimesheetEntriesTableData &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.employeeName == this.employeeName &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.taskTitle == this.taskTitle &&
          other.date == this.date &&
          other.hours == this.hours &&
          other.description == this.description &&
          other.status == this.status);
}

class TimesheetEntriesTableCompanion
    extends UpdateCompanion<TimesheetEntriesTableData> {
  final Value<String> id;
  final Value<String> employeeId;
  final Value<String> employeeName;
  final Value<String> projectId;
  final Value<String> projectName;
  final Value<String> taskTitle;
  final Value<String> date;
  final Value<double> hours;
  final Value<String> description;
  final Value<String> status;
  final Value<int> rowid;
  const TimesheetEntriesTableCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.employeeName = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.taskTitle = const Value.absent(),
    this.date = const Value.absent(),
    this.hours = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimesheetEntriesTableCompanion.insert({
    required String id,
    required String employeeId,
    required String employeeName,
    required String projectId,
    required String projectName,
    required String taskTitle,
    required String date,
    required double hours,
    required String description,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       employeeId = Value(employeeId),
       employeeName = Value(employeeName),
       projectId = Value(projectId),
       projectName = Value(projectName),
       taskTitle = Value(taskTitle),
       date = Value(date),
       hours = Value(hours),
       description = Value(description),
       status = Value(status);
  static Insertable<TimesheetEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? employeeId,
    Expression<String>? employeeName,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<String>? taskTitle,
    Expression<String>? date,
    Expression<double>? hours,
    Expression<String>? description,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (taskTitle != null) 'task_title': taskTitle,
      if (date != null) 'date': date,
      if (hours != null) 'hours': hours,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimesheetEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? employeeId,
    Value<String>? employeeName,
    Value<String>? projectId,
    Value<String>? projectName,
    Value<String>? taskTitle,
    Value<String>? date,
    Value<double>? hours,
    Value<String>? description,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return TimesheetEntriesTableCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      taskTitle: taskTitle ?? this.taskTitle,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (employeeName.present) {
      map['employee_name'] = Variable<String>(employeeName.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (taskTitle.present) {
      map['task_title'] = Variable<String>(taskTitle.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimesheetEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('employeeName: $employeeName, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('date: $date, ')
          ..write('hours: $hours, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseOrdersTableTable extends PurchaseOrdersTable
    with TableInfo<$PurchaseOrdersTableTable, PurchaseOrdersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseOrdersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorIdMeta = const VerificationMeta(
    'vendorId',
  );
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
    'vendor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorNameMeta = const VerificationMeta(
    'vendorName',
  );
  @override
  late final GeneratedColumn<String> vendorName = GeneratedColumn<String>(
    'vendor_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryDateMeta = const VerificationMeta(
    'deliveryDate',
  );
  @override
  late final GeneratedColumn<String> deliveryDate = GeneratedColumn<String>(
    'delivery_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<Map<String, dynamic>>,
    String
  >
  items =
      GeneratedColumn<String>(
        'items',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<Map<String, dynamic>>>(
        $PurchaseOrdersTableTable.$converteritems,
      );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
    'tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vendorId,
    vendorName,
    date,
    deliveryDate,
    items,
    subtotal,
    tax,
    total,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_orders_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseOrdersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorIdMeta);
    }
    if (data.containsKey('vendor_name')) {
      context.handle(
        _vendorNameMeta,
        vendorName.isAcceptableOrUnknown(data['vendor_name']!, _vendorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorNameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('delivery_date')) {
      context.handle(
        _deliveryDateMeta,
        deliveryDate.isAcceptableOrUnknown(
          data['delivery_date']!,
          _deliveryDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryDateMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('tax')) {
      context.handle(
        _taxMeta,
        tax.isAcceptableOrUnknown(data['tax']!, _taxMeta),
      );
    } else if (isInserting) {
      context.missing(_taxMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseOrdersTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseOrdersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vendorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_id'],
      )!,
      vendorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      deliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_date'],
      )!,
      items: $PurchaseOrdersTableTable.$converteritems.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}items'],
        )!,
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      tax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $PurchaseOrdersTableTable createAlias(String alias) {
    return $PurchaseOrdersTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Map<String, dynamic>>, String> $converteritems =
      const PurchaseItemListConverter();
}

class PurchaseOrdersTableData extends DataClass
    implements Insertable<PurchaseOrdersTableData> {
  final String id;
  final String vendorId;
  final String vendorName;
  final String date;
  final String deliveryDate;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  const PurchaseOrdersTableData({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.date,
    required this.deliveryDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vendor_id'] = Variable<String>(vendorId);
    map['vendor_name'] = Variable<String>(vendorName);
    map['date'] = Variable<String>(date);
    map['delivery_date'] = Variable<String>(deliveryDate);
    {
      map['items'] = Variable<String>(
        $PurchaseOrdersTableTable.$converteritems.toSql(items),
      );
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['tax'] = Variable<double>(tax);
    map['total'] = Variable<double>(total);
    map['status'] = Variable<String>(status);
    return map;
  }

  PurchaseOrdersTableCompanion toCompanion(bool nullToAbsent) {
    return PurchaseOrdersTableCompanion(
      id: Value(id),
      vendorId: Value(vendorId),
      vendorName: Value(vendorName),
      date: Value(date),
      deliveryDate: Value(deliveryDate),
      items: Value(items),
      subtotal: Value(subtotal),
      tax: Value(tax),
      total: Value(total),
      status: Value(status),
    );
  }

  factory PurchaseOrdersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseOrdersTableData(
      id: serializer.fromJson<String>(json['id']),
      vendorId: serializer.fromJson<String>(json['vendorId']),
      vendorName: serializer.fromJson<String>(json['vendorName']),
      date: serializer.fromJson<String>(json['date']),
      deliveryDate: serializer.fromJson<String>(json['deliveryDate']),
      items: serializer.fromJson<List<Map<String, dynamic>>>(json['items']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      tax: serializer.fromJson<double>(json['tax']),
      total: serializer.fromJson<double>(json['total']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vendorId': serializer.toJson<String>(vendorId),
      'vendorName': serializer.toJson<String>(vendorName),
      'date': serializer.toJson<String>(date),
      'deliveryDate': serializer.toJson<String>(deliveryDate),
      'items': serializer.toJson<List<Map<String, dynamic>>>(items),
      'subtotal': serializer.toJson<double>(subtotal),
      'tax': serializer.toJson<double>(tax),
      'total': serializer.toJson<double>(total),
      'status': serializer.toJson<String>(status),
    };
  }

  PurchaseOrdersTableData copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? date,
    String? deliveryDate,
    List<Map<String, dynamic>>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
  }) => PurchaseOrdersTableData(
    id: id ?? this.id,
    vendorId: vendorId ?? this.vendorId,
    vendorName: vendorName ?? this.vendorName,
    date: date ?? this.date,
    deliveryDate: deliveryDate ?? this.deliveryDate,
    items: items ?? this.items,
    subtotal: subtotal ?? this.subtotal,
    tax: tax ?? this.tax,
    total: total ?? this.total,
    status: status ?? this.status,
  );
  PurchaseOrdersTableData copyWithCompanion(PurchaseOrdersTableCompanion data) {
    return PurchaseOrdersTableData(
      id: data.id.present ? data.id.value : this.id,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      vendorName: data.vendorName.present
          ? data.vendorName.value
          : this.vendorName,
      date: data.date.present ? data.date.value : this.date,
      deliveryDate: data.deliveryDate.present
          ? data.deliveryDate.value
          : this.deliveryDate,
      items: data.items.present ? data.items.value : this.items,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      tax: data.tax.present ? data.tax.value : this.tax,
      total: data.total.present ? data.total.value : this.total,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrdersTableData(')
          ..write('id: $id, ')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('date: $date, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('items: $items, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vendorId,
    vendorName,
    date,
    deliveryDate,
    items,
    subtotal,
    tax,
    total,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrdersTableData &&
          other.id == this.id &&
          other.vendorId == this.vendorId &&
          other.vendorName == this.vendorName &&
          other.date == this.date &&
          other.deliveryDate == this.deliveryDate &&
          other.items == this.items &&
          other.subtotal == this.subtotal &&
          other.tax == this.tax &&
          other.total == this.total &&
          other.status == this.status);
}

class PurchaseOrdersTableCompanion
    extends UpdateCompanion<PurchaseOrdersTableData> {
  final Value<String> id;
  final Value<String> vendorId;
  final Value<String> vendorName;
  final Value<String> date;
  final Value<String> deliveryDate;
  final Value<List<Map<String, dynamic>>> items;
  final Value<double> subtotal;
  final Value<double> tax;
  final Value<double> total;
  final Value<String> status;
  final Value<int> rowid;
  const PurchaseOrdersTableCompanion({
    this.id = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.date = const Value.absent(),
    this.deliveryDate = const Value.absent(),
    this.items = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.tax = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseOrdersTableCompanion.insert({
    required String id,
    required String vendorId,
    required String vendorName,
    required String date,
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vendorId = Value(vendorId),
       vendorName = Value(vendorName),
       date = Value(date),
       deliveryDate = Value(deliveryDate),
       items = Value(items),
       subtotal = Value(subtotal),
       tax = Value(tax),
       total = Value(total),
       status = Value(status);
  static Insertable<PurchaseOrdersTableData> custom({
    Expression<String>? id,
    Expression<String>? vendorId,
    Expression<String>? vendorName,
    Expression<String>? date,
    Expression<String>? deliveryDate,
    Expression<String>? items,
    Expression<double>? subtotal,
    Expression<double>? tax,
    Expression<double>? total,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vendorId != null) 'vendor_id': vendorId,
      if (vendorName != null) 'vendor_name': vendorName,
      if (date != null) 'date': date,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (items != null) 'items': items,
      if (subtotal != null) 'subtotal': subtotal,
      if (tax != null) 'tax': tax,
      if (total != null) 'total': total,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseOrdersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? vendorId,
    Value<String>? vendorName,
    Value<String>? date,
    Value<String>? deliveryDate,
    Value<List<Map<String, dynamic>>>? items,
    Value<double>? subtotal,
    Value<double>? tax,
    Value<double>? total,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return PurchaseOrdersTableCompanion(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      date: date ?? this.date,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (vendorName.present) {
      map['vendor_name'] = Variable<String>(vendorName.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (deliveryDate.present) {
      map['delivery_date'] = Variable<String>(deliveryDate.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(
        $PurchaseOrdersTableTable.$converteritems.toSql(items.value),
      );
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrdersTableCompanion(')
          ..write('id: $id, ')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('date: $date, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('items: $items, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    category,
    price,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String status;
  const ProductsTableData({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['price'] = Variable<double>(price);
    map['status'] = Variable<String>(status);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      category: Value(category),
      price: Value(price),
      status: Value(status),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      price: serializer.fromJson<double>(json['price']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'price': serializer.toJson<double>(price),
      'status': serializer.toJson<String>(status),
    };
  }

  ProductsTableData copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? status,
  }) => ProductsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    price: price ?? this.price,
    status: status ?? this.status,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      price: data.price.present ? data.price.value : this.price,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('price: $price, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, category, price, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.price == this.price &&
          other.status == this.status);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> category;
  final Value<double> price;
  final Value<String> status;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.price = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    required String name,
    required String description,
    required String category,
    required double price,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       category = Value(category),
       price = Value(price),
       status = Value(status);
  static Insertable<ProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<double>? price,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (price != null) 'price': price,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? category,
    Value<double>? price,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      status: status ?? this.status,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('price: $price, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesInvoicesTableTable extends SalesInvoicesTable
    with TableInfo<$SalesInvoicesTableTable, SalesInvoicesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesInvoicesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<Map<String, dynamic>>,
    String
  >
  items =
      GeneratedColumn<String>(
        'items',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<Map<String, dynamic>>>(
        $SalesInvoicesTableTable.$converteritems,
      );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
    'tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    clientName,
    date,
    dueDate,
    items,
    subtotal,
    tax,
    total,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales_invoices_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalesInvoicesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('tax')) {
      context.handle(
        _taxMeta,
        tax.isAcceptableOrUnknown(data['tax']!, _taxMeta),
      );
    } else if (isInserting) {
      context.missing(_taxMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalesInvoicesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesInvoicesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      items: $SalesInvoicesTableTable.$converteritems.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}items'],
        )!,
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      tax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SalesInvoicesTableTable createAlias(String alias) {
    return $SalesInvoicesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Map<String, dynamic>>, String> $converteritems =
      const InvoiceItemListConverter();
}

class SalesInvoicesTableData extends DataClass
    implements Insertable<SalesInvoicesTableData> {
  final String id;
  final String clientId;
  final String clientName;
  final String date;
  final String dueDate;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  const SalesInvoicesTableData({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    map['client_name'] = Variable<String>(clientName);
    map['date'] = Variable<String>(date);
    map['due_date'] = Variable<String>(dueDate);
    {
      map['items'] = Variable<String>(
        $SalesInvoicesTableTable.$converteritems.toSql(items),
      );
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['tax'] = Variable<double>(tax);
    map['total'] = Variable<double>(total);
    map['status'] = Variable<String>(status);
    return map;
  }

  SalesInvoicesTableCompanion toCompanion(bool nullToAbsent) {
    return SalesInvoicesTableCompanion(
      id: Value(id),
      clientId: Value(clientId),
      clientName: Value(clientName),
      date: Value(date),
      dueDate: Value(dueDate),
      items: Value(items),
      subtotal: Value(subtotal),
      tax: Value(tax),
      total: Value(total),
      status: Value(status),
    );
  }

  factory SalesInvoicesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesInvoicesTableData(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      clientName: serializer.fromJson<String>(json['clientName']),
      date: serializer.fromJson<String>(json['date']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      items: serializer.fromJson<List<Map<String, dynamic>>>(json['items']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      tax: serializer.fromJson<double>(json['tax']),
      total: serializer.fromJson<double>(json['total']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'clientName': serializer.toJson<String>(clientName),
      'date': serializer.toJson<String>(date),
      'dueDate': serializer.toJson<String>(dueDate),
      'items': serializer.toJson<List<Map<String, dynamic>>>(items),
      'subtotal': serializer.toJson<double>(subtotal),
      'tax': serializer.toJson<double>(tax),
      'total': serializer.toJson<double>(total),
      'status': serializer.toJson<String>(status),
    };
  }

  SalesInvoicesTableData copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? date,
    String? dueDate,
    List<Map<String, dynamic>>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
  }) => SalesInvoicesTableData(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    clientName: clientName ?? this.clientName,
    date: date ?? this.date,
    dueDate: dueDate ?? this.dueDate,
    items: items ?? this.items,
    subtotal: subtotal ?? this.subtotal,
    tax: tax ?? this.tax,
    total: total ?? this.total,
    status: status ?? this.status,
  );
  SalesInvoicesTableData copyWithCompanion(SalesInvoicesTableCompanion data) {
    return SalesInvoicesTableData(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      date: data.date.present ? data.date.value : this.date,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      items: data.items.present ? data.items.value : this.items,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      tax: data.tax.present ? data.tax.value : this.tax,
      total: data.total.present ? data.total.value : this.total,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesInvoicesTableData(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('items: $items, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    clientName,
    date,
    dueDate,
    items,
    subtotal,
    tax,
    total,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesInvoicesTableData &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.clientName == this.clientName &&
          other.date == this.date &&
          other.dueDate == this.dueDate &&
          other.items == this.items &&
          other.subtotal == this.subtotal &&
          other.tax == this.tax &&
          other.total == this.total &&
          other.status == this.status);
}

class SalesInvoicesTableCompanion
    extends UpdateCompanion<SalesInvoicesTableData> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<String> clientName;
  final Value<String> date;
  final Value<String> dueDate;
  final Value<List<Map<String, dynamic>>> items;
  final Value<double> subtotal;
  final Value<double> tax;
  final Value<double> total;
  final Value<String> status;
  final Value<int> rowid;
  const SalesInvoicesTableCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.date = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.items = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.tax = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesInvoicesTableCompanion.insert({
    required String id,
    required String clientId,
    required String clientName,
    required String date,
    required String dueDate,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientId = Value(clientId),
       clientName = Value(clientName),
       date = Value(date),
       dueDate = Value(dueDate),
       items = Value(items),
       subtotal = Value(subtotal),
       tax = Value(tax),
       total = Value(total),
       status = Value(status);
  static Insertable<SalesInvoicesTableData> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<String>? clientName,
    Expression<String>? date,
    Expression<String>? dueDate,
    Expression<String>? items,
    Expression<double>? subtotal,
    Expression<double>? tax,
    Expression<double>? total,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (clientName != null) 'client_name': clientName,
      if (date != null) 'date': date,
      if (dueDate != null) 'due_date': dueDate,
      if (items != null) 'items': items,
      if (subtotal != null) 'subtotal': subtotal,
      if (tax != null) 'tax': tax,
      if (total != null) 'total': total,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesInvoicesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clientId,
    Value<String>? clientName,
    Value<String>? date,
    Value<String>? dueDate,
    Value<List<Map<String, dynamic>>>? items,
    Value<double>? subtotal,
    Value<double>? tax,
    Value<double>? total,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return SalesInvoicesTableCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(
        $SalesInvoicesTableTable.$converteritems.toSql(items.value),
      );
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesInvoicesTableCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('clientName: $clientName, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('items: $items, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecycleBinTableTable extends RecycleBinTable
    with TableInfo<$RecycleBinTableTable, RecycleBinTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecycleBinTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedByMeta = const VerificationMeta(
    'deletedBy',
  );
  @override
  late final GeneratedColumn<String> deletedBy = GeneratedColumn<String>(
    'deleted_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  jsonData =
      GeneratedColumn<String>(
        'json_data',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Map<String, dynamic>>(
        $RecycleBinTableTable.$converterjsonData,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemType,
    title,
    subtitle,
    deletedAt,
    deletedBy,
    jsonData,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recycle_bin_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecycleBinTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    } else if (isInserting) {
      context.missing(_subtitleMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    if (data.containsKey('deleted_by')) {
      context.handle(
        _deletedByMeta,
        deletedBy.isAcceptableOrUnknown(data['deleted_by']!, _deletedByMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedByMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecycleBinTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecycleBinTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      )!,
      deletedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_by'],
      )!,
      jsonData: $RecycleBinTableTable.$converterjsonData.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}json_data'],
        )!,
      ),
    );
  }

  @override
  $RecycleBinTableTable createAlias(String alias) {
    return $RecycleBinTableTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, dynamic>, String> $converterjsonData =
      const JsonMapConverter();
}

class RecycleBinTableData extends DataClass
    implements Insertable<RecycleBinTableData> {
  final String id;
  final String itemType;
  final String title;
  final String subtitle;
  final String deletedAt;
  final String deletedBy;
  final Map<String, dynamic> jsonData;
  const RecycleBinTableData({
    required this.id,
    required this.itemType,
    required this.title,
    required this.subtitle,
    required this.deletedAt,
    required this.deletedBy,
    required this.jsonData,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_type'] = Variable<String>(itemType);
    map['title'] = Variable<String>(title);
    map['subtitle'] = Variable<String>(subtitle);
    map['deleted_at'] = Variable<String>(deletedAt);
    map['deleted_by'] = Variable<String>(deletedBy);
    {
      map['json_data'] = Variable<String>(
        $RecycleBinTableTable.$converterjsonData.toSql(jsonData),
      );
    }
    return map;
  }

  RecycleBinTableCompanion toCompanion(bool nullToAbsent) {
    return RecycleBinTableCompanion(
      id: Value(id),
      itemType: Value(itemType),
      title: Value(title),
      subtitle: Value(subtitle),
      deletedAt: Value(deletedAt),
      deletedBy: Value(deletedBy),
      jsonData: Value(jsonData),
    );
  }

  factory RecycleBinTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecycleBinTableData(
      id: serializer.fromJson<String>(json['id']),
      itemType: serializer.fromJson<String>(json['itemType']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      deletedAt: serializer.fromJson<String>(json['deletedAt']),
      deletedBy: serializer.fromJson<String>(json['deletedBy']),
      jsonData: serializer.fromJson<Map<String, dynamic>>(json['jsonData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemType': serializer.toJson<String>(itemType),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String>(subtitle),
      'deletedAt': serializer.toJson<String>(deletedAt),
      'deletedBy': serializer.toJson<String>(deletedBy),
      'jsonData': serializer.toJson<Map<String, dynamic>>(jsonData),
    };
  }

  RecycleBinTableData copyWith({
    String? id,
    String? itemType,
    String? title,
    String? subtitle,
    String? deletedAt,
    String? deletedBy,
    Map<String, dynamic>? jsonData,
  }) => RecycleBinTableData(
    id: id ?? this.id,
    itemType: itemType ?? this.itemType,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    deletedAt: deletedAt ?? this.deletedAt,
    deletedBy: deletedBy ?? this.deletedBy,
    jsonData: jsonData ?? this.jsonData,
  );
  RecycleBinTableData copyWithCompanion(RecycleBinTableCompanion data) {
    return RecycleBinTableData(
      id: data.id.present ? data.id.value : this.id,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deletedBy: data.deletedBy.present ? data.deletedBy.value : this.deletedBy,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecycleBinTableData(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy, ')
          ..write('jsonData: $jsonData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemType,
    title,
    subtitle,
    deletedAt,
    deletedBy,
    jsonData,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecycleBinTableData &&
          other.id == this.id &&
          other.itemType == this.itemType &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.deletedAt == this.deletedAt &&
          other.deletedBy == this.deletedBy &&
          other.jsonData == this.jsonData);
}

class RecycleBinTableCompanion extends UpdateCompanion<RecycleBinTableData> {
  final Value<String> id;
  final Value<String> itemType;
  final Value<String> title;
  final Value<String> subtitle;
  final Value<String> deletedAt;
  final Value<String> deletedBy;
  final Value<Map<String, dynamic>> jsonData;
  final Value<int> rowid;
  const RecycleBinTableCompanion({
    this.id = const Value.absent(),
    this.itemType = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deletedBy = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecycleBinTableCompanion.insert({
    required String id,
    required String itemType,
    required String title,
    required String subtitle,
    required String deletedAt,
    required String deletedBy,
    required Map<String, dynamic> jsonData,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemType = Value(itemType),
       title = Value(title),
       subtitle = Value(subtitle),
       deletedAt = Value(deletedAt),
       deletedBy = Value(deletedBy),
       jsonData = Value(jsonData);
  static Insertable<RecycleBinTableData> custom({
    Expression<String>? id,
    Expression<String>? itemType,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? deletedAt,
    Expression<String>? deletedBy,
    Expression<String>? jsonData,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemType != null) 'item_type': itemType,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedBy != null) 'deleted_by': deletedBy,
      if (jsonData != null) 'json_data': jsonData,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecycleBinTableCompanion copyWith({
    Value<String>? id,
    Value<String>? itemType,
    Value<String>? title,
    Value<String>? subtitle,
    Value<String>? deletedAt,
    Value<String>? deletedBy,
    Value<Map<String, dynamic>>? jsonData,
    Value<int>? rowid,
  }) {
    return RecycleBinTableCompanion(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      jsonData: jsonData ?? this.jsonData,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (deletedBy.present) {
      map['deleted_by'] = Variable<String>(deletedBy.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(
        $RecycleBinTableTable.$converterjsonData.toSql(jsonData.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecycleBinTableCompanion(')
          ..write('id: $id, ')
          ..write('itemType: $itemType, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy, ')
          ..write('jsonData: $jsonData, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $ActivitiesTableTable activitiesTable = $ActivitiesTableTable(
    this,
  );
  late final $TasksTableTable tasksTable = $TasksTableTable(this);
  late final $StockAlertsTableTable stockAlertsTable = $StockAlertsTableTable(
    this,
  );
  late final $ClientsTableTable clientsTable = $ClientsTableTable(this);
  late final $BankAccountsTableTable bankAccountsTable =
      $BankAccountsTableTable(this);
  late final $ExpenseRecordsTableTable expenseRecordsTable =
      $ExpenseRecordsTableTable(this);
  late final $IncomeRecordsTableTable incomeRecordsTable =
      $IncomeRecordsTableTable(this);
  late final $LedgerEntriesTableTable ledgerEntriesTable =
      $LedgerEntriesTableTable(this);
  late final $LoanRecordsTableTable loanRecordsTable = $LoanRecordsTableTable(
    this,
  );
  late final $AdvanceRecordsTableTable advanceRecordsTable =
      $AdvanceRecordsTableTable(this);
  late final $AttendanceRecordsTableTable attendanceRecordsTable =
      $AttendanceRecordsTableTable(this);
  late final $EmployeesTableTable employeesTable = $EmployeesTableTable(this);
  late final $SalaryRecordsTableTable salaryRecordsTable =
      $SalaryRecordsTableTable(this);
  late final $AssetsTableTable assetsTable = $AssetsTableTable(this);
  late final $InventoryItemsTableTable inventoryItemsTable =
      $InventoryItemsTableTable(this);
  late final $ProjectsTableTable projectsTable = $ProjectsTableTable(this);
  late final $ProjectTasksTableTable projectTasksTable =
      $ProjectTasksTableTable(this);
  late final $TimesheetEntriesTableTable timesheetEntriesTable =
      $TimesheetEntriesTableTable(this);
  late final $PurchaseOrdersTableTable purchaseOrdersTable =
      $PurchaseOrdersTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $SalesInvoicesTableTable salesInvoicesTable =
      $SalesInvoicesTableTable(this);
  late final $RecycleBinTableTable recycleBinTable = $RecycleBinTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactionsTable,
    activitiesTable,
    tasksTable,
    stockAlertsTable,
    clientsTable,
    bankAccountsTable,
    expenseRecordsTable,
    incomeRecordsTable,
    ledgerEntriesTable,
    loanRecordsTable,
    advanceRecordsTable,
    attendanceRecordsTable,
    employeesTable,
    salaryRecordsTable,
    assetsTable,
    inventoryItemsTable,
    projectsTable,
    projectTasksTable,
    timesheetEntriesTable,
    purchaseOrdersTable,
    productsTable,
    salesInvoicesTable,
    recycleBinTable,
  ];
}

typedef $$TransactionsTableTableCreateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<int> id,
      required String details,
      required String type,
      required double amount,
      required String date,
      required bool isIncome,
    });
typedef $$TransactionsTableTableUpdateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<int> id,
      Value<String> details,
      Value<String> type,
      Value<double> amount,
      Value<String> date,
      Value<bool> isIncome,
    });

class $$TransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIncome => $composableBuilder(
    column: $table.isIncome,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIncome => $composableBuilder(
    column: $table.isIncome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isIncome =>
      $composableBuilder(column: $table.isIncome, builder: (column) => column);
}

class $$TransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData,
          $$TransactionsTableTableFilterComposer,
          $$TransactionsTableTableOrderingComposer,
          $$TransactionsTableTableAnnotationComposer,
          $$TransactionsTableTableCreateCompanionBuilder,
          $$TransactionsTableTableUpdateCompanionBuilder,
          (
            TransactionsTableData,
            BaseReferences<
              _$AppDatabase,
              $TransactionsTableTable,
              TransactionsTableData
            >,
          ),
          TransactionsTableData,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableTableManager(
    _$AppDatabase db,
    $TransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> details = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> isIncome = const Value.absent(),
              }) => TransactionsTableCompanion(
                id: id,
                details: details,
                type: type,
                amount: amount,
                date: date,
                isIncome: isIncome,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String details,
                required String type,
                required double amount,
                required String date,
                required bool isIncome,
              }) => TransactionsTableCompanion.insert(
                id: id,
                details: details,
                type: type,
                amount: amount,
                date: date,
                isIncome: isIncome,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTableTable, TransactionsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TransactionsTableTable,
                    TransactionsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTableTable,
      TransactionsTableData,
      $$TransactionsTableTableFilterComposer,
      $$TransactionsTableTableOrderingComposer,
      $$TransactionsTableTableAnnotationComposer,
      $$TransactionsTableTableCreateCompanionBuilder,
      $$TransactionsTableTableUpdateCompanionBuilder,
      (
        TransactionsTableData,
        BaseReferences<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData
        >,
      ),
      TransactionsTableData,
      PrefetchHooks Function()
    >;
typedef $$ActivitiesTableTableCreateCompanionBuilder =
    ActivitiesTableCompanion Function({
      Value<int> id,
      required String content,
      required String timestamp,
      required String iconName,
      required String colorHex,
    });
typedef $$ActivitiesTableTableUpdateCompanionBuilder =
    ActivitiesTableCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<String> timestamp,
      Value<String> iconName,
      Value<String> colorHex,
    });

class $$ActivitiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTableTable> {
  $$ActivitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivitiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTableTable> {
  $$ActivitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTableTable> {
  $$ActivitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);
}

class $$ActivitiesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTableTable,
          ActivitiesTableData,
          $$ActivitiesTableTableFilterComposer,
          $$ActivitiesTableTableOrderingComposer,
          $$ActivitiesTableTableAnnotationComposer,
          $$ActivitiesTableTableCreateCompanionBuilder,
          $$ActivitiesTableTableUpdateCompanionBuilder,
          (
            ActivitiesTableData,
            BaseReferences<
              _$AppDatabase,
              $ActivitiesTableTable,
              ActivitiesTableData
            >,
          ),
          ActivitiesTableData,
          PrefetchHooks Function()
        > {
  $$ActivitiesTableTableTableManager(
    _$AppDatabase db,
    $ActivitiesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
              }) => ActivitiesTableCompanion(
                id: id,
                content: content,
                timestamp: timestamp,
                iconName: iconName,
                colorHex: colorHex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                required String timestamp,
                required String iconName,
                required String colorHex,
              }) => ActivitiesTableCompanion.insert(
                id: id,
                content: content,
                timestamp: timestamp,
                iconName: iconName,
                colorHex: colorHex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTableTable, ActivitiesTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ActivitiesTableTable,
                    ActivitiesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitiesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTableTable,
      ActivitiesTableData,
      $$ActivitiesTableTableFilterComposer,
      $$ActivitiesTableTableOrderingComposer,
      $$ActivitiesTableTableAnnotationComposer,
      $$ActivitiesTableTableCreateCompanionBuilder,
      $$ActivitiesTableTableUpdateCompanionBuilder,
      (
        ActivitiesTableData,
        BaseReferences<
          _$AppDatabase,
          $ActivitiesTableTable,
          ActivitiesTableData
        >,
      ),
      ActivitiesTableData,
      PrefetchHooks Function()
    >;
typedef $$TasksTableTableCreateCompanionBuilder =
    TasksTableCompanion Function({
      Value<int> id,
      required String name,
      required String dueDate,
      required String assignee,
      required bool isCompleted,
    });
typedef $$TasksTableTableUpdateCompanionBuilder =
    TasksTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> dueDate,
      Value<String> assignee,
      Value<bool> isCompleted,
    });

class $$TasksTableTableFilterComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignee => $composableBuilder(
    column: $table.assignee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignee => $composableBuilder(
    column: $table.assignee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get assignee =>
      $composableBuilder(column: $table.assignee, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );
}

class $$TasksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTableTable,
          TasksTableData,
          $$TasksTableTableFilterComposer,
          $$TasksTableTableOrderingComposer,
          $$TasksTableTableAnnotationComposer,
          $$TasksTableTableCreateCompanionBuilder,
          $$TasksTableTableUpdateCompanionBuilder,
          (
            TasksTableData,
            BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
          ),
          TasksTableData,
          PrefetchHooks Function()
        > {
  $$TasksTableTableTableManager(_$AppDatabase db, $TasksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<String> assignee = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
              }) => TasksTableCompanion(
                id: id,
                name: name,
                dueDate: dueDate,
                assignee: assignee,
                isCompleted: isCompleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String dueDate,
                required String assignee,
                required bool isCompleted,
              }) => TasksTableCompanion.insert(
                id: id,
                name: name,
                dueDate: dueDate,
                assignee: assignee,
                isCompleted: isCompleted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTableTable, TasksTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TasksTableTable,
                    TasksTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTableTable,
      TasksTableData,
      $$TasksTableTableFilterComposer,
      $$TasksTableTableOrderingComposer,
      $$TasksTableTableAnnotationComposer,
      $$TasksTableTableCreateCompanionBuilder,
      $$TasksTableTableUpdateCompanionBuilder,
      (
        TasksTableData,
        BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
      ),
      TasksTableData,
      PrefetchHooks Function()
    >;
typedef $$StockAlertsTableTableCreateCompanionBuilder =
    StockAlertsTableCompanion Function({
      Value<int> id,
      required String assetName,
      required String currentStatus,
      required String recommendation,
      required String colorHex,
      required String bgHex,
    });
typedef $$StockAlertsTableTableUpdateCompanionBuilder =
    StockAlertsTableCompanion Function({
      Value<int> id,
      Value<String> assetName,
      Value<String> currentStatus,
      Value<String> recommendation,
      Value<String> colorHex,
      Value<String> bgHex,
    });

class $$StockAlertsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StockAlertsTableTable> {
  $$StockAlertsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentStatus => $composableBuilder(
    column: $table.currentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bgHex => $composableBuilder(
    column: $table.bgHex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockAlertsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StockAlertsTableTable> {
  $$StockAlertsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentStatus => $composableBuilder(
    column: $table.currentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bgHex => $composableBuilder(
    column: $table.bgHex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockAlertsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockAlertsTableTable> {
  $$StockAlertsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get assetName =>
      $composableBuilder(column: $table.assetName, builder: (column) => column);

  GeneratedColumn<String> get currentStatus => $composableBuilder(
    column: $table.currentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get bgHex =>
      $composableBuilder(column: $table.bgHex, builder: (column) => column);
}

class $$StockAlertsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockAlertsTableTable,
          StockAlertsTableData,
          $$StockAlertsTableTableFilterComposer,
          $$StockAlertsTableTableOrderingComposer,
          $$StockAlertsTableTableAnnotationComposer,
          $$StockAlertsTableTableCreateCompanionBuilder,
          $$StockAlertsTableTableUpdateCompanionBuilder,
          (
            StockAlertsTableData,
            BaseReferences<
              _$AppDatabase,
              $StockAlertsTableTable,
              StockAlertsTableData
            >,
          ),
          StockAlertsTableData,
          PrefetchHooks Function()
        > {
  $$StockAlertsTableTableTableManager(
    _$AppDatabase db,
    $StockAlertsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockAlertsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockAlertsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockAlertsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> assetName = const Value.absent(),
                Value<String> currentStatus = const Value.absent(),
                Value<String> recommendation = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String> bgHex = const Value.absent(),
              }) => StockAlertsTableCompanion(
                id: id,
                assetName: assetName,
                currentStatus: currentStatus,
                recommendation: recommendation,
                colorHex: colorHex,
                bgHex: bgHex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String assetName,
                required String currentStatus,
                required String recommendation,
                required String colorHex,
                required String bgHex,
              }) => StockAlertsTableCompanion.insert(
                id: id,
                assetName: assetName,
                currentStatus: currentStatus,
                recommendation: recommendation,
                colorHex: colorHex,
                bgHex: bgHex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockAlertsTableTable, StockAlertsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $StockAlertsTableTable,
                    StockAlertsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockAlertsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockAlertsTableTable,
      StockAlertsTableData,
      $$StockAlertsTableTableFilterComposer,
      $$StockAlertsTableTableOrderingComposer,
      $$StockAlertsTableTableAnnotationComposer,
      $$StockAlertsTableTableCreateCompanionBuilder,
      $$StockAlertsTableTableUpdateCompanionBuilder,
      (
        StockAlertsTableData,
        BaseReferences<
          _$AppDatabase,
          $StockAlertsTableTable,
          StockAlertsTableData
        >,
      ),
      StockAlertsTableData,
      PrefetchHooks Function()
    >;
typedef $$ClientsTableTableCreateCompanionBuilder =
    ClientsTableCompanion Function({
      required String id,
      required String name,
      required String contactPerson,
      required String email,
      required String phone,
      required String status,
      required String industry,
      required int totalProjects,
      required double advancedPayment,
      required double fullPayment,
      Value<int> rowid,
    });
typedef $$ClientsTableTableUpdateCompanionBuilder =
    ClientsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> contactPerson,
      Value<String> email,
      Value<String> phone,
      Value<String> status,
      Value<String> industry,
      Value<int> totalProjects,
      Value<double> advancedPayment,
      Value<double> fullPayment,
      Value<int> rowid,
    });

class $$ClientsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get industry => $composableBuilder(
    column: $table.industry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalProjects => $composableBuilder(
    column: $table.totalProjects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get advancedPayment => $composableBuilder(
    column: $table.advancedPayment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fullPayment => $composableBuilder(
    column: $table.fullPayment,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get industry => $composableBuilder(
    column: $table.industry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalProjects => $composableBuilder(
    column: $table.totalProjects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get advancedPayment => $composableBuilder(
    column: $table.advancedPayment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fullPayment => $composableBuilder(
    column: $table.fullPayment,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get industry =>
      $composableBuilder(column: $table.industry, builder: (column) => column);

  GeneratedColumn<int> get totalProjects => $composableBuilder(
    column: $table.totalProjects,
    builder: (column) => column,
  );

  GeneratedColumn<double> get advancedPayment => $composableBuilder(
    column: $table.advancedPayment,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fullPayment => $composableBuilder(
    column: $table.fullPayment,
    builder: (column) => column,
  );
}

class $$ClientsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientsTableTable,
          ClientsTableData,
          $$ClientsTableTableFilterComposer,
          $$ClientsTableTableOrderingComposer,
          $$ClientsTableTableAnnotationComposer,
          $$ClientsTableTableCreateCompanionBuilder,
          $$ClientsTableTableUpdateCompanionBuilder,
          (
            ClientsTableData,
            BaseReferences<_$AppDatabase, $ClientsTableTable, ClientsTableData>,
          ),
          ClientsTableData,
          PrefetchHooks Function()
        > {
  $$ClientsTableTableTableManager(_$AppDatabase db, $ClientsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> contactPerson = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> industry = const Value.absent(),
                Value<int> totalProjects = const Value.absent(),
                Value<double> advancedPayment = const Value.absent(),
                Value<double> fullPayment = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsTableCompanion(
                id: id,
                name: name,
                contactPerson: contactPerson,
                email: email,
                phone: phone,
                status: status,
                industry: industry,
                totalProjects: totalProjects,
                advancedPayment: advancedPayment,
                fullPayment: fullPayment,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String contactPerson,
                required String email,
                required String phone,
                required String status,
                required String industry,
                required int totalProjects,
                required double advancedPayment,
                required double fullPayment,
                Value<int> rowid = const Value.absent(),
              }) => ClientsTableCompanion.insert(
                id: id,
                name: name,
                contactPerson: contactPerson,
                email: email,
                phone: phone,
                status: status,
                industry: industry,
                totalProjects: totalProjects,
                advancedPayment: advancedPayment,
                fullPayment: fullPayment,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClientsTableTable, ClientsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ClientsTableTable,
                    ClientsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientsTableTable,
      ClientsTableData,
      $$ClientsTableTableFilterComposer,
      $$ClientsTableTableOrderingComposer,
      $$ClientsTableTableAnnotationComposer,
      $$ClientsTableTableCreateCompanionBuilder,
      $$ClientsTableTableUpdateCompanionBuilder,
      (
        ClientsTableData,
        BaseReferences<_$AppDatabase, $ClientsTableTable, ClientsTableData>,
      ),
      ClientsTableData,
      PrefetchHooks Function()
    >;
typedef $$BankAccountsTableTableCreateCompanionBuilder =
    BankAccountsTableCompanion Function({
      required String id,
      required String name,
      required String type,
      required String accountNumber,
      required String bankName,
      required double balance,
      required String status,
      Value<double> openingBalance,
      Value<String> openingBalanceDate,
      Value<String> accountScope,
      Value<String> ownerName,
      Value<int> rowid,
    });
typedef $$BankAccountsTableTableUpdateCompanionBuilder =
    BankAccountsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> accountNumber,
      Value<String> bankName,
      Value<double> balance,
      Value<String> status,
      Value<double> openingBalance,
      Value<String> openingBalanceDate,
      Value<String> accountScope,
      Value<String> ownerName,
      Value<int> rowid,
    });

class $$BankAccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BankAccountsTableTable> {
  $$BankAccountsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingBalanceDate => $composableBuilder(
    column: $table.openingBalanceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BankAccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BankAccountsTableTable> {
  $$BankAccountsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingBalanceDate => $composableBuilder(
    column: $table.openingBalanceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BankAccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BankAccountsTableTable> {
  $$BankAccountsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openingBalanceDate => $composableBuilder(
    column: $table.openingBalanceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);
}

class $$BankAccountsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BankAccountsTableTable,
          BankAccountsTableData,
          $$BankAccountsTableTableFilterComposer,
          $$BankAccountsTableTableOrderingComposer,
          $$BankAccountsTableTableAnnotationComposer,
          $$BankAccountsTableTableCreateCompanionBuilder,
          $$BankAccountsTableTableUpdateCompanionBuilder,
          (
            BankAccountsTableData,
            BaseReferences<
              _$AppDatabase,
              $BankAccountsTableTable,
              BankAccountsTableData
            >,
          ),
          BankAccountsTableData,
          PrefetchHooks Function()
        > {
  $$BankAccountsTableTableTableManager(
    _$AppDatabase db,
    $BankAccountsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BankAccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BankAccountsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BankAccountsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> accountNumber = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<String> openingBalanceDate = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BankAccountsTableCompanion(
                id: id,
                name: name,
                type: type,
                accountNumber: accountNumber,
                bankName: bankName,
                balance: balance,
                status: status,
                openingBalance: openingBalance,
                openingBalanceDate: openingBalanceDate,
                accountScope: accountScope,
                ownerName: ownerName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required String accountNumber,
                required String bankName,
                required double balance,
                required String status,
                Value<double> openingBalance = const Value.absent(),
                Value<String> openingBalanceDate = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BankAccountsTableCompanion.insert(
                id: id,
                name: name,
                type: type,
                accountNumber: accountNumber,
                bankName: bankName,
                balance: balance,
                status: status,
                openingBalance: openingBalance,
                openingBalanceDate: openingBalanceDate,
                accountScope: accountScope,
                ownerName: ownerName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BankAccountsTableTable, BankAccountsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $BankAccountsTableTable,
                    BankAccountsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BankAccountsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BankAccountsTableTable,
      BankAccountsTableData,
      $$BankAccountsTableTableFilterComposer,
      $$BankAccountsTableTableOrderingComposer,
      $$BankAccountsTableTableAnnotationComposer,
      $$BankAccountsTableTableCreateCompanionBuilder,
      $$BankAccountsTableTableUpdateCompanionBuilder,
      (
        BankAccountsTableData,
        BaseReferences<
          _$AppDatabase,
          $BankAccountsTableTable,
          BankAccountsTableData
        >,
      ),
      BankAccountsTableData,
      PrefetchHooks Function()
    >;
typedef $$ExpenseRecordsTableTableCreateCompanionBuilder =
    ExpenseRecordsTableCompanion Function({
      required String id,
      required String date,
      required double amount,
      required String accountId,
      required String category,
      required String vendorName,
      required String description,
      Value<int> rowid,
    });
typedef $$ExpenseRecordsTableTableUpdateCompanionBuilder =
    ExpenseRecordsTableCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<double> amount,
      Value<String> accountId,
      Value<String> category,
      Value<String> vendorName,
      Value<String> description,
      Value<int> rowid,
    });

class $$ExpenseRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseRecordsTableTable> {
  $$ExpenseRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpenseRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseRecordsTableTable> {
  $$ExpenseRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpenseRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseRecordsTableTable> {
  $$ExpenseRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$ExpenseRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseRecordsTableTable,
          ExpenseRecordsTableData,
          $$ExpenseRecordsTableTableFilterComposer,
          $$ExpenseRecordsTableTableOrderingComposer,
          $$ExpenseRecordsTableTableAnnotationComposer,
          $$ExpenseRecordsTableTableCreateCompanionBuilder,
          $$ExpenseRecordsTableTableUpdateCompanionBuilder,
          (
            ExpenseRecordsTableData,
            BaseReferences<
              _$AppDatabase,
              $ExpenseRecordsTableTable,
              ExpenseRecordsTableData
            >,
          ),
          ExpenseRecordsTableData,
          PrefetchHooks Function()
        > {
  $$ExpenseRecordsTableTableTableManager(
    _$AppDatabase db,
    $ExpenseRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseRecordsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExpenseRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> vendorName = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseRecordsTableCompanion(
                id: id,
                date: date,
                amount: amount,
                accountId: accountId,
                category: category,
                vendorName: vendorName,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required double amount,
                required String accountId,
                required String category,
                required String vendorName,
                required String description,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseRecordsTableCompanion.insert(
                id: id,
                date: date,
                amount: amount,
                accountId: accountId,
                category: category,
                vendorName: vendorName,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ExpenseRecordsTableTable,
                    ExpenseRecordsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExpenseRecordsTableTable,
                    ExpenseRecordsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseRecordsTableTable,
      ExpenseRecordsTableData,
      $$ExpenseRecordsTableTableFilterComposer,
      $$ExpenseRecordsTableTableOrderingComposer,
      $$ExpenseRecordsTableTableAnnotationComposer,
      $$ExpenseRecordsTableTableCreateCompanionBuilder,
      $$ExpenseRecordsTableTableUpdateCompanionBuilder,
      (
        ExpenseRecordsTableData,
        BaseReferences<
          _$AppDatabase,
          $ExpenseRecordsTableTable,
          ExpenseRecordsTableData
        >,
      ),
      ExpenseRecordsTableData,
      PrefetchHooks Function()
    >;
typedef $$IncomeRecordsTableTableCreateCompanionBuilder =
    IncomeRecordsTableCompanion Function({
      required String id,
      required String date,
      required String clientId,
      required String clientName,
      required double amount,
      required String accountId,
      required String invoiceNumber,
      required String description,
      required String status,
      Value<String?> projectId,
      Value<String?> projectName,
      Value<String?> projectPaymentType,
      Value<int> rowid,
    });
typedef $$IncomeRecordsTableTableUpdateCompanionBuilder =
    IncomeRecordsTableCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> clientId,
      Value<String> clientName,
      Value<double> amount,
      Value<String> accountId,
      Value<String> invoiceNumber,
      Value<String> description,
      Value<String> status,
      Value<String?> projectId,
      Value<String?> projectName,
      Value<String?> projectPaymentType,
      Value<int> rowid,
    });

class $$IncomeRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeRecordsTableTable> {
  $$IncomeRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectPaymentType => $composableBuilder(
    column: $table.projectPaymentType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IncomeRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeRecordsTableTable> {
  $$IncomeRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectPaymentType => $composableBuilder(
    column: $table.projectPaymentType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncomeRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeRecordsTableTable> {
  $$IncomeRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectPaymentType => $composableBuilder(
    column: $table.projectPaymentType,
    builder: (column) => column,
  );
}

class $$IncomeRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeRecordsTableTable,
          IncomeRecordsTableData,
          $$IncomeRecordsTableTableFilterComposer,
          $$IncomeRecordsTableTableOrderingComposer,
          $$IncomeRecordsTableTableAnnotationComposer,
          $$IncomeRecordsTableTableCreateCompanionBuilder,
          $$IncomeRecordsTableTableUpdateCompanionBuilder,
          (
            IncomeRecordsTableData,
            BaseReferences<
              _$AppDatabase,
              $IncomeRecordsTableTable,
              IncomeRecordsTableData
            >,
          ),
          IncomeRecordsTableData,
          PrefetchHooks Function()
        > {
  $$IncomeRecordsTableTableTableManager(
    _$AppDatabase db,
    $IncomeRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomeRecordsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomeRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> clientName = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> invoiceNumber = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String?> projectPaymentType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomeRecordsTableCompanion(
                id: id,
                date: date,
                clientId: clientId,
                clientName: clientName,
                amount: amount,
                accountId: accountId,
                invoiceNumber: invoiceNumber,
                description: description,
                status: status,
                projectId: projectId,
                projectName: projectName,
                projectPaymentType: projectPaymentType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String clientId,
                required String clientName,
                required double amount,
                required String accountId,
                required String invoiceNumber,
                required String description,
                required String status,
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String?> projectPaymentType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomeRecordsTableCompanion.insert(
                id: id,
                date: date,
                clientId: clientId,
                clientName: clientName,
                amount: amount,
                accountId: accountId,
                invoiceNumber: invoiceNumber,
                description: description,
                status: status,
                projectId: projectId,
                projectName: projectName,
                projectPaymentType: projectPaymentType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncomeRecordsTableTable, IncomeRecordsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $IncomeRecordsTableTable,
                    IncomeRecordsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IncomeRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeRecordsTableTable,
      IncomeRecordsTableData,
      $$IncomeRecordsTableTableFilterComposer,
      $$IncomeRecordsTableTableOrderingComposer,
      $$IncomeRecordsTableTableAnnotationComposer,
      $$IncomeRecordsTableTableCreateCompanionBuilder,
      $$IncomeRecordsTableTableUpdateCompanionBuilder,
      (
        IncomeRecordsTableData,
        BaseReferences<
          _$AppDatabase,
          $IncomeRecordsTableTable,
          IncomeRecordsTableData
        >,
      ),
      IncomeRecordsTableData,
      PrefetchHooks Function()
    >;
typedef $$LedgerEntriesTableTableCreateCompanionBuilder =
    LedgerEntriesTableCompanion Function({
      required String id,
      required String date,
      required String accountId,
      required String accountName,
      required String type,
      required String category,
      required double amount,
      required String reference,
      required String description,
      Value<int> rowid,
    });
typedef $$LedgerEntriesTableTableUpdateCompanionBuilder =
    LedgerEntriesTableCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> accountId,
      Value<String> accountName,
      Value<String> type,
      Value<String> category,
      Value<double> amount,
      Value<String> reference,
      Value<String> description,
      Value<int> rowid,
    });

class $$LedgerEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTableTable> {
  $$LedgerEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTableTable> {
  $$LedgerEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTableTable> {
  $$LedgerEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$LedgerEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTableTable,
          LedgerEntriesTableData,
          $$LedgerEntriesTableTableFilterComposer,
          $$LedgerEntriesTableTableOrderingComposer,
          $$LedgerEntriesTableTableAnnotationComposer,
          $$LedgerEntriesTableTableCreateCompanionBuilder,
          $$LedgerEntriesTableTableUpdateCompanionBuilder,
          (
            LedgerEntriesTableData,
            BaseReferences<
              _$AppDatabase,
              $LedgerEntriesTableTable,
              LedgerEntriesTableData
            >,
          ),
          LedgerEntriesTableData,
          PrefetchHooks Function()
        > {
  $$LedgerEntriesTableTableTableManager(
    _$AppDatabase db,
    $LedgerEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> accountName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesTableCompanion(
                id: id,
                date: date,
                accountId: accountId,
                accountName: accountName,
                type: type,
                category: category,
                amount: amount,
                reference: reference,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String accountId,
                required String accountName,
                required String type,
                required String category,
                required double amount,
                required String reference,
                required String description,
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesTableCompanion.insert(
                id: id,
                date: date,
                accountId: accountId,
                accountName: accountName,
                type: type,
                category: category,
                amount: amount,
                reference: reference,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTableTable, LedgerEntriesTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LedgerEntriesTableTable,
                    LedgerEntriesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTableTable,
      LedgerEntriesTableData,
      $$LedgerEntriesTableTableFilterComposer,
      $$LedgerEntriesTableTableOrderingComposer,
      $$LedgerEntriesTableTableAnnotationComposer,
      $$LedgerEntriesTableTableCreateCompanionBuilder,
      $$LedgerEntriesTableTableUpdateCompanionBuilder,
      (
        LedgerEntriesTableData,
        BaseReferences<
          _$AppDatabase,
          $LedgerEntriesTableTable,
          LedgerEntriesTableData
        >,
      ),
      LedgerEntriesTableData,
      PrefetchHooks Function()
    >;
typedef $$LoanRecordsTableTableCreateCompanionBuilder =
    LoanRecordsTableCompanion Function({
      required String id,
      required String borrowerName,
      required String type,
      required double amount,
      required double remainingBalance,
      required String startDate,
      required String endDate,
      required String status,
      required String description,
      required List<Map<String, dynamic>> repayments,
      Value<int> rowid,
    });
typedef $$LoanRecordsTableTableUpdateCompanionBuilder =
    LoanRecordsTableCompanion Function({
      Value<String> id,
      Value<String> borrowerName,
      Value<String> type,
      Value<double> amount,
      Value<double> remainingBalance,
      Value<String> startDate,
      Value<String> endDate,
      Value<String> status,
      Value<String> description,
      Value<List<Map<String, dynamic>>> repayments,
      Value<int> rowid,
    });

class $$LoanRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LoanRecordsTableTable> {
  $$LoanRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingBalance => $composableBuilder(
    column: $table.remainingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
    String
  >
  get repayments => $composableBuilder(
    column: $table.repayments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$LoanRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LoanRecordsTableTable> {
  $$LoanRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingBalance => $composableBuilder(
    column: $table.remainingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repayments => $composableBuilder(
    column: $table.repayments,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoanRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoanRecordsTableTable> {
  $$LoanRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get remainingBalance => $composableBuilder(
    column: $table.remainingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<Map<String, dynamic>>, String>
  get repayments => $composableBuilder(
    column: $table.repayments,
    builder: (column) => column,
  );
}

class $$LoanRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoanRecordsTableTable,
          LoanRecordsTableData,
          $$LoanRecordsTableTableFilterComposer,
          $$LoanRecordsTableTableOrderingComposer,
          $$LoanRecordsTableTableAnnotationComposer,
          $$LoanRecordsTableTableCreateCompanionBuilder,
          $$LoanRecordsTableTableUpdateCompanionBuilder,
          (
            LoanRecordsTableData,
            BaseReferences<
              _$AppDatabase,
              $LoanRecordsTableTable,
              LoanRecordsTableData
            >,
          ),
          LoanRecordsTableData,
          PrefetchHooks Function()
        > {
  $$LoanRecordsTableTableTableManager(
    _$AppDatabase db,
    $LoanRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoanRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoanRecordsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoanRecordsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> borrowerName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> remainingBalance = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<List<Map<String, dynamic>>> repayments =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoanRecordsTableCompanion(
                id: id,
                borrowerName: borrowerName,
                type: type,
                amount: amount,
                remainingBalance: remainingBalance,
                startDate: startDate,
                endDate: endDate,
                status: status,
                description: description,
                repayments: repayments,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String borrowerName,
                required String type,
                required double amount,
                required double remainingBalance,
                required String startDate,
                required String endDate,
                required String status,
                required String description,
                required List<Map<String, dynamic>> repayments,
                Value<int> rowid = const Value.absent(),
              }) => LoanRecordsTableCompanion.insert(
                id: id,
                borrowerName: borrowerName,
                type: type,
                amount: amount,
                remainingBalance: remainingBalance,
                startDate: startDate,
                endDate: endDate,
                status: status,
                description: description,
                repayments: repayments,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoanRecordsTableTable, LoanRecordsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LoanRecordsTableTable,
                    LoanRecordsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoanRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoanRecordsTableTable,
      LoanRecordsTableData,
      $$LoanRecordsTableTableFilterComposer,
      $$LoanRecordsTableTableOrderingComposer,
      $$LoanRecordsTableTableAnnotationComposer,
      $$LoanRecordsTableTableCreateCompanionBuilder,
      $$LoanRecordsTableTableUpdateCompanionBuilder,
      (
        LoanRecordsTableData,
        BaseReferences<
          _$AppDatabase,
          $LoanRecordsTableTable,
          LoanRecordsTableData
        >,
      ),
      LoanRecordsTableData,
      PrefetchHooks Function()
    >;
typedef $$AdvanceRecordsTableTableCreateCompanionBuilder =
    AdvanceRecordsTableCompanion Function({
      required String id,
      required String employeeId,
      required String employeeName,
      required double amount,
      required String requestDate,
      required String reason,
      required int repaymentMonths,
      required double amountRepaid,
      required String status,
      Value<int> rowid,
    });
typedef $$AdvanceRecordsTableTableUpdateCompanionBuilder =
    AdvanceRecordsTableCompanion Function({
      Value<String> id,
      Value<String> employeeId,
      Value<String> employeeName,
      Value<double> amount,
      Value<String> requestDate,
      Value<String> reason,
      Value<int> repaymentMonths,
      Value<double> amountRepaid,
      Value<String> status,
      Value<int> rowid,
    });

class $$AdvanceRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AdvanceRecordsTableTable> {
  $$AdvanceRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestDate => $composableBuilder(
    column: $table.requestDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repaymentMonths => $composableBuilder(
    column: $table.repaymentMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountRepaid => $composableBuilder(
    column: $table.amountRepaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdvanceRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AdvanceRecordsTableTable> {
  $$AdvanceRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestDate => $composableBuilder(
    column: $table.requestDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repaymentMonths => $composableBuilder(
    column: $table.repaymentMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountRepaid => $composableBuilder(
    column: $table.amountRepaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdvanceRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdvanceRecordsTableTable> {
  $$AdvanceRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get requestDate => $composableBuilder(
    column: $table.requestDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get repaymentMonths => $composableBuilder(
    column: $table.repaymentMonths,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amountRepaid => $composableBuilder(
    column: $table.amountRepaid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$AdvanceRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdvanceRecordsTableTable,
          AdvanceRecordsTableData,
          $$AdvanceRecordsTableTableFilterComposer,
          $$AdvanceRecordsTableTableOrderingComposer,
          $$AdvanceRecordsTableTableAnnotationComposer,
          $$AdvanceRecordsTableTableCreateCompanionBuilder,
          $$AdvanceRecordsTableTableUpdateCompanionBuilder,
          (
            AdvanceRecordsTableData,
            BaseReferences<
              _$AppDatabase,
              $AdvanceRecordsTableTable,
              AdvanceRecordsTableData
            >,
          ),
          AdvanceRecordsTableData,
          PrefetchHooks Function()
        > {
  $$AdvanceRecordsTableTableTableManager(
    _$AppDatabase db,
    $AdvanceRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvanceRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdvanceRecordsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdvanceRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> employeeName = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> requestDate = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> repaymentMonths = const Value.absent(),
                Value<double> amountRepaid = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvanceRecordsTableCompanion(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                amount: amount,
                requestDate: requestDate,
                reason: reason,
                repaymentMonths: repaymentMonths,
                amountRepaid: amountRepaid,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String employeeId,
                required String employeeName,
                required double amount,
                required String requestDate,
                required String reason,
                required int repaymentMonths,
                required double amountRepaid,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => AdvanceRecordsTableCompanion.insert(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                amount: amount,
                requestDate: requestDate,
                reason: reason,
                repaymentMonths: repaymentMonths,
                amountRepaid: amountRepaid,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AdvanceRecordsTableTable,
                    AdvanceRecordsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AdvanceRecordsTableTable,
                    AdvanceRecordsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdvanceRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdvanceRecordsTableTable,
      AdvanceRecordsTableData,
      $$AdvanceRecordsTableTableFilterComposer,
      $$AdvanceRecordsTableTableOrderingComposer,
      $$AdvanceRecordsTableTableAnnotationComposer,
      $$AdvanceRecordsTableTableCreateCompanionBuilder,
      $$AdvanceRecordsTableTableUpdateCompanionBuilder,
      (
        AdvanceRecordsTableData,
        BaseReferences<
          _$AppDatabase,
          $AdvanceRecordsTableTable,
          AdvanceRecordsTableData
        >,
      ),
      AdvanceRecordsTableData,
      PrefetchHooks Function()
    >;
typedef $$AttendanceRecordsTableTableCreateCompanionBuilder =
    AttendanceRecordsTableCompanion Function({
      required String id,
      required String employeeId,
      required String employeeName,
      required String date,
      required String status,
      Value<String?> checkIn,
      Value<String?> checkOut,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$AttendanceRecordsTableTableUpdateCompanionBuilder =
    AttendanceRecordsTableCompanion Function({
      Value<String> id,
      Value<String> employeeId,
      Value<String> employeeName,
      Value<String> date,
      Value<String> status,
      Value<String?> checkIn,
      Value<String?> checkOut,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$AttendanceRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTableTable> {
  $$AttendanceRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkIn => $composableBuilder(
    column: $table.checkIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkOut => $composableBuilder(
    column: $table.checkOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTableTable> {
  $$AttendanceRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkIn => $composableBuilder(
    column: $table.checkIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkOut => $composableBuilder(
    column: $table.checkOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTableTable> {
  $$AttendanceRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get checkIn =>
      $composableBuilder(column: $table.checkIn, builder: (column) => column);

  GeneratedColumn<String> get checkOut =>
      $composableBuilder(column: $table.checkOut, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$AttendanceRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceRecordsTableTable,
          AttendanceRecordsTableData,
          $$AttendanceRecordsTableTableFilterComposer,
          $$AttendanceRecordsTableTableOrderingComposer,
          $$AttendanceRecordsTableTableAnnotationComposer,
          $$AttendanceRecordsTableTableCreateCompanionBuilder,
          $$AttendanceRecordsTableTableUpdateCompanionBuilder,
          (
            AttendanceRecordsTableData,
            BaseReferences<
              _$AppDatabase,
              $AttendanceRecordsTableTable,
              AttendanceRecordsTableData
            >,
          ),
          AttendanceRecordsTableData,
          PrefetchHooks Function()
        > {
  $$AttendanceRecordsTableTableTableManager(
    _$AppDatabase db,
    $AttendanceRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceRecordsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> employeeName = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> checkIn = const Value.absent(),
                Value<String?> checkOut = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordsTableCompanion(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                date: date,
                status: status,
                checkIn: checkIn,
                checkOut: checkOut,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String employeeId,
                required String employeeName,
                required String date,
                required String status,
                Value<String?> checkIn = const Value.absent(),
                Value<String?> checkOut = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordsTableCompanion.insert(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                date: date,
                status: status,
                checkIn: checkIn,
                checkOut: checkOut,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AttendanceRecordsTableTable,
                    AttendanceRecordsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AttendanceRecordsTableTable,
                    AttendanceRecordsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceRecordsTableTable,
      AttendanceRecordsTableData,
      $$AttendanceRecordsTableTableFilterComposer,
      $$AttendanceRecordsTableTableOrderingComposer,
      $$AttendanceRecordsTableTableAnnotationComposer,
      $$AttendanceRecordsTableTableCreateCompanionBuilder,
      $$AttendanceRecordsTableTableUpdateCompanionBuilder,
      (
        AttendanceRecordsTableData,
        BaseReferences<
          _$AppDatabase,
          $AttendanceRecordsTableTable,
          AttendanceRecordsTableData
        >,
      ),
      AttendanceRecordsTableData,
      PrefetchHooks Function()
    >;
typedef $$EmployeesTableTableCreateCompanionBuilder =
    EmployeesTableCompanion Function({
      required String id,
      required String name,
      required String email,
      required List<String> phones,
      Value<String> cnic,
      required String designation,
      required String department,
      required String joiningDate,
      Value<String?> leavingDate,
      required String status,
      required String salaryType,
      required double baseSalary,
      required String paymentMethod,
      Value<int> rowid,
    });
typedef $$EmployeesTableTableUpdateCompanionBuilder =
    EmployeesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> email,
      Value<List<String>> phones,
      Value<String> cnic,
      Value<String> designation,
      Value<String> department,
      Value<String> joiningDate,
      Value<String?> leavingDate,
      Value<String> status,
      Value<String> salaryType,
      Value<double> baseSalary,
      Value<String> paymentMethod,
      Value<int> rowid,
    });

class $$EmployeesTableTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get phones => $composableBuilder(
    column: $table.phones,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get cnic => $composableBuilder(
    column: $table.cnic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get designation => $composableBuilder(
    column: $table.designation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joiningDate => $composableBuilder(
    column: $table.joiningDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leavingDate => $composableBuilder(
    column: $table.leavingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salaryType => $composableBuilder(
    column: $table.salaryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmployeesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phones => $composableBuilder(
    column: $table.phones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cnic => $composableBuilder(
    column: $table.cnic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get designation => $composableBuilder(
    column: $table.designation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joiningDate => $composableBuilder(
    column: $table.joiningDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leavingDate => $composableBuilder(
    column: $table.leavingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salaryType => $composableBuilder(
    column: $table.salaryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployeesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableAnnotationComposer({
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

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get phones =>
      $composableBuilder(column: $table.phones, builder: (column) => column);

  GeneratedColumn<String> get cnic =>
      $composableBuilder(column: $table.cnic, builder: (column) => column);

  GeneratedColumn<String> get designation => $composableBuilder(
    column: $table.designation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => column,
  );

  GeneratedColumn<String> get joiningDate => $composableBuilder(
    column: $table.joiningDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get leavingDate => $composableBuilder(
    column: $table.leavingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get salaryType => $composableBuilder(
    column: $table.salaryType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );
}

class $$EmployeesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeesTableTable,
          EmployeesTableData,
          $$EmployeesTableTableFilterComposer,
          $$EmployeesTableTableOrderingComposer,
          $$EmployeesTableTableAnnotationComposer,
          $$EmployeesTableTableCreateCompanionBuilder,
          $$EmployeesTableTableUpdateCompanionBuilder,
          (
            EmployeesTableData,
            BaseReferences<
              _$AppDatabase,
              $EmployeesTableTable,
              EmployeesTableData
            >,
          ),
          EmployeesTableData,
          PrefetchHooks Function()
        > {
  $$EmployeesTableTableTableManager(
    _$AppDatabase db,
    $EmployeesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<List<String>> phones = const Value.absent(),
                Value<String> cnic = const Value.absent(),
                Value<String> designation = const Value.absent(),
                Value<String> department = const Value.absent(),
                Value<String> joiningDate = const Value.absent(),
                Value<String?> leavingDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> salaryType = const Value.absent(),
                Value<double> baseSalary = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeesTableCompanion(
                id: id,
                name: name,
                email: email,
                phones: phones,
                cnic: cnic,
                designation: designation,
                department: department,
                joiningDate: joiningDate,
                leavingDate: leavingDate,
                status: status,
                salaryType: salaryType,
                baseSalary: baseSalary,
                paymentMethod: paymentMethod,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String email,
                required List<String> phones,
                Value<String> cnic = const Value.absent(),
                required String designation,
                required String department,
                required String joiningDate,
                Value<String?> leavingDate = const Value.absent(),
                required String status,
                required String salaryType,
                required double baseSalary,
                required String paymentMethod,
                Value<int> rowid = const Value.absent(),
              }) => EmployeesTableCompanion.insert(
                id: id,
                name: name,
                email: email,
                phones: phones,
                cnic: cnic,
                designation: designation,
                department: department,
                joiningDate: joiningDate,
                leavingDate: leavingDate,
                status: status,
                salaryType: salaryType,
                baseSalary: baseSalary,
                paymentMethod: paymentMethod,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmployeesTableTable, EmployeesTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EmployeesTableTable,
                    EmployeesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmployeesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeesTableTable,
      EmployeesTableData,
      $$EmployeesTableTableFilterComposer,
      $$EmployeesTableTableOrderingComposer,
      $$EmployeesTableTableAnnotationComposer,
      $$EmployeesTableTableCreateCompanionBuilder,
      $$EmployeesTableTableUpdateCompanionBuilder,
      (
        EmployeesTableData,
        BaseReferences<_$AppDatabase, $EmployeesTableTable, EmployeesTableData>,
      ),
      EmployeesTableData,
      PrefetchHooks Function()
    >;
typedef $$SalaryRecordsTableTableCreateCompanionBuilder =
    SalaryRecordsTableCompanion Function({
      required String id,
      required String employeeId,
      required String employeeName,
      required String payPeriod,
      required double baseSalary,
      required double allowances,
      required double deductions,
      required double netPaid,
      required String paymentDate,
      required String status,
      required String paymentMethod,
      Value<int> rowid,
    });
typedef $$SalaryRecordsTableTableUpdateCompanionBuilder =
    SalaryRecordsTableCompanion Function({
      Value<String> id,
      Value<String> employeeId,
      Value<String> employeeName,
      Value<String> payPeriod,
      Value<double> baseSalary,
      Value<double> allowances,
      Value<double> deductions,
      Value<double> netPaid,
      Value<String> paymentDate,
      Value<String> status,
      Value<String> paymentMethod,
      Value<int> rowid,
    });

class $$SalaryRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SalaryRecordsTableTable> {
  $$SalaryRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payPeriod => $composableBuilder(
    column: $table.payPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get allowances => $composableBuilder(
    column: $table.allowances,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netPaid => $composableBuilder(
    column: $table.netPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SalaryRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SalaryRecordsTableTable> {
  $$SalaryRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payPeriod => $composableBuilder(
    column: $table.payPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get allowances => $composableBuilder(
    column: $table.allowances,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netPaid => $composableBuilder(
    column: $table.netPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalaryRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalaryRecordsTableTable> {
  $$SalaryRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payPeriod =>
      $composableBuilder(column: $table.payPeriod, builder: (column) => column);

  GeneratedColumn<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => column,
  );

  GeneratedColumn<double> get allowances => $composableBuilder(
    column: $table.allowances,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => column,
  );

  GeneratedColumn<double> get netPaid =>
      $composableBuilder(column: $table.netPaid, builder: (column) => column);

  GeneratedColumn<String> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );
}

class $$SalaryRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalaryRecordsTableTable,
          SalaryRecordsTableData,
          $$SalaryRecordsTableTableFilterComposer,
          $$SalaryRecordsTableTableOrderingComposer,
          $$SalaryRecordsTableTableAnnotationComposer,
          $$SalaryRecordsTableTableCreateCompanionBuilder,
          $$SalaryRecordsTableTableUpdateCompanionBuilder,
          (
            SalaryRecordsTableData,
            BaseReferences<
              _$AppDatabase,
              $SalaryRecordsTableTable,
              SalaryRecordsTableData
            >,
          ),
          SalaryRecordsTableData,
          PrefetchHooks Function()
        > {
  $$SalaryRecordsTableTableTableManager(
    _$AppDatabase db,
    $SalaryRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalaryRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalaryRecordsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalaryRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> employeeName = const Value.absent(),
                Value<String> payPeriod = const Value.absent(),
                Value<double> baseSalary = const Value.absent(),
                Value<double> allowances = const Value.absent(),
                Value<double> deductions = const Value.absent(),
                Value<double> netPaid = const Value.absent(),
                Value<String> paymentDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalaryRecordsTableCompanion(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                payPeriod: payPeriod,
                baseSalary: baseSalary,
                allowances: allowances,
                deductions: deductions,
                netPaid: netPaid,
                paymentDate: paymentDate,
                status: status,
                paymentMethod: paymentMethod,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String employeeId,
                required String employeeName,
                required String payPeriod,
                required double baseSalary,
                required double allowances,
                required double deductions,
                required double netPaid,
                required String paymentDate,
                required String status,
                required String paymentMethod,
                Value<int> rowid = const Value.absent(),
              }) => SalaryRecordsTableCompanion.insert(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                payPeriod: payPeriod,
                baseSalary: baseSalary,
                allowances: allowances,
                deductions: deductions,
                netPaid: netPaid,
                paymentDate: paymentDate,
                status: status,
                paymentMethod: paymentMethod,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SalaryRecordsTableTable, SalaryRecordsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SalaryRecordsTableTable,
                    SalaryRecordsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SalaryRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalaryRecordsTableTable,
      SalaryRecordsTableData,
      $$SalaryRecordsTableTableFilterComposer,
      $$SalaryRecordsTableTableOrderingComposer,
      $$SalaryRecordsTableTableAnnotationComposer,
      $$SalaryRecordsTableTableCreateCompanionBuilder,
      $$SalaryRecordsTableTableUpdateCompanionBuilder,
      (
        SalaryRecordsTableData,
        BaseReferences<
          _$AppDatabase,
          $SalaryRecordsTableTable,
          SalaryRecordsTableData
        >,
      ),
      SalaryRecordsTableData,
      PrefetchHooks Function()
    >;
typedef $$AssetsTableTableCreateCompanionBuilder =
    AssetsTableCompanion Function({
      required String id,
      required String name,
      required String type,
      required String serialNumber,
      required String purchaseDate,
      required double cost,
      required String status,
      required String condition,
      Value<String?> assignedToId,
      Value<String?> assignedToName,
      Value<int> rowid,
    });
typedef $$AssetsTableTableUpdateCompanionBuilder =
    AssetsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> serialNumber,
      Value<String> purchaseDate,
      Value<double> cost,
      Value<String> status,
      Value<String> condition,
      Value<String?> assignedToId,
      Value<String?> assignedToName,
      Value<int> rowid,
    });

class $$AssetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTableTable> {
  $$AssetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedToId => $composableBuilder(
    column: $table.assignedToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedToName => $composableBuilder(
    column: $table.assignedToName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTableTable> {
  $$AssetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedToId => $composableBuilder(
    column: $table.assignedToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedToName => $composableBuilder(
    column: $table.assignedToName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTableTable> {
  $$AssetsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get assignedToId => $composableBuilder(
    column: $table.assignedToId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assignedToName => $composableBuilder(
    column: $table.assignedToName,
    builder: (column) => column,
  );
}

class $$AssetsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTableTable,
          AssetsTableData,
          $$AssetsTableTableFilterComposer,
          $$AssetsTableTableOrderingComposer,
          $$AssetsTableTableAnnotationComposer,
          $$AssetsTableTableCreateCompanionBuilder,
          $$AssetsTableTableUpdateCompanionBuilder,
          (
            AssetsTableData,
            BaseReferences<_$AppDatabase, $AssetsTableTable, AssetsTableData>,
          ),
          AssetsTableData,
          PrefetchHooks Function()
        > {
  $$AssetsTableTableTableManager(_$AppDatabase db, $AssetsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> serialNumber = const Value.absent(),
                Value<String> purchaseDate = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<String?> assignedToId = const Value.absent(),
                Value<String?> assignedToName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsTableCompanion(
                id: id,
                name: name,
                type: type,
                serialNumber: serialNumber,
                purchaseDate: purchaseDate,
                cost: cost,
                status: status,
                condition: condition,
                assignedToId: assignedToId,
                assignedToName: assignedToName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required String serialNumber,
                required String purchaseDate,
                required double cost,
                required String status,
                required String condition,
                Value<String?> assignedToId = const Value.absent(),
                Value<String?> assignedToName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsTableCompanion.insert(
                id: id,
                name: name,
                type: type,
                serialNumber: serialNumber,
                purchaseDate: purchaseDate,
                cost: cost,
                status: status,
                condition: condition,
                assignedToId: assignedToId,
                assignedToName: assignedToName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetsTableTable, AssetsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AssetsTableTable,
                    AssetsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTableTable,
      AssetsTableData,
      $$AssetsTableTableFilterComposer,
      $$AssetsTableTableOrderingComposer,
      $$AssetsTableTableAnnotationComposer,
      $$AssetsTableTableCreateCompanionBuilder,
      $$AssetsTableTableUpdateCompanionBuilder,
      (
        AssetsTableData,
        BaseReferences<_$AppDatabase, $AssetsTableTable, AssetsTableData>,
      ),
      AssetsTableData,
      PrefetchHooks Function()
    >;
typedef $$InventoryItemsTableTableCreateCompanionBuilder =
    InventoryItemsTableCompanion Function({
      required String id,
      required String name,
      required String category,
      required int quantity,
      required int minQuantity,
      required String unit,
      required double pricePerUnit,
      required String lastRestockedDate,
      Value<int> rowid,
    });
typedef $$InventoryItemsTableTableUpdateCompanionBuilder =
    InventoryItemsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<int> quantity,
      Value<int> minQuantity,
      Value<String> unit,
      Value<double> pricePerUnit,
      Value<String> lastRestockedDate,
      Value<int> rowid,
    });

class $$InventoryItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTableTable> {
  $$InventoryItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastRestockedDate => $composableBuilder(
    column: $table.lastRestockedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTableTable> {
  $$InventoryItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastRestockedDate => $composableBuilder(
    column: $table.lastRestockedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTableTable> {
  $$InventoryItemsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastRestockedDate => $composableBuilder(
    column: $table.lastRestockedDate,
    builder: (column) => column,
  );
}

class $$InventoryItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryItemsTableTable,
          InventoryItemsTableData,
          $$InventoryItemsTableTableFilterComposer,
          $$InventoryItemsTableTableOrderingComposer,
          $$InventoryItemsTableTableAnnotationComposer,
          $$InventoryItemsTableTableCreateCompanionBuilder,
          $$InventoryItemsTableTableUpdateCompanionBuilder,
          (
            InventoryItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $InventoryItemsTableTable,
              InventoryItemsTableData
            >,
          ),
          InventoryItemsTableData,
          PrefetchHooks Function()
        > {
  $$InventoryItemsTableTableTableManager(
    _$AppDatabase db,
    $InventoryItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> minQuantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> pricePerUnit = const Value.absent(),
                Value<String> lastRestockedDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsTableCompanion(
                id: id,
                name: name,
                category: category,
                quantity: quantity,
                minQuantity: minQuantity,
                unit: unit,
                pricePerUnit: pricePerUnit,
                lastRestockedDate: lastRestockedDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required int quantity,
                required int minQuantity,
                required String unit,
                required double pricePerUnit,
                required String lastRestockedDate,
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsTableCompanion.insert(
                id: id,
                name: name,
                category: category,
                quantity: quantity,
                minQuantity: minQuantity,
                unit: unit,
                pricePerUnit: pricePerUnit,
                lastRestockedDate: lastRestockedDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InventoryItemsTableTable,
                    InventoryItemsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InventoryItemsTableTable,
                    InventoryItemsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryItemsTableTable,
      InventoryItemsTableData,
      $$InventoryItemsTableTableFilterComposer,
      $$InventoryItemsTableTableOrderingComposer,
      $$InventoryItemsTableTableAnnotationComposer,
      $$InventoryItemsTableTableCreateCompanionBuilder,
      $$InventoryItemsTableTableUpdateCompanionBuilder,
      (
        InventoryItemsTableData,
        BaseReferences<
          _$AppDatabase,
          $InventoryItemsTableTable,
          InventoryItemsTableData
        >,
      ),
      InventoryItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableTableCreateCompanionBuilder =
    ProjectsTableCompanion Function({
      required String id,
      required String name,
      required String description,
      required String clientId,
      required String clientName,
      required String startDate,
      required String endDate,
      required String status,
      required double budget,
      required double advancedPayment,
      required double partialPayments,
      required double finalPayment,
      required String paymentStatus,
      required String bankAccountId,
      required String bankAccountName,
      required String accountHolder,
      required List<String> teamMembers,
      required String clientPaymentSource,
      Value<int> rowid,
    });
typedef $$ProjectsTableTableUpdateCompanionBuilder =
    ProjectsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<String> clientId,
      Value<String> clientName,
      Value<String> startDate,
      Value<String> endDate,
      Value<String> status,
      Value<double> budget,
      Value<double> advancedPayment,
      Value<double> partialPayments,
      Value<double> finalPayment,
      Value<String> paymentStatus,
      Value<String> bankAccountId,
      Value<String> bankAccountName,
      Value<String> accountHolder,
      Value<List<String>> teamMembers,
      Value<String> clientPaymentSource,
      Value<int> rowid,
    });

class $$ProjectsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTableTable> {
  $$ProjectsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get advancedPayment => $composableBuilder(
    column: $table.advancedPayment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get partialPayments => $composableBuilder(
    column: $table.partialPayments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get finalPayment => $composableBuilder(
    column: $table.finalPayment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccountId => $composableBuilder(
    column: $table.bankAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountHolder => $composableBuilder(
    column: $table.accountHolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get teamMembers => $composableBuilder(
    column: $table.teamMembers,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get clientPaymentSource => $composableBuilder(
    column: $table.clientPaymentSource,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTableTable> {
  $$ProjectsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get advancedPayment => $composableBuilder(
    column: $table.advancedPayment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get partialPayments => $composableBuilder(
    column: $table.partialPayments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get finalPayment => $composableBuilder(
    column: $table.finalPayment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccountId => $composableBuilder(
    column: $table.bankAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountHolder => $composableBuilder(
    column: $table.accountHolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamMembers => $composableBuilder(
    column: $table.teamMembers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientPaymentSource => $composableBuilder(
    column: $table.clientPaymentSource,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTableTable> {
  $$ProjectsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<double> get advancedPayment => $composableBuilder(
    column: $table.advancedPayment,
    builder: (column) => column,
  );

  GeneratedColumn<double> get partialPayments => $composableBuilder(
    column: $table.partialPayments,
    builder: (column) => column,
  );

  GeneratedColumn<double> get finalPayment => $composableBuilder(
    column: $table.finalPayment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankAccountId => $composableBuilder(
    column: $table.bankAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountHolder => $composableBuilder(
    column: $table.accountHolder,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get teamMembers =>
      $composableBuilder(
        column: $table.teamMembers,
        builder: (column) => column,
      );

  GeneratedColumn<String> get clientPaymentSource => $composableBuilder(
    column: $table.clientPaymentSource,
    builder: (column) => column,
  );
}

class $$ProjectsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTableTable,
          ProjectsTableData,
          $$ProjectsTableTableFilterComposer,
          $$ProjectsTableTableOrderingComposer,
          $$ProjectsTableTableAnnotationComposer,
          $$ProjectsTableTableCreateCompanionBuilder,
          $$ProjectsTableTableUpdateCompanionBuilder,
          (
            ProjectsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProjectsTableTable,
              ProjectsTableData
            >,
          ),
          ProjectsTableData,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableTableManager(_$AppDatabase db, $ProjectsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> clientName = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> budget = const Value.absent(),
                Value<double> advancedPayment = const Value.absent(),
                Value<double> partialPayments = const Value.absent(),
                Value<double> finalPayment = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> bankAccountId = const Value.absent(),
                Value<String> bankAccountName = const Value.absent(),
                Value<String> accountHolder = const Value.absent(),
                Value<List<String>> teamMembers = const Value.absent(),
                Value<String> clientPaymentSource = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsTableCompanion(
                id: id,
                name: name,
                description: description,
                clientId: clientId,
                clientName: clientName,
                startDate: startDate,
                endDate: endDate,
                status: status,
                budget: budget,
                advancedPayment: advancedPayment,
                partialPayments: partialPayments,
                finalPayment: finalPayment,
                paymentStatus: paymentStatus,
                bankAccountId: bankAccountId,
                bankAccountName: bankAccountName,
                accountHolder: accountHolder,
                teamMembers: teamMembers,
                clientPaymentSource: clientPaymentSource,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                required String clientId,
                required String clientName,
                required String startDate,
                required String endDate,
                required String status,
                required double budget,
                required double advancedPayment,
                required double partialPayments,
                required double finalPayment,
                required String paymentStatus,
                required String bankAccountId,
                required String bankAccountName,
                required String accountHolder,
                required List<String> teamMembers,
                required String clientPaymentSource,
                Value<int> rowid = const Value.absent(),
              }) => ProjectsTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                clientId: clientId,
                clientName: clientName,
                startDate: startDate,
                endDate: endDate,
                status: status,
                budget: budget,
                advancedPayment: advancedPayment,
                partialPayments: partialPayments,
                finalPayment: finalPayment,
                paymentStatus: paymentStatus,
                bankAccountId: bankAccountId,
                bankAccountName: bankAccountName,
                accountHolder: accountHolder,
                teamMembers: teamMembers,
                clientPaymentSource: clientPaymentSource,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTableTable, ProjectsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProjectsTableTable,
                    ProjectsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTableTable,
      ProjectsTableData,
      $$ProjectsTableTableFilterComposer,
      $$ProjectsTableTableOrderingComposer,
      $$ProjectsTableTableAnnotationComposer,
      $$ProjectsTableTableCreateCompanionBuilder,
      $$ProjectsTableTableUpdateCompanionBuilder,
      (
        ProjectsTableData,
        BaseReferences<_$AppDatabase, $ProjectsTableTable, ProjectsTableData>,
      ),
      ProjectsTableData,
      PrefetchHooks Function()
    >;
typedef $$ProjectTasksTableTableCreateCompanionBuilder =
    ProjectTasksTableCompanion Function({
      required String id,
      required String projectId,
      required String projectName,
      required String title,
      required String description,
      required String assigneeId,
      required String assigneeName,
      required String dueDate,
      required String priority,
      required String status,
      Value<int> rowid,
    });
typedef $$ProjectTasksTableTableUpdateCompanionBuilder =
    ProjectTasksTableCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> projectName,
      Value<String> title,
      Value<String> description,
      Value<String> assigneeId,
      Value<String> assigneeName,
      Value<String> dueDate,
      Value<String> priority,
      Value<String> status,
      Value<int> rowid,
    });

class $$ProjectTasksTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectTasksTableTable> {
  $$ProjectTasksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectTasksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectTasksTableTable> {
  $$ProjectTasksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectTasksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectTasksTableTable> {
  $$ProjectTasksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ProjectTasksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectTasksTableTable,
          ProjectTasksTableData,
          $$ProjectTasksTableTableFilterComposer,
          $$ProjectTasksTableTableOrderingComposer,
          $$ProjectTasksTableTableAnnotationComposer,
          $$ProjectTasksTableTableCreateCompanionBuilder,
          $$ProjectTasksTableTableUpdateCompanionBuilder,
          (
            ProjectTasksTableData,
            BaseReferences<
              _$AppDatabase,
              $ProjectTasksTableTable,
              ProjectTasksTableData
            >,
          ),
          ProjectTasksTableData,
          PrefetchHooks Function()
        > {
  $$ProjectTasksTableTableTableManager(
    _$AppDatabase db,
    $ProjectTasksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectTasksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectTasksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectTasksTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> projectName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> assigneeId = const Value.absent(),
                Value<String> assigneeName = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectTasksTableCompanion(
                id: id,
                projectId: projectId,
                projectName: projectName,
                title: title,
                description: description,
                assigneeId: assigneeId,
                assigneeName: assigneeName,
                dueDate: dueDate,
                priority: priority,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String projectName,
                required String title,
                required String description,
                required String assigneeId,
                required String assigneeName,
                required String dueDate,
                required String priority,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => ProjectTasksTableCompanion.insert(
                id: id,
                projectId: projectId,
                projectName: projectName,
                title: title,
                description: description,
                assigneeId: assigneeId,
                assigneeName: assigneeName,
                dueDate: dueDate,
                priority: priority,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectTasksTableTable, ProjectTasksTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ProjectTasksTableTable,
                    ProjectTasksTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectTasksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectTasksTableTable,
      ProjectTasksTableData,
      $$ProjectTasksTableTableFilterComposer,
      $$ProjectTasksTableTableOrderingComposer,
      $$ProjectTasksTableTableAnnotationComposer,
      $$ProjectTasksTableTableCreateCompanionBuilder,
      $$ProjectTasksTableTableUpdateCompanionBuilder,
      (
        ProjectTasksTableData,
        BaseReferences<
          _$AppDatabase,
          $ProjectTasksTableTable,
          ProjectTasksTableData
        >,
      ),
      ProjectTasksTableData,
      PrefetchHooks Function()
    >;
typedef $$TimesheetEntriesTableTableCreateCompanionBuilder =
    TimesheetEntriesTableCompanion Function({
      required String id,
      required String employeeId,
      required String employeeName,
      required String projectId,
      required String projectName,
      required String taskTitle,
      required String date,
      required double hours,
      required String description,
      required String status,
      Value<int> rowid,
    });
typedef $$TimesheetEntriesTableTableUpdateCompanionBuilder =
    TimesheetEntriesTableCompanion Function({
      Value<String> id,
      Value<String> employeeId,
      Value<String> employeeName,
      Value<String> projectId,
      Value<String> projectName,
      Value<String> taskTitle,
      Value<String> date,
      Value<double> hours,
      Value<String> description,
      Value<String> status,
      Value<int> rowid,
    });

class $$TimesheetEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $TimesheetEntriesTableTable> {
  $$TimesheetEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskTitle => $composableBuilder(
    column: $table.taskTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimesheetEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TimesheetEntriesTableTable> {
  $$TimesheetEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskTitle => $composableBuilder(
    column: $table.taskTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimesheetEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimesheetEntriesTableTable> {
  $$TimesheetEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employeeName => $composableBuilder(
    column: $table.employeeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskTitle =>
      $composableBuilder(column: $table.taskTitle, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$TimesheetEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimesheetEntriesTableTable,
          TimesheetEntriesTableData,
          $$TimesheetEntriesTableTableFilterComposer,
          $$TimesheetEntriesTableTableOrderingComposer,
          $$TimesheetEntriesTableTableAnnotationComposer,
          $$TimesheetEntriesTableTableCreateCompanionBuilder,
          $$TimesheetEntriesTableTableUpdateCompanionBuilder,
          (
            TimesheetEntriesTableData,
            BaseReferences<
              _$AppDatabase,
              $TimesheetEntriesTableTable,
              TimesheetEntriesTableData
            >,
          ),
          TimesheetEntriesTableData,
          PrefetchHooks Function()
        > {
  $$TimesheetEntriesTableTableTableManager(
    _$AppDatabase db,
    $TimesheetEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimesheetEntriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TimesheetEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TimesheetEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> employeeName = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> projectName = const Value.absent(),
                Value<String> taskTitle = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> hours = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimesheetEntriesTableCompanion(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                projectId: projectId,
                projectName: projectName,
                taskTitle: taskTitle,
                date: date,
                hours: hours,
                description: description,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String employeeId,
                required String employeeName,
                required String projectId,
                required String projectName,
                required String taskTitle,
                required String date,
                required double hours,
                required String description,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => TimesheetEntriesTableCompanion.insert(
                id: id,
                employeeId: employeeId,
                employeeName: employeeName,
                projectId: projectId,
                projectName: projectName,
                taskTitle: taskTitle,
                date: date,
                hours: hours,
                description: description,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TimesheetEntriesTableTable,
                    TimesheetEntriesTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TimesheetEntriesTableTable,
                    TimesheetEntriesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimesheetEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimesheetEntriesTableTable,
      TimesheetEntriesTableData,
      $$TimesheetEntriesTableTableFilterComposer,
      $$TimesheetEntriesTableTableOrderingComposer,
      $$TimesheetEntriesTableTableAnnotationComposer,
      $$TimesheetEntriesTableTableCreateCompanionBuilder,
      $$TimesheetEntriesTableTableUpdateCompanionBuilder,
      (
        TimesheetEntriesTableData,
        BaseReferences<
          _$AppDatabase,
          $TimesheetEntriesTableTable,
          TimesheetEntriesTableData
        >,
      ),
      TimesheetEntriesTableData,
      PrefetchHooks Function()
    >;
typedef $$PurchaseOrdersTableTableCreateCompanionBuilder =
    PurchaseOrdersTableCompanion Function({
      required String id,
      required String vendorId,
      required String vendorName,
      required String date,
      required String deliveryDate,
      required List<Map<String, dynamic>> items,
      required double subtotal,
      required double tax,
      required double total,
      required String status,
      Value<int> rowid,
    });
typedef $$PurchaseOrdersTableTableUpdateCompanionBuilder =
    PurchaseOrdersTableCompanion Function({
      Value<String> id,
      Value<String> vendorId,
      Value<String> vendorName,
      Value<String> date,
      Value<String> deliveryDate,
      Value<List<Map<String, dynamic>>> items,
      Value<double> subtotal,
      Value<double> tax,
      Value<double> total,
      Value<String> status,
      Value<int> rowid,
    });

class $$PurchaseOrdersTableTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTableTable> {
  $$PurchaseOrdersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
    String
  >
  get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseOrdersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTableTable> {
  $$PurchaseOrdersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseOrdersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTableTable> {
  $$PurchaseOrdersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<Map<String, dynamic>>, String>
  get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$PurchaseOrdersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseOrdersTableTable,
          PurchaseOrdersTableData,
          $$PurchaseOrdersTableTableFilterComposer,
          $$PurchaseOrdersTableTableOrderingComposer,
          $$PurchaseOrdersTableTableAnnotationComposer,
          $$PurchaseOrdersTableTableCreateCompanionBuilder,
          $$PurchaseOrdersTableTableUpdateCompanionBuilder,
          (
            PurchaseOrdersTableData,
            BaseReferences<
              _$AppDatabase,
              $PurchaseOrdersTableTable,
              PurchaseOrdersTableData
            >,
          ),
          PurchaseOrdersTableData,
          PrefetchHooks Function()
        > {
  $$PurchaseOrdersTableTableTableManager(
    _$AppDatabase db,
    $PurchaseOrdersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseOrdersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseOrdersTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchaseOrdersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vendorId = const Value.absent(),
                Value<String> vendorName = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> deliveryDate = const Value.absent(),
                Value<List<Map<String, dynamic>>> items = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> tax = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersTableCompanion(
                id: id,
                vendorId: vendorId,
                vendorName: vendorName,
                date: date,
                deliveryDate: deliveryDate,
                items: items,
                subtotal: subtotal,
                tax: tax,
                total: total,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vendorId,
                required String vendorName,
                required String date,
                required String deliveryDate,
                required List<Map<String, dynamic>> items,
                required double subtotal,
                required double tax,
                required double total,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersTableCompanion.insert(
                id: id,
                vendorId: vendorId,
                vendorName: vendorName,
                date: date,
                deliveryDate: deliveryDate,
                items: items,
                subtotal: subtotal,
                tax: tax,
                total: total,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PurchaseOrdersTableTable,
                    PurchaseOrdersTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PurchaseOrdersTableTable,
                    PurchaseOrdersTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseOrdersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseOrdersTableTable,
      PurchaseOrdersTableData,
      $$PurchaseOrdersTableTableFilterComposer,
      $$PurchaseOrdersTableTableOrderingComposer,
      $$PurchaseOrdersTableTableAnnotationComposer,
      $$PurchaseOrdersTableTableCreateCompanionBuilder,
      $$PurchaseOrdersTableTableUpdateCompanionBuilder,
      (
        PurchaseOrdersTableData,
        BaseReferences<
          _$AppDatabase,
          $PurchaseOrdersTableTable,
          PurchaseOrdersTableData
        >,
      ),
      PurchaseOrdersTableData,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      required String name,
      required String description,
      required String category,
      required double price,
      required String status,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<String> category,
      Value<double> price,
      Value<String> status,
      Value<int> rowid,
    });

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (
            ProductsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductsTableTable,
              ProductsTableData
            >,
          ),
          ProductsTableData,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                name: name,
                description: description,
                category: category,
                price: price,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                required String category,
                required double price,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                category: category,
                price: price,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTableTable, ProductsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProductsTableTable,
                    ProductsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (
        ProductsTableData,
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData>,
      ),
      ProductsTableData,
      PrefetchHooks Function()
    >;
typedef $$SalesInvoicesTableTableCreateCompanionBuilder =
    SalesInvoicesTableCompanion Function({
      required String id,
      required String clientId,
      required String clientName,
      required String date,
      required String dueDate,
      required List<Map<String, dynamic>> items,
      required double subtotal,
      required double tax,
      required double total,
      required String status,
      Value<int> rowid,
    });
typedef $$SalesInvoicesTableTableUpdateCompanionBuilder =
    SalesInvoicesTableCompanion Function({
      Value<String> id,
      Value<String> clientId,
      Value<String> clientName,
      Value<String> date,
      Value<String> dueDate,
      Value<List<Map<String, dynamic>>> items,
      Value<double> subtotal,
      Value<double> tax,
      Value<double> total,
      Value<String> status,
      Value<int> rowid,
    });

class $$SalesInvoicesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTableTable> {
  $$SalesInvoicesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
    String
  >
  get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SalesInvoicesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTableTable> {
  $$SalesInvoicesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalesInvoicesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTableTable> {
  $$SalesInvoicesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Map<String, dynamic>>, String>
  get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SalesInvoicesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesInvoicesTableTable,
          SalesInvoicesTableData,
          $$SalesInvoicesTableTableFilterComposer,
          $$SalesInvoicesTableTableOrderingComposer,
          $$SalesInvoicesTableTableAnnotationComposer,
          $$SalesInvoicesTableTableCreateCompanionBuilder,
          $$SalesInvoicesTableTableUpdateCompanionBuilder,
          (
            SalesInvoicesTableData,
            BaseReferences<
              _$AppDatabase,
              $SalesInvoicesTableTable,
              SalesInvoicesTableData
            >,
          ),
          SalesInvoicesTableData,
          PrefetchHooks Function()
        > {
  $$SalesInvoicesTableTableTableManager(
    _$AppDatabase db,
    $SalesInvoicesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesInvoicesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesInvoicesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesInvoicesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> clientName = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<List<Map<String, dynamic>>> items = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> tax = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesInvoicesTableCompanion(
                id: id,
                clientId: clientId,
                clientName: clientName,
                date: date,
                dueDate: dueDate,
                items: items,
                subtotal: subtotal,
                tax: tax,
                total: total,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientId,
                required String clientName,
                required String date,
                required String dueDate,
                required List<Map<String, dynamic>> items,
                required double subtotal,
                required double tax,
                required double total,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => SalesInvoicesTableCompanion.insert(
                id: id,
                clientId: clientId,
                clientName: clientName,
                date: date,
                dueDate: dueDate,
                items: items,
                subtotal: subtotal,
                tax: tax,
                total: total,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SalesInvoicesTableTable, SalesInvoicesTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SalesInvoicesTableTable,
                    SalesInvoicesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SalesInvoicesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesInvoicesTableTable,
      SalesInvoicesTableData,
      $$SalesInvoicesTableTableFilterComposer,
      $$SalesInvoicesTableTableOrderingComposer,
      $$SalesInvoicesTableTableAnnotationComposer,
      $$SalesInvoicesTableTableCreateCompanionBuilder,
      $$SalesInvoicesTableTableUpdateCompanionBuilder,
      (
        SalesInvoicesTableData,
        BaseReferences<
          _$AppDatabase,
          $SalesInvoicesTableTable,
          SalesInvoicesTableData
        >,
      ),
      SalesInvoicesTableData,
      PrefetchHooks Function()
    >;
typedef $$RecycleBinTableTableCreateCompanionBuilder =
    RecycleBinTableCompanion Function({
      required String id,
      required String itemType,
      required String title,
      required String subtitle,
      required String deletedAt,
      required String deletedBy,
      required Map<String, dynamic> jsonData,
      Value<int> rowid,
    });
typedef $$RecycleBinTableTableUpdateCompanionBuilder =
    RecycleBinTableCompanion Function({
      Value<String> id,
      Value<String> itemType,
      Value<String> title,
      Value<String> subtitle,
      Value<String> deletedAt,
      Value<String> deletedBy,
      Value<Map<String, dynamic>> jsonData,
      Value<int> rowid,
    });

class $$RecycleBinTableTableFilterComposer
    extends Composer<_$AppDatabase, $RecycleBinTableTable> {
  $$RecycleBinTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$RecycleBinTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RecycleBinTableTable> {
  $$RecycleBinTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecycleBinTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecycleBinTableTable> {
  $$RecycleBinTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedBy =>
      $composableBuilder(column: $table.deletedBy, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);
}

class $$RecycleBinTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecycleBinTableTable,
          RecycleBinTableData,
          $$RecycleBinTableTableFilterComposer,
          $$RecycleBinTableTableOrderingComposer,
          $$RecycleBinTableTableAnnotationComposer,
          $$RecycleBinTableTableCreateCompanionBuilder,
          $$RecycleBinTableTableUpdateCompanionBuilder,
          (
            RecycleBinTableData,
            BaseReferences<
              _$AppDatabase,
              $RecycleBinTableTable,
              RecycleBinTableData
            >,
          ),
          RecycleBinTableData,
          PrefetchHooks Function()
        > {
  $$RecycleBinTableTableTableManager(
    _$AppDatabase db,
    $RecycleBinTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecycleBinTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecycleBinTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecycleBinTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<String> deletedAt = const Value.absent(),
                Value<String> deletedBy = const Value.absent(),
                Value<Map<String, dynamic>> jsonData = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecycleBinTableCompanion(
                id: id,
                itemType: itemType,
                title: title,
                subtitle: subtitle,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                jsonData: jsonData,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemType,
                required String title,
                required String subtitle,
                required String deletedAt,
                required String deletedBy,
                required Map<String, dynamic> jsonData,
                Value<int> rowid = const Value.absent(),
              }) => RecycleBinTableCompanion.insert(
                id: id,
                itemType: itemType,
                title: title,
                subtitle: subtitle,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                jsonData: jsonData,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecycleBinTableTable, RecycleBinTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $RecycleBinTableTable,
                    RecycleBinTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecycleBinTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecycleBinTableTable,
      RecycleBinTableData,
      $$RecycleBinTableTableFilterComposer,
      $$RecycleBinTableTableOrderingComposer,
      $$RecycleBinTableTableAnnotationComposer,
      $$RecycleBinTableTableCreateCompanionBuilder,
      $$RecycleBinTableTableUpdateCompanionBuilder,
      (
        RecycleBinTableData,
        BaseReferences<
          _$AppDatabase,
          $RecycleBinTableTable,
          RecycleBinTableData
        >,
      ),
      RecycleBinTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$ActivitiesTableTableTableManager get activitiesTable =>
      $$ActivitiesTableTableTableManager(_db, _db.activitiesTable);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db, _db.tasksTable);
  $$StockAlertsTableTableTableManager get stockAlertsTable =>
      $$StockAlertsTableTableTableManager(_db, _db.stockAlertsTable);
  $$ClientsTableTableTableManager get clientsTable =>
      $$ClientsTableTableTableManager(_db, _db.clientsTable);
  $$BankAccountsTableTableTableManager get bankAccountsTable =>
      $$BankAccountsTableTableTableManager(_db, _db.bankAccountsTable);
  $$ExpenseRecordsTableTableTableManager get expenseRecordsTable =>
      $$ExpenseRecordsTableTableTableManager(_db, _db.expenseRecordsTable);
  $$IncomeRecordsTableTableTableManager get incomeRecordsTable =>
      $$IncomeRecordsTableTableTableManager(_db, _db.incomeRecordsTable);
  $$LedgerEntriesTableTableTableManager get ledgerEntriesTable =>
      $$LedgerEntriesTableTableTableManager(_db, _db.ledgerEntriesTable);
  $$LoanRecordsTableTableTableManager get loanRecordsTable =>
      $$LoanRecordsTableTableTableManager(_db, _db.loanRecordsTable);
  $$AdvanceRecordsTableTableTableManager get advanceRecordsTable =>
      $$AdvanceRecordsTableTableTableManager(_db, _db.advanceRecordsTable);
  $$AttendanceRecordsTableTableTableManager get attendanceRecordsTable =>
      $$AttendanceRecordsTableTableTableManager(
        _db,
        _db.attendanceRecordsTable,
      );
  $$EmployeesTableTableTableManager get employeesTable =>
      $$EmployeesTableTableTableManager(_db, _db.employeesTable);
  $$SalaryRecordsTableTableTableManager get salaryRecordsTable =>
      $$SalaryRecordsTableTableTableManager(_db, _db.salaryRecordsTable);
  $$AssetsTableTableTableManager get assetsTable =>
      $$AssetsTableTableTableManager(_db, _db.assetsTable);
  $$InventoryItemsTableTableTableManager get inventoryItemsTable =>
      $$InventoryItemsTableTableTableManager(_db, _db.inventoryItemsTable);
  $$ProjectsTableTableTableManager get projectsTable =>
      $$ProjectsTableTableTableManager(_db, _db.projectsTable);
  $$ProjectTasksTableTableTableManager get projectTasksTable =>
      $$ProjectTasksTableTableTableManager(_db, _db.projectTasksTable);
  $$TimesheetEntriesTableTableTableManager get timesheetEntriesTable =>
      $$TimesheetEntriesTableTableTableManager(_db, _db.timesheetEntriesTable);
  $$PurchaseOrdersTableTableTableManager get purchaseOrdersTable =>
      $$PurchaseOrdersTableTableTableManager(_db, _db.purchaseOrdersTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$SalesInvoicesTableTableTableManager get salesInvoicesTable =>
      $$SalesInvoicesTableTableTableManager(_db, _db.salesInvoicesTable);
  $$RecycleBinTableTableTableManager get recycleBinTable =>
      $$RecycleBinTableTableTableManager(_db, _db.recycleBinTable);
}

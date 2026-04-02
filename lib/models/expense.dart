class Expense {
  int? id;
  String title;
  double amount;
  String category;
  DateTime? date;
  DateTime? dueDate;
  String? description;
  String paymentMethod;
  String? location;
  bool isPaid;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.date,
    this.dueDate,
    this.description,
    required this.paymentMethod,
    this.location,
    this.isPaid = false,
  });

  Expense.fromMap(Map<String, dynamic> map)
      : id = map["id"] as int?,
        title = map["title"] as String,
        amount = (map["amount"] as num).toDouble(),
        category = map["category"] as String,
        date = map["date"] != null
            ? DateTime.parse(map["date"] as String)
            : null,
        dueDate = map["dueDate"] != null
            ? DateTime.parse(map["dueDate"] as String)
            : null,
        description = map["description"] as String?,
        paymentMethod = map["paymentMethod"] as String,
        location = map["location"] as String?,
        isPaid = (map["isPaid"] as int? ?? 0) == 1;

  /// Creates a copy of this Expense with the given fields replaced.
  /// Used for edit/duplicate workflows to avoid mutating the original expense.
  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    DateTime? dueDate,
    String? description,
    String? paymentMethod,
    String? location,
    bool? isPaid,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      location: location ?? this.location,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'description': description,
      'paymentMethod': paymentMethod,
      'location': location,
      'isPaid': isPaid ? 1 : 0,
    };
  }
}

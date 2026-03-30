class Expense{
    int? id;
    String title;
    double amount;
    String category;
    DateTime? date;
    String? description;
    String paymentMethod;
    String? location;

    Expense({
            this.id, 
            required this.title, 
            required this.amount, 
            required this.category,
            this.date, 
            this.description, 
            required this.paymentMethod,
            this.location,
          });

    Expense.fromMap(Map<String, dynamic> map)
    : id = map["id"] as int?,
      title = map["title"] as String,
      amount = (map["amount"] as num).toDouble(),
      category = map["category"] as String,
      date = map["date"] != null
          ? DateTime.parse(map["date"] as String)
          : null,
      description = map["description"] as String?,
      paymentMethod = map["paymentMethod"] as String,
      location = map["location"] as String?;

    /// Creates a copy of this Expense with the given fields replaced.
    /// Used for edit/duplicate workflows to avoid mutating the original expense.
    Expense copyWith({
            int? id,
            String? title,
            double? amount,
            String? category,
            DateTime? date,
            String? description,
            String? paymentMethod,
            String? location,
        }) {
            return Expense(
                id: id ?? this.id,
                title: title ?? this.title,
                amount: amount ?? this.amount,
                category: category ?? this.category,
                date: date ?? this.date,
                description: description ?? this.description,
                paymentMethod: paymentMethod ?? this.paymentMethod,
                location: location ?? this.location,
            );
        }


    Map<String, dynamic> toMap() {
        return{
              'id' :  id,
              'title' : title,
              'amount' : amount,
              'category': category,
            'date' : date?.toIso8601String(),
              'description':  description,
              'paymentMethod' : paymentMethod,
              'location': location
        };
    }
}
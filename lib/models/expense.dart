class Expense{
    int? id;
    String title;
    double amount;
    String category;
    DateTime? date;
    String? description;
    String paymentMethod;

    Expense({
            this.id, 
            required this.title, 
            required this.amount, 
            required this.category,
            this.date, 
            this.description, 
            required this.paymentMethod
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
      paymentMethod = map["paymentMethod"] as String;


    Map<String, dynamic> toMap() {
        return{
            'id' :  this.id,
            'title' : this.title,
            'amount' : this.amount,
            'category': this.category,
            'date' : date?.toIso8601String(),
            'description':  this.description,
            'paymentMethod' : this.paymentMethod
        };
    }
}
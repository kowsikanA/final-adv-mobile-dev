class Expense{
    int? id;
    String title;
    double amount;
    DateTime? date;
    String? description;
    String paymentMethod;

    Expense({
            this.id, 
            required this.title, 
            required this.amount, 
            this.date, 
            this.description, 
            required this.paymentMethod
          });

    Expense.fromMap(Map<String, dynamic> map)
    : id = map["id"] as int?,
      title = map["title"] as String,
      amount = (map["amount"] as num).toDouble(),
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
            'date' : date?.toIso8601String(),
            'description':  this.description,
            'paymentMethod' : this.paymentMethod
        };
    }
}
class Expense{
    int? id;
    String? title;
    double? amount;
    DateTime? date;
    String? description;
    String? paymentMethod;

    Expense({this.id, required this.title, required this.amount, this.date, this.description, required this.paymentMethod});

    Expense.fromMap(Map<String, dynamic> map){
        this.id = map["id"];
        this.title = map["title"];
        this.amount = map["amount"];
        this.date = map["date"];
        this.description = map['description'];
        this.paymentMethod = map['paymentMethod'];

    }

    Map<String, dynamic> toMap() {
        return{
            'id' :  this.id,
            'title' : this.title,
            'amount' : this.amount,
            'date' : DateTime.now(),
            'description':  this.description,
            'paymentMethod' : this.paymentMethod
        };
    }
}
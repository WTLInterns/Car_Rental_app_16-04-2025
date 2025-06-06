class Discount {
  int? id;
  String? couponCode;
  int? priceDiscount;
  String? isEnabled;

  Discount({this.id, this.couponCode, this.priceDiscount, this.isEnabled});

  Discount.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    couponCode = json['couponCode'];
    priceDiscount = json['priceDiscount'];
    isEnabled = json['isEnabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['couponCode'] = this.couponCode;
    data['priceDiscount'] = this.priceDiscount;
    data['isEnabled'] = this.isEnabled;
    return data;
  }
}
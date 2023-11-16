class PriceRange {
  late double start;
  late double end;

  PriceRange({required this.start, required this.end}) {
    if (start < 0) {
      start = 0;
    }
    if (end < 0) {
      end = 0;
    }
    if (start > end) {
      var temp = start;
      start = end;
      end = temp;
    }
  }

  PriceRange.fromJson(Map<String, dynamic> map) {
    start = double.parse(
      map['start'].toString(),
    );
    end = double.parse(
      map['end'].toString(),
    );
    if (start < 0) {
      start = 0;
    }
    if (end < 0) {
      end = 0;
    }
    if (start > end) {
      var temp = start;
      start = end;
      end = temp;
    }
  }
}

class PriceData {
  late String type; // pending（待定） accurate（准确价格） range（价格范围）
  double? price;
  PriceRange? priceRange;

  PriceData({required this.type, this.price, this.priceRange}) {
    switch (type) {
      case "accurate":
        price ??= 0;
        priceRange = null;
        break;
      case "range":
        price = null;
        priceRange ??= PriceRange(start: 0, end: 0);
        break;
      default:
        if (type != "pending") {
          type = "pending";
        }
        price = null;
        priceRange = null;
        break;
    }
  }

  PriceData.fromJson(Map<String, dynamic> map) {
    type = map['type'];
    switch (type) {
      case "accurate":
        price = double.parse(
          map['price'].toString(),
        );
        break;
      case "range":
        priceRange = PriceRange.fromJson(map['priceRange']);
        break;
      default:
        if (type != "pending") {
          type = "pending";
        }
        break;
    }
  }
}

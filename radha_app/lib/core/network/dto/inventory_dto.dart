import 'package:json_annotation/json_annotation.dart';

part 'inventory_dto.g.dart';

@JsonSerializable(createFactory: false)
class StockAdjustmentDto {
  const StockAdjustmentDto({
    required this.productId,
    required this.quantity,
    required this.type,
  });

  final String productId;
  final int quantity;
  final String type; // 'in' | 'out'

  Map<String, dynamic> toJson() => _$StockAdjustmentDtoToJson(this);
}

@JsonSerializable(createToJson: false)
class InventoryItemResponse {
  const InventoryItemResponse({
    required this.id,
    required this.productId,
    required this.quantity,
    this.lowStockThreshold,
  });

  final String id;
  final String productId;
  final int quantity;
  final int? lowStockThreshold;

  factory InventoryItemResponse.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class PaginatedInventory {
  const PaginatedInventory({
    required this.items,
    required this.total,
    this.cursor,
  });

  final List<InventoryItemResponse> items;
  final int total;
  final String? cursor;

  factory PaginatedInventory.fromJson(Map<String, dynamic> json) =>
      _$PaginatedInventoryFromJson(json);
}

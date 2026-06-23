// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$StockAdjustmentDtoToJson(StockAdjustmentDto instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
      'type': instance.type,
    };

InventoryItemResponse _$InventoryItemResponseFromJson(
  Map<String, dynamic> json,
) => InventoryItemResponse(
  id: json['id'] as String,
  productId: json['productId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt(),
);

PaginatedInventory _$PaginatedInventoryFromJson(Map<String, dynamic> json) =>
    PaginatedInventory(
      items: (json['items'] as List<dynamic>)
          .map((e) => InventoryItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      cursor: json['cursor'] as String?,
    );

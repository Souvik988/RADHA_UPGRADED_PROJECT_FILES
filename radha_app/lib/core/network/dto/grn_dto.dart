import 'package:json_annotation/json_annotation.dart';

part 'grn_dto.g.dart';

@JsonSerializable(createFactory: false)
class CreateGrnDto {
  const CreateGrnDto({
    required this.supplierId,
    this.invoiceNumber,
    this.invoiceDate,
    this.expectedDeliveryDate,
    this.items,
  });

  final String supplierId;
  final String? invoiceNumber;
  final String? invoiceDate;
  final String? expectedDeliveryDate;
  final List<Map<String, dynamic>>? items;

  Map<String, dynamic> toJson() => _$CreateGrnDtoToJson(this);
}

@JsonSerializable(createToJson: false)
class GrnResponse {
  const GrnResponse({
    required this.id,
    required this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.invoiceDate,
    this.status,
    this.totalItems,
    this.totalQuantity,
    this.totalValue,
    this.createdAt,
  });

  final String id;
  final String supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  final String? invoiceDate;
  final String? status;
  final int? totalItems;
  final int? totalQuantity;
  final double? totalValue;
  final String? createdAt;

  factory GrnResponse.fromJson(Map<String, dynamic> json) =>
      _$GrnResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class PaginatedGrns {
  const PaginatedGrns({required this.items, required this.total, this.cursor});

  final List<GrnResponse> items;
  final int total;
  final String? cursor;

  factory PaginatedGrns.fromJson(Map<String, dynamic> json) =>
      _$PaginatedGrnsFromJson(json);
}

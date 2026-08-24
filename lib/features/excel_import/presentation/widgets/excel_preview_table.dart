import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/excel_column_name.dart';
import '../../domain/excel_row.dart';
import '../../domain/worksheet_info.dart';

class ExcelPreviewTable extends StatefulWidget {
  const ExcelPreviewTable({
    required this.worksheet,
    required this.rows,
    super.key,
  });

  final WorksheetInfo worksheet;
  final List<ExcelRow> rows;

  @override
  State<ExcelPreviewTable> createState() => _ExcelPreviewTableState();
}

class _ExcelPreviewTableState extends State<ExcelPreviewTable> {
  static const rowNumberWidth = 64.0;
  static const cellWidth = 160.0;
  static const rowHeight = 44.0;

  final horizontalController = ScrollController();
  final verticalController = ScrollController();

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columnCount = math.max(
      widget.worksheet.columnCount,
      widget.rows.fold<int>(
        0,
        (maximum, row) => math.max(maximum, row.cells.length),
      ),
    );
    final previewHeight = (widget.rows.length * rowHeight)
        .clamp(rowHeight, 360.0)
        .toDouble();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.worksheet.name,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.worksheet.rowCount} แถว'
              ' • ${widget.worksheet.columnCount} คอลัมน์'
              ' • แสดง ${widget.rows.length} แถวแรก',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = rowNumberWidth + (columnCount * cellWidth);
                final tableWidth = math.max(contentWidth, constraints.maxWidth);

                return Scrollbar(
                  controller: horizontalController,
                  thumbVisibility: contentWidth > constraints.maxWidth,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          _buildHeader(context, columnCount),
                          SizedBox(
                            height: previewHeight,
                            child: Scrollbar(
                              controller: verticalController,
                              thumbVisibility:
                                  widget.rows.length * rowHeight >
                                  previewHeight,
                              child: ListView.builder(
                                controller: verticalController,
                                itemCount: widget.rows.length,
                                itemExtent: rowHeight,
                                itemBuilder: (context, index) => _buildRow(
                                  context,
                                  widget.rows[index],
                                  columnCount,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int columnCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: rowHeight,
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _tableCell(context, text: '#', width: rowNumberWidth, isHeader: true),
          for (var index = 0; index < columnCount; index++)
            _tableCell(
              context,
              text: ExcelColumnName.fromIndex(index),
              width: cellWidth,
              isHeader: true,
            ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ExcelRow row, int columnCount) {
    final valuesByColumn = {
      for (final cell in row.cells) cell.columnIndex: cell.displayValue,
    };
    return Row(
      children: [
        _tableCell(
          context,
          text: '${row.index + 1}',
          width: rowNumberWidth,
          isHeader: true,
        ),
        for (var index = 0; index < columnCount; index++)
          _tableCell(
            context,
            text: valuesByColumn[index] ?? '',
            width: cellWidth,
          ),
      ],
    );
  }

  Widget _tableCell(
    BuildContext context, {
    required String text,
    required double width,
    bool isHeader = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: rowHeight,
      alignment: isHeader ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isHeader ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'firestore_sales_service.dart';

class SalesByHourChart extends StatefulWidget {
  const SalesByHourChart({
    super.key,
    this.service,
    this.nowProvider,
    this.fallbackHourlySales,
  });

  final FirestoreSalesService? service;
  final DateTime Function()? nowProvider;
  final List<double>? fallbackHourlySales;

  @override
  State<SalesByHourChart> createState() => _SalesByHourChartState();
}

class _SalesByHourChartState extends State<SalesByHourChart> {
  static const Duration _hapticDebounce = Duration(milliseconds: 120);

  late FirestoreSalesService _service;
  late Stream<SalesByHourSnapshot> _stream;

  int? _lastTrackballIndex;
  DateTime _lastHapticAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? FirestoreSalesService();
    _stream = _buildStream();
  }

  @override
  void didUpdateWidget(covariant SalesByHourChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.nowProvider != widget.nowProvider) {
      _service = widget.service ?? FirestoreSalesService();
      _stream = _buildStream();
      _lastTrackballIndex = null;
    }
  }

  Stream<SalesByHourSnapshot> _buildStream() {
    return _service.watchTodaySales(nowProvider: widget.nowProvider);
  }

  void _retry() {
    setState(() {
      _stream = _buildStream();
      _lastTrackballIndex = null;
    });
  }

  SalesByHourSnapshot _resolveChartData(SalesByHourSnapshot source) {
    if (source.hasFirestoreHours) {
      return source;
    }

    final fallback = widget.fallbackHourlySales;
    if (fallback == null || fallback.isEmpty) {
      return source;
    }

    final points = <SalesPoint>[];
    for (var index = 0; index < source.points.length; index++) {
      final basePoint = source.points[index];
      final fallbackValue = index < fallback.length ? fallback[index] : 0;
      points.add(
        SalesPoint(
          hourLabel: basePoint.hourLabel,
          hourKey: basePoint.hourKey,
          value: math.max(0, fallbackValue.round()),
        ),
      );
    }

    final hasFallbackData = points.any((point) => point.value > 0);
    if (!hasFallbackData) {
      return source;
    }

    return SalesByHourSnapshot(
      documentId: source.documentId,
      points: points,
      hasFirestoreHours: true,
    );
  }

  void _handleTrackballChanged(TrackballArgs args) {
    final index = args.chartPointInfo.dataPointIndex;
    if (index == null || index == _lastTrackballIndex || index < 0) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastHapticAt) >= _hapticDebounce) {
      HapticFeedback.selectionClick();
      _lastHapticAt = now;
    }
    _lastTrackballIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SalesByHourSnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ChartErrorState(onRetry: _retry);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _ChartLoadingState();
        }

        final data = snapshot.data;
        if (data == null) {
          return const _ChartLoadingState();
        }

        final resolvedData = _resolveChartData(data);

        final signature =
            '${resolvedData.documentId}-${resolvedData.hasFirestoreHours}-${resolvedData.points.map((point) => point.value).join(",")}';

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(fade),
                child: child,
              ),
            );
          },
          child: _ChartContent(
            key: ValueKey<String>(signature),
            data: resolvedData,
            onTrackballChanged: _handleTrackballChanged,
          ),
        );
      },
    );
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({
    required this.data,
    required this.onTrackballChanged,
    super.key,
  });

  final SalesByHourSnapshot data;
  final ValueChanged<TrackballArgs> onTrackballChanged;

  @override
  Widget build(BuildContext context) {
    final maxY = _computeAxisMax(data.points);
    final interval = maxY / 4;
    final hasPeak = data.peakValue > 0;

    final trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      lineType: TrackballLineType.vertical,
      tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
      lineColor: const Color(0xCC2F7D4D),
      lineDashArray: const <double>[6, 5],
      tooltipSettings: const InteractiveTooltip(enable: false),
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
        width: 10,
        height: 10,
        color: Colors.white,
        borderColor: Color(0xFF146D36),
        borderWidth: 2,
      ),
      builder: (context, details) {
        final index = details.pointIndex;
        if (index == null || index < 0 || index >= data.points.length) {
          return const SizedBox.shrink();
        }
        final current = data.points[index];
        final previous = index > 0 ? data.points[index - 1] : null;
        return _TrackballTooltip(current: current, previous: previous);
      },
    );

    return Stack(
      children: [
        SfCartesianChart(
          margin: EdgeInsets.zero,
          plotAreaBorderWidth: 0,
          onTrackballPositionChanging: onTrackballChanged,
          trackballBehavior: trackballBehavior,
          primaryXAxis: CategoryAxis(
            interval: 1,
            labelPlacement: LabelPlacement.onTicks,
            axisLine: AxisLine(width: 0),
            majorTickLines: MajorTickLines(width: 0, size: 0),
            majorGridLines: MajorGridLines(width: 0),
            axisLabelFormatter: (details) {
              final parsedHour = int.tryParse(details.text);
              final label = parsedHour == null
                  ? details.text
                  : '${parsedHour}h';
              return ChartAxisLabel(label, details.textStyle);
            },
            labelStyle: TextStyle(
              color: Color(0xFF97A0AE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: maxY,
            interval: interval,
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(width: 0, size: 0),
            minorTickLines: const MinorTickLines(width: 0, size: 0),
            majorGridLines: const MajorGridLines(
              width: 0.8,
              color: Color(0x22334155),
              dashArray: <double>[6, 6],
            ),
            minorGridLines: const MinorGridLines(width: 0),
            labelStyle: const TextStyle(
              color: Color(0xFF97A0AE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            axisLabelFormatter: (details) {
              return ChartAxisLabel(
                _formatCompact(details.value),
                details.textStyle,
              );
            },
            plotBands: [
              PlotBand(
                isVisible: true,
                start: data.averageValue,
                end: data.averageValue,
                shouldRenderAboveSeries: true,
                borderWidth: 1.2,
                borderColor: const Color(0x99487064),
                dashArray: const <double>[5, 4],
                text: 'Moyenne',
                horizontalTextAlignment: TextAnchor.end,
                verticalTextAlignment: TextAnchor.start,
                horizontalTextPadding: '8',
                verticalTextPadding: '4',
                textStyle: const TextStyle(
                  color: Color(0xFF6F7C8A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          series: <CartesianSeries<SalesPoint, String>>[
            ColumnSeries<SalesPoint, String>(
              dataSource: data.points,
              xValueMapper: (point, _) => point.hourKey,
              yValueMapper: (point, _) => point.value,
              width: 0.64,
              spacing: 0.22,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              color: const Color(0x80B8E4C5),
              enableTooltip: false,
              animationDuration: 750,
            ),
            SplineAreaSeries<SalesPoint, String>(
              dataSource: data.points,
              xValueMapper: (point, _) => point.hourKey,
              yValueMapper: (point, _) => point.value,
              splineType: SplineType.monotonic,
              borderColor: Colors.transparent,
              borderWidth: 0,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x4D2E8B52), Color(0x002E8B52)],
                stops: <double>[0, 1],
              ),
              enableTooltip: false,
              animationDuration: 900,
            ),
            SplineSeries<SalesPoint, String>(
              dataSource: data.points,
              xValueMapper: (point, _) => point.hourKey,
              yValueMapper: (point, _) => point.value,
              splineType: SplineType.monotonic,
              width: 3,
              color: const Color(0xFF146D36),
              markerSettings: const MarkerSettings(
                isVisible: true,
                width: 8.5,
                height: 8.5,
                color: Color(0xFF146D36),
                borderColor: Colors.white,
                borderWidth: 2,
              ),
              enableTooltip: false,
              animationDuration: 980,
            ),
            if (hasPeak)
              ScatterSeries<SalesPoint, String>(
                dataSource: <SalesPoint>[data.points[data.peakIndex]],
                xValueMapper: (point, _) => point.hourKey,
                yValueMapper: (point, _) => point.value,
                enableTooltip: false,
                enableTrackball: false,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  width: 12,
                  height: 12,
                  color: Color(0xFFFFA228),
                  borderColor: Colors.white,
                  borderWidth: 2.4,
                ),
                dataLabelMapper: (point, _) => 'PIC',
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.top,
                  labelPosition: ChartDataLabelPosition.outside,
                  color: Color(0xFFFFF2CF),
                  borderColor: Color(0xFFFFA228),
                  borderWidth: 1,
                  borderRadius: 12,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: TextStyle(
                    color: Color(0xFF93510B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                animationDuration: 1020,
              ),
          ],
        ),
        if (!data.hasFirestoreHours)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFDCE2E8)),
              ),
              child: const Text(
                'Aucune donnée',
                style: TextStyle(
                  color: Color(0xFF7B8695),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _computeAxisMax(List<SalesPoint> points) {
    var maxValue = 0;
    for (final point in points) {
      if (point.value > maxValue) {
        maxValue = point.value;
      }
    }
    if (maxValue <= 0) {
      return 10000;
    }
    final step = _niceStep(maxValue / 4);
    return step * 4;
  }

  double _niceStep(double raw) {
    final safeRaw = raw <= 0 ? 1 : raw;
    final magnitude = math
        .pow(10, (math.log(safeRaw) / math.ln10).floor())
        .toDouble();
    final fraction = safeRaw / magnitude;

    double niceFraction;
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }

    return niceFraction * magnitude;
  }
}

class _TrackballTooltip extends StatelessWidget {
  const _TrackballTooltip({required this.current, required this.previous});

  final SalesPoint current;
  final SalesPoint? previous;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current.hourLabel,
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatFcfa(current.value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _deltaLabel(current, previous),
            style: const TextStyle(
              color: Color(0xFFC9D3E0),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _deltaLabel(SalesPoint current, SalesPoint? previous) {
    if (previous == null || previous.value == 0) {
      return '—';
    }
    final delta = ((current.value - previous.value) / previous.value) * 100;
    return '${_formatPercent(delta)} vs ${previous.hourLabel}';
  }

  String _formatPercent(double value) {
    final decimals = value.abs() >= 10 ? 0 : 1;
    var formatted = value.toStringAsFixed(decimals);
    if (formatted.endsWith('.0')) {
      formatted = formatted.substring(0, formatted.length - 2);
    }
    if (formatted == '-0') {
      formatted = '0';
    }
    if (value > 0) {
      formatted = '+$formatted';
    }
    return '$formatted%';
  }
}

class _ChartLoadingState extends StatelessWidget {
  const _ChartLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8E4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Color(0xFFE6ECE8),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9BC8AB)),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(10, (index) {
                final height = 22 + ((index % 4) * 10.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEBE1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chargement des ventes horaires...',
            style: TextStyle(
              color: Color(0xFF8C97A6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartErrorState extends StatelessWidget {
  const _ChartErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Erreur de chargement du graphique',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFD0D7E2)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCompact(num value) {
  final absolute = value.abs();
  if (absolute >= 1000000) {
    final formatted = (value / 1000000).toStringAsFixed(
      absolute >= 10000000 ? 0 : 1,
    );
    return '${_trimTrailingZero(formatted)}M';
  }
  if (absolute >= 1000) {
    final formatted = (value / 1000).toStringAsFixed(absolute >= 10000 ? 0 : 1);
    return '${_trimTrailingZero(formatted)}k';
  }
  return value.toStringAsFixed(0);
}

String _trimTrailingZero(String value) {
  if (value.endsWith('.0')) {
    return value.substring(0, value.length - 2);
  }
  return value;
}

String _formatFcfa(int value) {
  final isNegative = value < 0;
  final digits = value.abs().toString();
  final groups = <String>[];
  for (var index = digits.length; index > 0; index -= 3) {
    final start = math.max(0, index - 3);
    groups.insert(0, digits.substring(start, index));
  }
  final joined = groups.join(' ');
  return '${isNegative ? '-' : ''}$joined FCFA';
}

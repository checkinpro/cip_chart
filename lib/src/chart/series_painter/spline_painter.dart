part of charts;

class _SplineChartPainter extends CustomPainter {
  _SplineChartPainter(
      {this.chart,
      this.seriesRenderer,
      this.isRepaint,
      this.animationController,
      this.seriesAnimation,
      this.chartElementAnimation,
      ValueNotifier<num> notifier,
      this.painterKey})
      : super(repaint: notifier);
  final SfCartesianChart chart;
  final bool isRepaint;
  final AnimationController animationController;
  final Animation<double> seriesAnimation;
  final Animation<double> chartElementAnimation;
  final SplineSeriesRenderer seriesRenderer;
  final _PainterKey painterKey;

  /// Painter method for spline series
  @override
  void paint(Canvas canvas, Size size) {
    Rect clipRect;
    double animationFactor;
    final SplineSeries<dynamic, dynamic> series = seriesRenderer._series;
    final ChartAxis xAxis = seriesRenderer._xAxis;
    final ChartAxis yAxis = seriesRenderer._yAxis;
    final List<dynamic> dataPoints = seriesRenderer._dataPoints;
    seriesRenderer?._drawControlPoints?.clear();

    /// Clip rect will be added for series.
    if (seriesRenderer._visible) {
      canvas.save();
      final int seriesIndex = painterKey.index;
      seriesRenderer.storeSeriesProperties(chart, seriesIndex);
      animationFactor = seriesAnimation != null ? seriesAnimation.value : 1;
      final Rect axisClipRect = _calculatePlotOffset(
          chart._chartAxis._axisClipRect,
          Offset(xAxis.plotOffset, yAxis.plotOffset));
      canvas.clipRect(axisClipRect);
      if ((!(chart._chartState.widgetNeedUpdate ||
                  chart._chartState._isLegendToggled) ||
              !chart._chartState._oldSeriesKeys.contains(series.key)) &&
          series.animationDuration > 0) {
        _performLinearAnimation(
            seriesRenderer._chart, xAxis, canvas, animationFactor);
      }
      _calculateSplineAreaControlPoints(seriesRenderer);

      int segmentIndex = -1;

      CartesianChartPoint<dynamic> point, _nextPoint, startPoint, endPoint;

      ///Draw spline for spline series
      for (int pointIndex = 0; pointIndex < dataPoints.length; pointIndex++) {
        point = dataPoints[pointIndex];
        seriesRenderer.calculateRegionData(
            chart, seriesRenderer, painterKey.index, point, pointIndex);
        if ((point.isVisible && !point.isGap) && startPoint == null) {
          startPoint = point;
        }
        if (pointIndex + 1 < dataPoints.length) {
          _nextPoint = dataPoints[pointIndex + 1];
          if (startPoint != null && _nextPoint.isVisible && _nextPoint.isGap) {
            startPoint = null;
          } else if (_nextPoint.isVisible && !_nextPoint.isGap) {
            endPoint = _nextPoint;
          }
        }
        if (startPoint != null && endPoint != null && startPoint != endPoint) {
          seriesRenderer.drawSegment(
              canvas,
              seriesRenderer.addSegment(startPoint, endPoint, segmentIndex += 1,
                  seriesIndex, animationFactor));
          endPoint = startPoint = null;
        }
      }
      clipRect = _calculatePlotOffset(
          Rect.fromLTRB(
              chart._chartAxis._axisClipRect.left - series.markerSettings.width,
              chart._chartAxis._axisClipRect.top - series.markerSettings.height,
              chart._chartAxis._axisClipRect.right +
                  series.markerSettings.width,
              chart._chartAxis._axisClipRect.bottom +
                  series.markerSettings.height),
          Offset(xAxis.plotOffset, yAxis.plotOffset));
      canvas.restore();

      if ((series.animationDuration <= 0 ||
              (!chart._chartState.initialRender &&
                  !seriesRenderer._needAnimateSeriesElements) ||
              animationFactor >= chart._seriesDurationFactor) &&
          (series.markerSettings.isVisible ||
              series.dataLabelSettings.isVisible)) {
        canvas.clipRect(clipRect);

        ///Draw marker and other elements for spline series
        seriesRenderer.renderSeriesElements(
            chart, canvas, chartElementAnimation);
      }
      if (animationFactor >= 1) {
        chart._chartState
            .setPainterKey(painterKey.index, painterKey.name, true);
      }
    }
  }

  @override
  bool shouldRepaint(_SplineChartPainter oldDelegate) => isRepaint;
}

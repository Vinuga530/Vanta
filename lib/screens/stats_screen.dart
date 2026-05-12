import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/usage_service.dart';
import '../widgets/ios_components.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<DailyStats> _weeklyStats = [];
  bool _loading = true;
  int _selectedDay = 6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await UsageService.getWeeklyUsage();
    if (mounted) setState(() { _weeklyStats = w; _loading = false; });
  }

  String _fmt(int m) => m < 60 ? '${m}m' : '${m ~/ 60}h ${m % 60}m';
  String _day(DateTime d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];

  Color _appColor(String p) {
    const c = [Color(0xFFFF453A),Color(0xFFFF9F0A),Color(0xFF30D158),Color(0xFF5E5CE6),Color(0xFFBF5AF2),Color(0xFF64D2FF)];
    return c[p.hashCode.abs() % c.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Statistics'),
            border: null,
            backgroundColor: isDark ? Colors.black.withOpacity(0.8) : const Color(0xFFF2F2F7).withOpacity(0.8),
          ),
          SliverList(delegate: SliverChildListDelegate([
            if (_loading) const Padding(padding: EdgeInsets.all(60), child: Center(child: CupertinoActivityIndicator()))
            else ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Weekly Screen Time', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Avg ${_fmt(_weeklyStats.isEmpty ? 0 : _weeklyStats.fold<int>(0, (s, e) => s + e.totalMinutes) ~/ _weeklyStats.length)} / day',
                      style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 20),
                    SizedBox(height: 180, child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (_weeklyStats.isEmpty ? 60 : _weeklyStats.map((s) => s.totalMinutes).reduce((a, b) => a > b ? a : b).toDouble()) * 1.2,
                      barTouchData: BarTouchData(
                        touchCallback: (e, r) { if (r?.spot != null && e is FlTapUpEvent) setState(() => _selectedDay = r!.spot!.touchedBarGroupIndex); },
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          getTooltipItem: (g, gi, r, ri) => BarTooltipItem(_fmt(r.toY.toInt()), TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= _weeklyStats.length) return const SizedBox.shrink();
                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_day(_weeklyStats[i].date),
                              style: TextStyle(fontSize: 12, fontWeight: i == _selectedDay ? FontWeight.w700 : FontWeight.w400,
                                color: i == _selectedDay ? CupertinoColors.activeBlue : CupertinoColors.systemGrey)));
                          },
                        )),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(_weeklyStats.length, (i) => BarChartGroupData(x: i, barRods: [
                        BarChartRodData(toY: _weeklyStats[i].totalMinutes.toDouble(),
                          color: i == _selectedDay ? CupertinoColors.activeBlue : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6)),
                          width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                      ])),
                    ))),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedDay < _weeklyStats.length)
                _buildBreakdown(_weeklyStats[_selectedDay]),
              const SizedBox(height: 40),
            ],
          ])),
        ],
      ),
    );
  }

  Widget _buildBreakdown(DailyStats stats) {
    final top = stats.appUsages.take(10).toList();
    return IOSGroup(
      header: '${_day(stats.date)} · ${_fmt(stats.totalMinutes)}',
      children: [
        if (top.isEmpty) const IOSListTile(title: Text('No data', style: TextStyle(color: CupertinoColors.systemGrey))),
        for (final a in top)
          IOSListTile(
            leading: Container(width: 30, height: 30, decoration: BoxDecoration(color: _appColor(a.packageName), borderRadius: BorderRadius.circular(7)),
              alignment: Alignment.center, child: Text(a.appName.isNotEmpty ? a.appName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
            title: Text(a.appName),
            subtitle: Text('Opened ${a.openCount} times'),
            trailing: Text(_fmt(a.usageMinutes), style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

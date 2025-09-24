import 'dart:async';
import 'package:flutter/material.dart';
import '../services/authority_data_service.dart';

// Enhanced Signal Monitoring Page implementing interactive authority dashboard.
class SignalMonitoringPage extends StatefulWidget {
  const SignalMonitoringPage({super.key});
  @override
  State<SignalMonitoringPage> createState() => _SignalMonitoringPageState();
}

class _SignalMonitoringPageState extends State<SignalMonitoringPage> {
  final service = AuthorityDataService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: service.addIntersection,
        icon: const Icon(Icons.add),
        label: const Text('Add Signal'),
      ),
      body: Column(
        children: [
          _GlobalControls(service: service),
          Expanded(
            child: StreamBuilder<List<IntersectionState>>(
              stream: service.intersectionsStream,
              builder: (context, snapshot) {
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('No signals.')); 
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) => _IntersectionCard(state: data[i], service: service),
                );
              },
            ),
          ),
          _LastActionPanel(service: service),
        ],
      ),
    );
  }
}

class _GlobalControls extends StatefulWidget {
  final AuthorityDataService service;
  const _GlobalControls({required this.service});
  @override
  State<_GlobalControls> createState() => _GlobalControlsState();
}

class _GlobalControlsState extends State<_GlobalControls> {
  late StreamSubscription sub;
  String? lastAction;

  @override
  void initState() {
    super.initState();
    sub = widget.service.lastActionStream.listen((e) => setState(() => lastAction = e));
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            _pillLabel(icon: Icons.memory, label: 'Mode', value: s.aiMode ? 'AI' : 'Manual'),
            _pillLabel(icon: Icons.emergency_share, label: 'Emergency', value: s.emergencyMode ? 'ON' : 'Off', color: s.emergencyMode ? Colors.red : Colors.grey),
            ElevatedButton.icon(
              icon: Icon(s.aiMode ? Icons.pause_circle : Icons.play_circle),
              label: Text(s.aiMode ? 'Switch Manual' : 'Enable AI'),
              onPressed: () => s.setAIMode(!s.aiMode),
            ),
            ElevatedButton.icon(
              icon: Icon(s.emergencyMode ? Icons.warning_amber : Icons.shield),
              style: ElevatedButton.styleFrom(backgroundColor: s.emergencyMode ? Colors.red : null),
              label: Text(s.emergencyMode ? 'Clear Emergency' : 'Emergency Mode'),
              onPressed: () async {
                if (!s.emergencyMode) {
                  final ok = await _confirm(context, 'Activate Emergency Mode', 'Force ALL signals to RED?');
                  if (!ok) return;
                }
                s.setEmergencyMode(!s.emergencyMode);
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              onPressed: () async {
                final ok = await _confirm(context, 'Reset System', 'Return everything to AI defaults?');
                if (ok) s.resetToDefaults();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillLabel({required IconData icon, required String label, required String value, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (color ?? Colors.blue).withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color ?? Colors.blue),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: color ?? Colors.blue, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 12, color: color ?? Colors.blue)),
      ]),
    );
  }
}

class _IntersectionCard extends StatefulWidget {
  final IntersectionState state;
  final AuthorityDataService service;
  const _IntersectionCard({required this.state, required this.service});
  @override
  State<_IntersectionCard> createState() => _IntersectionCardState();
}

class _IntersectionCardState extends State<_IntersectionCard> {
  bool expanded = false;

  Color _phaseColor(SignalPhase p) =>
      p == SignalPhase.green ? Colors.green : p == SignalPhase.yellow ? Colors.yellow.shade700 : Colors.red;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final phaseColor = _phaseColor(s.phase);
    final severityTag = _severityTag(s);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 14, backgroundColor: phaseColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.name}  (${s.id})', style: Theme.of(context).textTheme.titleMedium),
                  Text('Last updated ${_ago(s.lastUpdated)}', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: phaseColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text('${s.phase.name.toUpperCase()}  ${s.remainingSeconds}s',
                    style: TextStyle(color: phaseColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _smallInfo(Icons.speed, 'Flow Δ', s.flowRatePerTick.toString()),
              _smallInfo(Icons.directions_car, 'Vehicles', s.vehicleCount.toString()),
              _smallInfo(Icons.format_list_numbered, 'Queue', s.queueLength.toString()),
              _smallInfo(Icons.timer, 'Cycle', '${s.cycleSeconds}s'),
              _smallInfo(Icons.schedule, 'Predict', '${s.predictedNextPhase.name}'),
              _smallInfo(Icons.rule, 'Mode', widget.service.aiMode ? (s.manualOverride ? 'Manual (local)' : 'AI') : 'Manual'),
              if (severityTag != null) severityTag,
            ]),
            const SizedBox(height: 8),
            if (expanded) _HistorySparkline(s),
            Row(children: [
              TextButton.icon(
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(expanded ? 'Hide Analytics' : 'Analytics'),
                onPressed: () => setState(() => expanded = !expanded),
              ),
              const Spacer(),
              if (!widget.service.emergencyMode)
                PopupMenuButton<SignalPhase?>(
                  tooltip: 'Manual Override',
                  onSelected: (p) => _confirmOverride(context, p),
                  itemBuilder: (_) => [
                    const PopupMenuItem<SignalPhase?>(value: SignalPhase.green, child: Text('Force GREEN')),
                    const PopupMenuItem<SignalPhase?>(value: SignalPhase.yellow, child: Text('Force YELLOW')),
                    const PopupMenuItem<SignalPhase?>(value: SignalPhase.red, child: Text('Force RED')),
                    if (s.manualOverride)
                      const PopupMenuItem<SignalPhase?>(value: null, child: Text('Release Override')),
                  ],
                  child: Chip(
                    label: Text(s.manualOverride ? 'Override*' : 'Override'),
                    avatar: const Icon(Icons.tune, size: 16),
                  ),
                ),
            ]),
            if (s.lastAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Last: ${s.lastAction} (${_ago(s.lastActionAt)})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmOverride(BuildContext context, SignalPhase? phase) async {
    if (phase == null) {
      widget.service.releaseOverride(widget.state.id);
      return;
    }
    final ok = await _confirm(context, 'Confirm Override', 'Force ${phase.name.toUpperCase()} for ${widget.state.id}?');
    if (ok) widget.service.forcePhase(widget.state.id, phase);
  }

  Widget _smallInfo(IconData icon, String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16),
      const SizedBox(width: 4),
      Text('$label: $value', style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget? _severityTag(IntersectionState s) {
    if (s.jammed) {
      return _tag('JAM', Colors.red);
    }
    if (s.zeroFlow) {
      return _tag('ZERO', Colors.orange);
    }
    return null;
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _HistorySparkline extends StatelessWidget {
  final IntersectionState s;
  const _HistorySparkline(this.s);
  @override
  Widget build(BuildContext context) {
    final values = s.history;
    if (values.isEmpty) return const SizedBox.shrink();
    final maxV = values.reduce((a, b) => a > b ? a : b).toDouble().clamp(1, double.infinity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      height: 46,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: (values[i] / maxV) * 40,
                  decoration: BoxDecoration(
                    color: i == values.length - 1 ? Colors.blueAccent : Colors.blue.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LastActionPanel extends StatelessWidget {
  final AuthorityDataService service;
  const _LastActionPanel({required this.service});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: service.lastActionStream,
      builder: (context, snapshot) {
        final txt = snapshot.data ?? service.lastAction ?? 'No actions yet';
        return Container(
          width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text('Last Action: $txt', style: Theme.of(context).textTheme.bodySmall));
      },
    );
  }
}

String _ago(DateTime? dt) {
  if (dt == null) return '--';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  return '${diff.inHours}h ago';
}

Future<bool> _confirm(BuildContext context, String title, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
          ],
        ),
      ) ??
      false;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/kpi_drive_api.dart';
import 'logic/board_controller.dart';
import 'ui/app_theme.dart';
import 'ui/board_screen.dart';

void main() {
  runApp(const KpiKanbanApp());
}

class KpiKanbanApp extends StatelessWidget {
  const KpiKanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<KpiDriveApi>(create: (_) => KpiDriveApi()),
        ChangeNotifierProvider<BoardController>(
          create: (ctx) => BoardController(ctx.read<KpiDriveApi>()),
        ),
      ],
      child: MaterialApp(
        title: 'KPI-DRIVE Канбан',
        debugShowCheckedModeBanner: false,
        theme: buildKpiTheme(),
        home: const BoardScreen(),
      ),
    );
  }
}

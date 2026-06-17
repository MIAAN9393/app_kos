import 'package:flutter/material.dart';

/// Indeks bottom navigation — selaras hierarki visi.
class AppShellTabs {
  static const int dashboard = 0;
  static const int property = 1;
  static const int controll = 2;
  static const int keuangan = 3;
  static const int length = 4;
}

/// Inherited widget untuk ganti tab dari halaman anak.
class ShellScope extends InheritedWidget {
  final void Function(int index) pindahTab;

  const ShellScope({super.key, required this.pindahTab, required super.child});

  static ShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellScope>();
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

extension ShellScopeExt on BuildContext {
  void switchShellTab(int index) {
    ShellScope.maybeOf(this)?.pindahTab(index);
  }
}

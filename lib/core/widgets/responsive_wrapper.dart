import 'package:flutter/material.dart';
import 'package:vail_meds_v2/core/theme.dart';

class VailMedsScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showAppBar;
  final bool resizeToAvoidBottomInset;
  final ScrollPhysics physics;
  final bool safeArea;

  const VailMedsScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.showAppBar = true,
    this.resizeToAvoidBottomInset = true,
    this.physics = const ClampingScrollPhysics(),
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        physics: physics,
        child: body,
      ),
    );

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            )
          : null,
      body: content,
      floatingActionButton: floatingActionButton,
    );
  }
}

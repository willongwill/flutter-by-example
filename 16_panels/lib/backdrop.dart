// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Adapted from
// https://github.com/flutter/udacity-course/blob/master/unit_converter/unit_converter/lib/backdrop.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

const _kFlingVelocity = 2.0;

class _BackdropPanel extends StatelessWidget {
  const _BackdropPanel({
    Key key,
    this.onTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.title,
    this.child,
    this.titleHeight,
  }) : super(key: key);

  final VoidCallback onTap;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget title;
  final Widget child;
  final double titleHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12.0,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            onTap: onTap,
            child: Container(
              color: Theme.of(context).primaryColor,
              height: titleHeight,
              padding: EdgeInsetsDirectional.only(start: 16.0),
              alignment: AlignmentDirectional.centerStart,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.subhead,
                child: title,
              ),
            ),
          ),
          Divider(
            height: 1.0,
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Builds a Backdrop.
///
/// A Backdrop widget has two panels, front and back. The front panel is shown
/// by default, and slides down to show the back panel, from which a user
/// can make a selection. The user can also configure the titles for when the
/// front or back panel is showing.
class Backdrop extends StatefulWidget {
  final Widget frontPanel;
  final Widget backPanel;
  final Widget frontTitle;
  final Widget backTitle;
  final Widget frontHeader;
  final bool initialVisibility;
  final double backPanelHeight;
  final double frontPanelClosedHeight;
  final ValueNotifier<bool> toggleFrontPanel;

  const Backdrop(
      {@required this.frontPanel,
      @required this.backPanel,
      @required this.frontTitle,
      @required this.backTitle,
      this.initialVisibility = true,
      this.backPanelHeight = 0.0,
      this.frontPanelClosedHeight = 48.0,
      this.toggleFrontPanel,
      this.frontHeader})
      : assert(frontPanel != null),
        assert(backPanel != null),
        assert(frontTitle != null),
        assert(backTitle != null);

  @override
  createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin {
  final _backdropKey = GlobalKey(debugLabel: 'Backdrop');
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      // value of 0 hides the panel; value of 1 fully shows the panel
      value: widget.initialVisibility ? 1.0 : 0.0,
      vsync: this,
    );

    // Listen on the toggle value notifier if it's not null
    widget.toggleFrontPanel?.addListener(() {
      if (widget.toggleFrontPanel.value) {
        _toggleBackdropPanelVisibility();
        widget.toggleFrontPanel.value = false;
      }
    });
  }

  /*
  @override
  void didUpdateWidget(Backdrop old) {
    super.didUpdateWidget(old);
    if (false) {
      setState(() {
        _controller.fling(
            velocity:
                _backdropPanelVisible ? -_kFlingVelocity : _kFlingVelocity);
      });
    } else if (!_backdropPanelVisible) {
      setState(() {
        _controller.fling(velocity: _kFlingVelocity);
      });
    }
  }
  */

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _backdropPanelVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleBackdropPanelVisibility() {
    _controller.fling(
        velocity: _backdropPanelVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  double get _backdropHeight {
    final RenderBox renderBox = _backdropKey.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_controller.isAnimating)
      _controller.value -= details.primaryDelta / _backdropHeight;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;

    final double flingVelocity =
        details.velocity.pixelsPerSecond.dy / _backdropHeight;
    if (flingVelocity < 0.0)
      _controller.fling(velocity: math.max(_kFlingVelocity, -flingVelocity));
    else if (flingVelocity > 0.0)
      _controller.fling(velocity: math.min(-_kFlingVelocity, -flingVelocity));
    else
      _controller.fling(
          velocity:
              _controller.value < 0.5 ? -_kFlingVelocity : _kFlingVelocity);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        final panelTitleHeight = widget.frontPanelClosedHeight;
        final panelSize = constraints.biggest;
        final panelTop = panelSize.height - panelTitleHeight;

        // Animate the front panel sliding up and down
        Animation<RelativeRect> panelAnimation = RelativeRectTween(
          begin: RelativeRect.fromLTRB(
              0.0, panelTop, 0.0, panelTop - panelSize.height),
          end: RelativeRect.fromLTRB(0.0, widget.backPanelHeight, 0.0, 0.0),
        ).animate(_controller.view);

        return Container(
          key: _backdropKey,
          child: Stack(
            children: <Widget>[
              widget.backPanel,
              PositionedTransition(
                rect: panelAnimation,
                child: _BackdropPanel(
                  onTap: _toggleBackdropPanelVisibility,
                  onVerticalDragUpdate: _handleDragUpdate,
                  onVerticalDragEnd: _handleDragEnd,
                  title: widget.frontHeader,
                  titleHeight: panelTitleHeight,
                  child: widget.frontPanel,
                ),
              ),
            ],
          ),
        );
      });
}

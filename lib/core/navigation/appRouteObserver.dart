import 'package:flutter/widgets.dart';

/// App-wide route observer. Registered in [MaterialApp.navigatorObservers] so
/// pages can implement [RouteAware] and react when they're returned to
/// (e.g. the dashboard re-fetching saldo after a booking pops).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

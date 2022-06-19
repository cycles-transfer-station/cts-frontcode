import 'package:flutter/material.dart';




class _MainStateBindScope<T> extends InheritedWidget {
    final _MainStateBindState<T> state_bind;
    const _MainStateBindScope({
        Key? key, 
        required this.state_bind,
        required Widget child 
    }) : super(key: key, child: child);

    @override
    bool updateShouldNotify(_MainStateBindScope oldwidget) => true;
}


class MainStateBind<T> extends StatefulWidget {
    final T Function() getState;
    final void Function(T new_state, {required bool tifyListeners}) changeState;
    Widget child;
    MainStateBind({
        Key? key,
        required this.getState,
        required this.changeState,
        required this.child 
    }) : super(key: key);

    @override
    _MainStateBindState<T> createState() => _MainStateBindState<T>();


    static T get_state<T>(BuildContext context) {
        final _MainStateBindScope<T> scope = context.dependOnInheritedWidgetOfExactType<_MainStateBindScope<T>>()!;
        return scope.state_bind.getState();
    }
    static void set_state<T>(BuildContext context, T new_state, {required bool tifyListeners}) {
        final _MainStateBindScope<T> scope = context.dependOnInheritedWidgetOfExactType<_MainStateBindScope<T>>()!;
        return scope.state_bind.changeState(new_state, tifyListeners: tifyListeners);
    }
}


class _MainStateBindState<T> extends State<MainStateBind<T>> {
    T getState() => widget.getState();
    void changeState(T new_state, {required bool tifyListeners}) => widget.changeState(new_state, tifyListeners: tifyListeners);
    @override
    Widget build(BuildContext context) {
        return _MainStateBindScope<T>(
            state_bind: this,
            child: widget.child
        );
    }
}









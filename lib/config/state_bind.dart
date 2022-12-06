import 'package:flutter/material.dart';




class MainStateBindScope<T> extends InheritedWidget {
    final _MainStateBindState<T> state_bind;
    const MainStateBindScope({
        Key? key, 
        required this.state_bind,
        required Widget child 
    }) : super(key: key, child: child);

    @override
    bool updateShouldNotify(MainStateBindScope oldwidget) => true;
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
        final MainStateBindScope<T> scope = context.dependOnInheritedWidgetOfExactType<MainStateBindScope<T>>()!;
        return scope.state_bind.getState();
    }
    static void set_state<T>(BuildContext context, T new_state, {required bool tifyListeners}) {
        final MainStateBindScope<T> scope = context.dependOnInheritedWidgetOfExactType<MainStateBindScope<T>>()!;
        return scope.state_bind.changeState(new_state, tifyListeners: tifyListeners);
    }
    static MainStateBindScope<T> get_main_state_bind_scope<T>(BuildContext context) {
        return context.dependOnInheritedWidgetOfExactType<MainStateBindScope<T>>()!;
    }
    
}


class _MainStateBindState<T> extends State<MainStateBind<T>> {
    T getState() => widget.getState();
    void changeState(T new_state, {required bool tifyListeners}) => widget.changeState(new_state, tifyListeners: tifyListeners);
    @override
    Widget build(BuildContext context) {
        return MainStateBindScope<T>(
            state_bind: this,
            child: widget.child
        );
    }
}









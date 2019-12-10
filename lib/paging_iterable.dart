import 'dart:async';

import 'package:flutter/widgets.dart';

typedef PageGenerator<T> = FutureOr<List<T>> Function(int limit, int offset);

class PagingList<T> {
  final int bufferSize;
  int _page = 0;
  List<T> _pageList = [];
  Future<List<T>> _pageFuture;
  Iterator<T> _currIter;
  final PageGenerator<T> pageGenerator;

  PagingList({this.pageGenerator, this.bufferSize = 20});

  Future<List<T>> get currentPage {
    if (_pageFuture != null) return _pageFuture;
    return Future.value(_pageList);
  }

  Future<T> get current async {
    if (_pageFuture != null) {
      await _pageFuture;
    }
    return _currIter?.current;
  }

  FutureOr<bool> jumpToPage(int page) {
    _page = page;
    return moveNextPage();
  }

  FutureOr<bool> moveNextPage() {
    final nextPage = pageGenerator(bufferSize, (bufferSize * _page++));
    if (nextPage is Future<List<T>>) {
      _pageFuture = nextPage;
      return nextPage.then((_nextList) {
        _pageFuture = null;
        _pageList = _nextList;
        _currIter = _nextList.iterator;
        return _currIter.moveNext() == true;
      });
    } else {
      _pageFuture = null;
      _pageList = nextPage;
      _currIter = _pageList.iterator;
      return _currIter.moveNext() == true;
    }
  }

  FutureOr<bool> moveNext() {
    final _next = _currIter?.moveNext() == true;
    if (_next == true) return true;

    return moveNextPage();
  }
}

/// A stream that pages through results
class PagingStream<T> extends Stream<T> {
  final int bufferSize;
  final PageGenerator<T> pageGenerator;

  int _page = 0;
  Iterator<T> _currPage;
  bool _isPaused = true;
  StreamController<T> _controller;

  _resume() async {
    try {
      assert(_isPaused == true);
      assert(_controller.isClosed != true);
      _isPaused = false;

      while (await moveNext()) {
        _controller.add(_currPage.current);
        if (_isPaused == true) return;
        if (_controller.isClosed) {
          return;
        }
      }

      if (!_controller.isClosed) {
        _controller.close();
      }
    } catch (e, stack) {
      _controller.addError(e, stack);
      _controller.close();
    }
  }

  FutureOr<bool> moveNext() {
    final _next = _currPage?.moveNext() == true;
    if (_next == true) return true;

    final nextPage = pageGenerator(bufferSize, (bufferSize * _page++));
    if (nextPage is Future<List<T>>) {
      return nextPage.then((_next) {
        _currPage = _next.iterator;
        return _currPage.moveNext();
      });
    } else {
      _currPage = (nextPage as List).iterator;
      return _currPage?.moveNext() == true;
    }
  }

  PagingStream({@required this.pageGenerator, this.bufferSize = 20}) : assert(pageGenerator != null);

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    _controller ??= StreamController(
      onListen: () => _resume(),
      onCancel: () {
        if (!_controller.isClosed) _controller.close();
      },
      onPause: () => _isPaused = true,
      onResume: () => _resume(),
    );

    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: () => onDone?.call(),
      cancelOnError: cancelOnError,
    );
  }
}

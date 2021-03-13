import 'dart:async';

typedef PageGenerator<T> = FutureOr<List<T>> Function(int limit, int offset);

class PagingList<T> {
  FutureOr<int?> _length;

  final int bufferSize;
  int _page = 0;
  List<T>? _pageList;
  Future<List<T>>? _pageFuture;
  Iterator<T>? _currIter;
  final PageGenerator<T>? pageGenerator;

  PagingList(
      {this.pageGenerator,
      this.bufferSize = 20,
      required final FutureOr<int?> length})
      : _length = length {
    if (length is Future<int>) {
      length.then((_resolved) {
        _length = _resolved;
      });
    }
  }

  bool _isPageLoaded(int index) {
    final upper = _page * bufferSize;
    final lower = upper - bufferSize;
    final inPage = index >= lower && index <= upper;
    return inPage;
  }

  Future<T> get(int index) async {
    if (!_isPageLoaded(index)) {
      final pageNum = index ~/ bufferSize;
      final page = await jumpToPage(pageNum);
      return page.get(index % bufferSize)!;
    } else {
      return (await currentPage)!.get(index % bufferSize)!;
    }
  }

  FutureOr<int?> get length => _length;
  int? get lengthOrEmpty => _length is Future<int> ? 0 : _length as int?;

  Future<List<T>?> get currentPage {
    if (_pageFuture != null) return _pageFuture!;
    return Future.value(_pageList);
  }

  int get pageNumber => _page;

  Future<T?> get current async {
    if (_pageFuture != null) {
      await _pageFuture;
    }
    return _currIter?.current;
  }

  Future reload() async {
    return await jumpToPage(_page);
  }

  Future<List<T>> jumpToPage(int page) async {
    _page = page;
    final moved = await moveNextPage();
    if (moved == false) return [];
    return (await currentPage)!;
  }

  FutureOr<bool> moveNextPage() {
    final nextPage = pageGenerator!(bufferSize, (bufferSize * _page++));
    if (nextPage is Future<List<T>>) {
      _pageFuture = nextPage;
      return nextPage.then((_nextList) {
        _pageFuture = null;
        _pageList = _nextList;
        _currIter = _nextList.iterator;
        return _currIter!.moveNext() == true;
      });
    } else {
      _pageFuture = null;
      _pageList = nextPage;
      _currIter = _pageList!.iterator;
      return _currIter!.moveNext() == true;
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
  Iterator<T>? _currPage;
  bool _isPaused = true;
  StreamController<T>? _controller;

  Future<void> _resume() async {
    try {
      if (_isPaused == false) return;
      if (_controller!.isClosed) return;

      _isPaused = false;

      while (await moveNext()) {
        if (_controller!.isClosed) {
          return;
        }
        _controller!.add(_currPage!.current);
        if (_isPaused == true) return;
      }

      if (!_controller!.isClosed) {
        await _controller!.close();
      }
    } catch (e, stack) {
      _controller!.addError(e, stack);
      await _controller!.close();
    }
  }

  FutureOr<bool> moveNext() {
    final _next = _currPage?.moveNext() == true;
    if (_next == true) return true;

    final nextPage = pageGenerator(bufferSize, (bufferSize * _page++));
    if (nextPage is Future<List<T>>) {
      return nextPage.then((_next) {
        _currPage = _next.iterator;
        return _currPage!.moveNext();
      });
    } else {
      _currPage = nextPage.iterator;
      return _currPage?.moveNext() == true;
    }
  }

  PagingStream({required this.pageGenerator, this.bufferSize = 20});

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _controller ??= StreamController(
      onListen: () => _resume(),
      onCancel: () {
//        if (!_controller.isClosed) _controller.close();
      },
      onPause: () => _isPaused = true,
      onResume: () => _resume(),
    );

    return _controller!.stream.listen(
      onData,
      onError: onError,
      onDone: () => onDone?.call(),
      cancelOnError: cancelOnError,
    );
  }
}

extension SafeList<X> on List<X>? {
  X? get(int index) {
    if (this == null) return null;
    if (index > this!.length) return null;
    return this![index];
  }
}

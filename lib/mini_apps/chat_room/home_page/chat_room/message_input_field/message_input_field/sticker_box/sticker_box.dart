import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../../../reusable_components/sticker/get_sticker_series.dart';
import '../../../../../../../reusable_components/sticker/get_stickers_by_range.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NumberCubit extends Cubit<int> {
  NumberCubit(super.initialState);

  void change(int number) => emit(number);
}

class StickerBox extends StatefulWidget {
  final Function onTapSticker;

  const StickerBox({super.key, required this.onTapSticker});

  @override
  State<StickerBox> createState() => _StickerBoxState();
}

class _StickerBoxState extends State<StickerBox> {
  List<StickerSeriesPreview> previewList = [];
  List<StickerGrid> gridList = [];

  ScrollController scrollController = ScrollController();
  bool isLoading = false;
  bool hasMore = true;
  late String currentSeries;
  int index = 0;
  int range = 40;

  late Future<dynamic> init;

  _init() async {
    List<StickerSeries> stickerSeries = await getStickerSeries(context);
    for (int i = 0; i < stickerSeries.length; i++) {
      previewList.add(
        StickerSeriesPreview(
          index: i,
          stickerSeries: stickerSeries[i],
          changeCurrentSeries: changeSeries,
        ),
      );
    }

    currentSeries = stickerSeries.first.id;

    await _loadStickers();
  }

  changeSeries(String newSeriesId) async {
    scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease).then((value) async {
      gridList.clear();
      currentSeries = newSeriesId;
      hasMore = true;
      index = 0;
      await _loadStickers();
    });
  }

  _loadStickers() async {
    isLoading = true;
    hasMore = false;

    List<Sticker> stickers = await getStickersByRange(context, currentSeries, index * range, range);
    index++;
    for (var sticker in stickers) {
      gridList.add(
        StickerGrid(
          sticker: sticker,
          onTapSticker: widget.onTapSticker,
        ),
      );
    }

    if (stickers.length < range) {
      hasMore = false;
    }
    else
    {
      hasMore = true;
    }

    isLoading = false;
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    scrollController.addListener(() {
      if (scrollController.position.extentAfter < 100 && !isLoading && hasMore) {
        isLoading = true;
        _loadStickers();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          case ConnectionState.active:
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          case ConnectionState.waiting:
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
            return BlocProvider<NumberCubit>(
              create: (context) => NumberCubit(0),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      controller: scrollController,
                      crossAxisCount: 4,
                      childAspectRatio: (MediaQuery.of(context).size.width / 4) / ((MediaQuery.of(context).size.width / 4) + 24),
                      children: gridList,
                    ),
                  ),
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3), width: 0.5),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: previewList,
                      ),
                    ),
                  ),
                ],
              ),
            );
          default:
            return const Center(
              child: CupertinoActivityIndicator(),
            );
        }
      },
    );
  }
}

class StickerSeriesPreview extends StatefulWidget {
  final int index;
  final StickerSeries stickerSeries;
  final Function changeCurrentSeries;

  const StickerSeriesPreview({super.key, required this.index, required this.stickerSeries, required this.changeCurrentSeries});

  @override
  State<StickerSeriesPreview> createState() => _StickerSeriesPreviewState();
}

class _StickerSeriesPreviewState extends State<StickerSeriesPreview> {
  late bool isCurrentChosen;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NumberCubit, int>(
      listener: (context, number) {
        setState(() {
          isCurrentChosen = number == widget.index;
        });
      },
      builder: (context, state) {
        isCurrentChosen = state == widget.index;
        return Container(
          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if(!isCurrentChosen)
              {
                context.read<NumberCubit>().change(widget.index);
                widget.changeCurrentSeries(widget.stickerSeries.id);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(isCurrentChosen ? 0.5 : 0.0),
                child: CachedNetworkImage(
                  fadeInDuration: const Duration(milliseconds: 800),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  imageUrl: widget.stickerSeries.preview,
                  imageBuilder: (context, imageProvider) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: imageProvider,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StickerGrid extends StatefulWidget {
  final Sticker sticker;
  final Function onTapSticker;

  const StickerGrid({super.key, required this.sticker, required this.onTapSticker});

  @override
  State<StickerGrid> createState() => _StickerGridState();
}

class _StickerGridState extends State<StickerGrid> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              widget.onTapSticker(widget.sticker.text);
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: CachedNetworkImage(
                fadeInDuration: const Duration(milliseconds: 800),
                fadeOutDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => const CupertinoActivityIndicator(),
                imageUrl: widget.sticker.url,
                imageBuilder: (context, imageProvider) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: imageProvider,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error_outline),
              ),
            ),
          ),
          Text(
            widget.sticker.tittle,
            style: Theme.of(context).textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

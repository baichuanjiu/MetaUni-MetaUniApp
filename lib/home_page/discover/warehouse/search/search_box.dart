import 'package:flutter/material.dart';

class DiscoverWarehouseSearchBox extends StatelessWidget {
  const DiscoverWarehouseSearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: InkWell(
        borderRadius: const BorderRadius.all(
          Radius.circular(50.0),
        ),
        onTap: () {
          Navigator.pushNamed(context, '/discover/warehouse/search');
        },
        child: Hero(
          tag: 'discoverWarehouseSearchBox',
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.all(
                Radius.circular(50.0),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    child: Icon(
                      Icons.search_outlined,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  DefaultTextStyle(
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.outline),
                    child: const Text(
                      '搜索',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

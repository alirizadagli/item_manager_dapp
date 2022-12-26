import 'package:flutter/material.dart';
import 'package:item_manager/controllers/item_manager_service.dart';
import 'package:item_manager/models/item_model.dart';
import 'package:provider/provider.dart';

class UniqueItemListTile extends StatelessWidget {
  const UniqueItemListTile({
    Key? key,
    required this.item,
  }) : super(key: key);

  final UniqueItem item;
  Web3ItemManagerService getData(context) =>
      Provider.of<Web3ItemManagerService>(
        context,
        listen: false,
      );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.identifier),
      subtitle: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${item.itemPrice} wei"),
          Text("Status: ${item.state.name}"),
          Text("Item Address: ${item.itemAddress.toString().substring(0, 12)}..."),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            color: item.state == SupplyChainState.created
                ? Colors.amber
                : item.state == SupplyChainState.paid
                    ? const Color(0xFF73BBD1)
                    : const Color(0xFF69AE6B),
            onPressed: () {
              if (item.state == SupplyChainState.created) {
                getData(context).triggerPayment(
                  index: item.index,
                  price: item.itemPrice,
                );
              } else if (item.state == SupplyChainState.paid) {
                getData(context).triggerDelivery(item.index);
              } else {
                getData(context).fallback(item.itemAddress);
              }
            },
            icon: Icon(
              item.state == SupplyChainState.created
                  ? Icons.payments_rounded
                  : item.state == SupplyChainState.paid
                      ? Icons.send_and_archive_rounded
                      : Icons.done_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
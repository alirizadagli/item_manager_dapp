import 'package:web3dart/web3dart.dart';

enum SupplyChainState {
  created,
  paid,
  delivered,
}

class UniqueItem {
  final BigInt index;
  final EthereumAddress itemAddress;
  final String identifier;
  final BigInt itemPrice;
  final SupplyChainState state;

  UniqueItem({
    required this.index,
    required this.itemAddress,
    required this.identifier,
    required this.itemPrice,
    required this.state,
  });

  factory UniqueItem.fromList(BigInt index, List list) {
    return UniqueItem(
      index: index,
      itemAddress: list[0],
      identifier: list[1],
      itemPrice: list[2],
      state: SupplyChainState.values[list[3].toInt()],
    );
  }

  @override
  String toString() {
    return 'Index: $index, State: ${state.name}, id: $identifier, price: ${itemPrice.toString()}, item: ${itemAddress.hex}';
  }
}

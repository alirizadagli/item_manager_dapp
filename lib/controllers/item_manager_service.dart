import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:item_manager/models/item_model.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import '../utils/private.dart' as private;

class Web3ItemManagerService extends ChangeNotifier {
  List<UniqueItem> items = [];

  final String _rpcUrl = private.rpcUrl;
  final String _wsUrl = private.wsUrl;
  final _owner = private.owner;
  final _account1 = private.account1;
  final _account2 = private.account2;

  EthPrivateKey? currentAccount;

  void switchAccount() {
    if (currentAccount == _owner) {
      currentAccount = _account1;
    } else if (currentAccount == _account1) {
      currentAccount = _account2;
    } else {
      currentAccount = _owner;
    }
    notifyListeners();
  }

  late Web3Client _web3client;
  late ContractAbi _itemManagerAbiCode;
  late EthereumAddress _itemManagerContractAddress;
  late ContractEvent _supplyChainEvent;

  late DeployedContract _deployedParentContract;
  late ContractFunction _createItem;
  late ContractFunction _triggerPayment;
  late ContractFunction _triggerDelivery;
  late ContractFunction _items;
  late ContractFunction _itemIndex;

  Future<void> init() async {
    _web3client = Web3Client(
      _rpcUrl,
      http.Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(_wsUrl).cast<String>();
      },
    );

    await getABI();
    getDeployedContract();
    await fetchItems();
    switchAccount();
    listenEvents();
  }

  Future<void> getABI() async {
    String itemManagerAbiFile = await rootBundle.loadString(
      'build/contracts/ItemManager.json',
    );
    final itemManagerAbiAsJson = jsonDecode(itemManagerAbiFile);
    _itemManagerAbiCode = ContractAbi.fromJson(
      jsonEncode(itemManagerAbiAsJson["abi"]),
      "ItemManager",
    );

    _itemManagerContractAddress = EthereumAddress.fromHex(
      itemManagerAbiAsJson["networks"]["5777"]["address"],
    );
  }

  List<FilterEvent>? logs;

  void listenEvents() async {
    logs = await _web3client.getLogs(
      FilterOptions(address: _itemManagerContractAddress),
    );
    notifyListeners();
    _web3client
        .events(FilterOptions(address: _itemManagerContractAddress))
        .listen(
      (event) async {
        if (event.topics != null && event.data != null) {
          final decodedResult = _supplyChainEvent.decodeResults(
            event.topics!,
            event.data!,
          );
          for (var element in decodedResult) {
            debugPrint(element.toString());
          }
        }
      },
    );
  }

  void getDeployedContract() async {
    _deployedParentContract = DeployedContract(
      _itemManagerAbiCode,
      _itemManagerContractAddress,
    );
    _createItem = _deployedParentContract.function("createItem");
    _triggerPayment = _deployedParentContract.function("triggerPayment");
    _triggerDelivery = _deployedParentContract.function("triggerDelivery");
    _items = _deployedParentContract.function("items");
    _itemIndex = _deployedParentContract.function("itemIndex");
    _supplyChainEvent = _deployedParentContract.events.single;
  }

  Future<void> fallback(EthereumAddress item) async {
    String itemAbiFile = await rootBundle.loadString(
      'build/contracts/Item.json',
    );
    final itemAbiAsJson = jsonDecode(itemAbiFile);
    ContractAbi abi;

    abi = ContractAbi.fromJson(
      jsonEncode(itemAbiAsJson["abi"]),
      "Item",
    );
    DeployedContract deployedChildContract;
    deployedChildContract = DeployedContract(
      abi,
      item,
    );

    final l = await _web3client.call(
      contract: deployedChildContract,
      function: deployedChildContract.functions.firstWhere(
        (e) => e.type == ContractFunctionType.fallback,
      ),
      params: [],
    );
  }

  Future<void> createItem({
    required BigInt value,
    required String identifier,
  }) async {
    try {
      await _web3client.sendTransaction(
        currentAccount!,
        Transaction.callContract(
          contract: _deployedParentContract,
          function: _createItem,
          parameters: [
            identifier,
            value,
          ],
        ),
      );
      await fetchItems();
    } on RPCError catch (_) {}
  }

  Future<void> triggerPayment({
    required BigInt index,
    required BigInt price,
  }) async {
    try {
      await _web3client.sendTransaction(
        currentAccount!,
        Transaction.callContract(
          contract: _deployedParentContract,
          function: _triggerPayment,
          parameters: [index],
          value: EtherAmount.inWei(price),
        ),
      );
      await fetchItems();
    } on RPCError catch (_) {}
  }

  Future<void> fetchItems() async {
    final lastIndex = await _web3client.call(
      contract: _deployedParentContract,
      function: _itemIndex,
      params: [],
    );
    BigInt index = BigInt.from(0);
    items.clear();
    while (index < lastIndex[0]) {
      List list = await _web3client.call(
        contract: _deployedParentContract,
        function: _items,
        params: [index],
      );

      UniqueItem item = UniqueItem.fromList(
        index,
        list,
      );
      items.add(item);

      index += BigInt.from(1);
    }
    notifyListeners();
  }

  Future<void> triggerDelivery(BigInt index) async {
    try {
      await _web3client.sendTransaction(
        currentAccount!,
        Transaction.callContract(
          contract: _deployedParentContract,
          function: _triggerDelivery,
          parameters: [index],
        ),
      );
      await fetchItems();
    } on RPCError catch (_) {}
  }
}

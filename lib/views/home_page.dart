import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:item_manager/controllers/item_manager_service.dart';
import 'package:item_manager/utils/int_extension.dart';
import 'package:item_manager/widgets/item_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool create = false;
  final idController = TextEditingController();
  final valueController = TextEditingController();
  EtherUnit unit = EtherUnit.wei;

  Web3ItemManagerService getData([bool listen = false]) {
    return Provider.of<Web3ItemManagerService>(
      context,
      listen: listen,
    );
  }

  @override
  void initState() {
    super.initState();
    getData().init();
  }

  @override
  void dispose() {
    super.dispose();
    idController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
    );
  }

  AppBar get appBar {
    return AppBar(
      title: Text(
        'Account: '
        '${getData(true).currentAccount?.address.toString().substring(0, 9) ?? ''}'
        '...',
      ),
      actions: [
        IconButton(
          tooltip: "Change Account",
          onPressed: getData().switchAccount,
          icon: const Icon(
            Icons.switch_account_rounded,
          ),
        )
      ],
    );
  }

  ListView get body {
    return ListView(
      children: [
        ...fields,
        createButton,
        ...getData(true).items.map(
              (item) => UniqueItemListTile(
                item: item,
              ),
            ),
      ],
    );
  }

  List<Widget> get fields {
    return [
      Visibility(
        visible: create,
        child: TextField(
          controller: idController,
          decoration: const InputDecoration(
            labelText: "Identifier",
          ),
        ),
      ),
      Visibility(
        visible: create,
        child: TextField(
          controller: valueController,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            label: Text("Price in ${unit.name}"),
            suffixIcon: PopupMenuButton<EtherUnit>(
              itemBuilder: (context) {
                return EtherUnit.values.map(
                  (u) {
                    return PopupMenuItem<EtherUnit>(
                      onTap: () {
                        setState(() {
                          unit = u;
                        });
                      },
                      value: u,
                      child: Text(
                        u.name,
                      ),
                    );
                  },
                ).toList();
              },
            ),
          ),
        ),
      ),
    ];
  }

  ElevatedButton get createButton {
    return ElevatedButton(
      onPressed: createItem,
      child: const Text(
        "Create Item",
      ),
    );
  }

  void createItem() {
    if (!create) {
      setState(() {
        create = true;
      });
    } else if (idController.text.isNotEmpty &&
        int.tryParse(valueController.text) != null &&
        getData().currentAccount != null) {

      int priceAsInt = int.parse(valueController.text);
      BigInt price = priceAsInt.toBigInt(unit);
      getData().createItem(
        value: price,
        identifier: idController.text,
      );
      idController.clear();
      valueController.clear();
      create = false;
    }
  }

  Future<void> showError(
    BuildContext context,
    String message,
  ) {
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(message),
          );
        });
  }
}
import 'package:web3dart/web3dart.dart';

extension IntExtension on int {
  static const String _ext = "000";
  BigInt get _toKwei => BigInt.parse("${this}$_ext");
  BigInt get _toMwei => BigInt.parse("${this}${_ext * 2}");
  BigInt get _toGwei => BigInt.parse("${this}${_ext * 3}");
  BigInt get _toSzabo => BigInt.parse("${this}${_ext * 4}");
  BigInt get _toFinney => BigInt.parse("${this}${_ext * 5}");
  BigInt get _toEther => BigInt.parse("${this}${_ext * 6}");

  BigInt toBigInt(EtherUnit unit) {
    switch (unit) {
      case EtherUnit.kwei:
        return _toKwei;
      case EtherUnit.mwei:
        return _toMwei;
      case EtherUnit.gwei:
        return _toGwei;
      case EtherUnit.szabo:
        return _toSzabo;
      case EtherUnit.finney:
        return _toFinney;
      case EtherUnit.ether:
        return _toEther;
      default:
        return BigInt.from(this);
    }
  }
}

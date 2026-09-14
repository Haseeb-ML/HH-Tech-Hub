void main() { 
  print(BigInt.tryParse('1725430267000')); 
  print(BigInt.tryParse('led_inc_inc_1725430267000'.replaceAll(RegExp(r'[^0-9]'), ''))); 
}

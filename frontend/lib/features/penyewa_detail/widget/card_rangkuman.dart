import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kos_management/utils/tagihan_rules.dart';

  class CardRangkuman extends StatelessWidget {
  final List<Map<String,dynamic>> list_tagihan;
  const CardRangkuman({super.key,required this.list_tagihan});

  @override
  Widget build(BuildContext context) {
    final data = hitung_rangkuman(data: list_tagihan);
    return Padding(padding: EdgeInsetsGeometry.only(top: 5,bottom: 5, right: 5, left: 5),
      child:Card(
        color: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 2,
        child: Padding(
          padding: EdgeInsetsGeometry.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  card_statistik(Colors.blue.withValues(alpha: 0.123),Colors.blue.withValues(alpha: 0.25),Icons.description,Colors.blue[500]!,"Total","Rp ${data["tagihan"]??0}","${data["jumlah_aktif"] ?? list_tagihan.length} tagihan"),
                  SizedBox(width: 10,),
                  card_statistik(Colors.green.withValues(alpha: 0.123),Colors.green.withValues(alpha: 0.25),Icons.request_page,Colors.green[500]!,"Bayar","Rp ${data["bayar"]??0}","total di bayar"),
                  SizedBox(width: 10,),
                  card_statistik(Colors.orangeAccent.withValues(alpha: 0.123),Colors.orangeAccent.withValues(alpha: 0.25),Icons.account_balance_wallet,Colors.orange[500]!,"Sisa","Rp ${data["sisa"]??0}","${data["tagihan_sisa"]} tagihan"),
                ],
              ),
            ],
          )
        ),
      )
    );
  }
}
Map hitung_rangkuman ({
  required List<Map<String,dynamic>> data,
}){ 
  if(data.isEmpty) return {};

  final aktif = data.where((v) => !TagihanRules.isCancelled(v)).toList();
  if (aktif.isEmpty) return {};

  int angka(dynamic v) => int.tryParse('$v') ?? 0;
  var tagihan = aktif.fold(0, (p, v) => p + angka(v['total_tagihan'] ?? v['harga_sewa']));
  var bayar = aktif.fold(0, (p, v) => p + angka(v['total_dibayar']));
  var sisa = tagihan - bayar;
  var jmlTagihanSisa = aktif.where((v) {
    final st = TagihanRules.normalizeBayar(v['status_pembayaran']);
    return st != TagihanRules.bayarLunas;
  });

  return {
    "tagihan": tagihan,
    "bayar": bayar,
    "sisa": sisa,
    "tagihan_sisa": jmlTagihanSisa.length,
    "jumlah_aktif": aktif.length,
  };
}


  Widget card_statistik (
    Color colorBackgroun,Color colorBorder, IconData icon, Color colorIcon,
    String title, String value, String subtile
  ){
    //KOMPONEN KHUSUS CARD STATIK
    return Expanded(
      flex: 1,
      child: Material(
          color: colorBackgroun,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: colorBorder,
              width: 0.8
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          
          child: Padding(
            padding: EdgeInsetsGeometry.only(top: 15, bottom: 15, right: 5,left: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon(icon,color: color_icon,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                      subtile,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Colors.grey[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w500
                      ),
                    )
                  ],
                ),
              ],
            )
          ),
        ),
    );
  }

    // List<Widget> card_statistik_tunggal ({required String title1,required String title2, required String title3,required String value1,required String value2,required String value3,required IconData icon1,required IconData icon2,required IconData icon3, required Color color_icon}){
  //   //KOMPONEN KHUSUS CARD STATIK
  //   return [
  //     Expanded(
  //       flex: 1,
  //       child: SizedBox(
  //         height: 50,
  //         width: double.infinity,
  //         child: Padding(
  //           padding: EdgeInsetsGeometry.only(top: 2, bottom: 2, right: 2,left: 2),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [
  //               Icon(icon1,color: color_icon,),
  //               Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title1,
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontSize: 9,
  //                       fontWeight: FontWeight.w700
  //                     ),
  //                   ),
  //                   Text(
  //                     value1,
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.black,
  //                       fontWeight: FontWeight.normal
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           )
  //         ),
  //       )
  //     ),
  //     SizedBox(width: 5,),
  //     Expanded(
  //       flex: 1,
  //       child: SizedBox(
  //         height: 50,
  //         width: double.infinity,
  //         child: Padding(
  //           padding: EdgeInsetsGeometry.only(top: 2, bottom: 2, right: 2,left: 2),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [
  //               Icon(icon2,color: color_icon,),
  //               Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title2,
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontSize: 9,
  //                       fontWeight: FontWeight.w700
  //                     ),
  //                   ),
  //                   Text(
  //                     value2,
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.black,
  //                       fontWeight: FontWeight.bold
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           )
  //         ),
  //       )
  //     ),
  //     SizedBox(width: 5,),

  //     Expanded(
  //       flex: 1,
  //       child: SizedBox(
  //         height: 50,
  //         width: double.infinity,
  //         child: Padding(
  //           padding: EdgeInsetsGeometry.only(top: 2, bottom: 2, right: 2,left: 2),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [
  //               Icon(icon3,color: color_icon,),
  //               Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title3,
  //                     style: TextStyle(
  //                       color: Colors.black,
  //                       fontSize: 9,
  //                       fontWeight: FontWeight.w700
  //                     ),
  //                   ),
  //                   Text(
  //                     value3,
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.black,
  //                       fontWeight: FontWeight.bold
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           )
  //         ),
  //       )
  //     ),
  //   ];
  // }
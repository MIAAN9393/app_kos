import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


  Widget card_statistik (
    Color color_backgroun,Color color_border, IconData icon, Color color_icon,
    String title, String value, String subtile
  ){
    //KOMPONEN KHUSUS CARD STATIK
    return Expanded(
      flex: 1,
      child: Material(
          color: color_backgroun,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: color_border,
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text("appbar"),
          IconButton(onPressed: (){
            showModalBottomSheet(context: context, builder: (context){
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(1))
                ),
                height: 500,
                child: ListView(
                  children: [
                    StatefulBuilder(
                        builder: (context,setState){
                        return Padding(
                          padding: EdgeInsetsGeometry.all(10),
                          child: Column(
                              children: [
                                Center(child: Text("kepala"),),
                                SizedBox(height: 30,),
                                Wrap(
                                    direction: Axis.horizontal,
                                    alignment: WrapAlignment.spaceAround,
                                  spacing: 5,
                                  children: [
                                    ChoiceChip(
                                      label: Text("Murah",style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),), 
                                      selected: true,
                                      selectedColor: Theme.of(context).colorScheme.secondary,
                                    ),

                                  ],
                                ),
                                SizedBox(height: 30,),
                                Center(
                                  child:Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(onPressed: (){}, child: Text("batalkan",
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)
                                      ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.error
                                        ),
                                      ),
                                      SizedBox(width: 10,),
                                      TextButton(onPressed: (){}, child: Text("terapkan",
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)
                                      ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary
                                        ),
                                      )
                                    ],
                                  )
                                )
                              ],
                            )
                        );
                      }
                    )
                  ],
                ),
              );
            });
          }, icon: Icon(Icons.add))],
        )
      ),
      body: Center(
        child: Column(
          children: [
            
          ],
        ),
      ),
    );
  }
}
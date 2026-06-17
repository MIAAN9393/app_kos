import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';

Widget tombolFilter(
  BuildContext context,
  bool kosong,
  bool sebagian,
  bool penuh,
  Function(Map<String, bool>) tangkapResult, {
  bool ac = false,
  bool wifi = false,
  bool lemari = false,
  bool kamarMandi = false,
}) {
  return Row(
    children: [
      IconButton(
        icon: Icon(Icons.filter_list_rounded),
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: ()async{
              bool localKosong = kosong;
              bool localSebagian = sebagian;
              bool localPenuh = penuh;
              bool localAc = ac;
              bool localWifi = wifi;
              bool localLemari = lemari;
              bool localKamarMandi = kamarMandi;
         final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔹 title
                          Text(
                            "FILTER",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),

                          const SizedBox(height: 20),

                          // 🔹 chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              choiceChipCustom(
                                context: context,
                                label: "Kosong",
                                selected: localKosong,
                                onSelected: (value) {
                                  setState(() {
                                    localKosong = value;
                                  });
                                },
                              ),
                              choiceChipCustom(
                                context: context,
                                label: "Sebagian",
                                selected: localSebagian,
                                onSelected: (value) {
                                  setState(() {
                                    localSebagian = value;
                                  });
                                },
                              ),
                              choiceChipCustom(
                                context: context,
                                label: "Penuh",
                                selected: localPenuh,
                                onSelected: (value) {
                                  setState(() {
                                    localPenuh = value;
                                  });
                                },
                              ),
                              choiceChipCustom(
                                context: context,
                                label: KamarFasilitas.labelFor(
                                  KamarFasilitas.ac,
                                ),
                                selected: localAc,
                                onSelected: (value) {
                                  setState(() {
                                    localAc = value;
                                  });
                                },
                              ),
                              choiceChipCustom(
                                context: context,
                                label: KamarFasilitas.labelFor(
                                  KamarFasilitas.wifi,
                                ),
                                selected: localWifi,
                                onSelected: (value) {
                                  setState(() {
                                    localWifi = value;
                                  });
                                },
                              ),
                              choiceChipCustom(
                                context: context,
                                label: KamarFasilitas.labelFor(
                                  KamarFasilitas.lemari,
                                ),
                                selected: localLemari,
                                onSelected: (value) {
                                  setState(() {
                                    localLemari = value;
                                  });
                                },
                              ),
                              choiceChipCustom(
                                context: context,
                                label: KamarFasilitas.labelFor(
                                  KamarFasilitas.kamarMandi,
                                ),
                                selected: localKamarMandi,
                                onSelected: (value) {
                                  setState(() {
                                    localKamarMandi = value;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // 🔹 tombol aksi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // mainAxisSize: MainAxisSize.min,
                            children: [
                              // ❌ batal
                              ElevatedButton(
                                onPressed: (){
                                    Navigator.pop(context);
                                  }, 
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: AppColors.icon_hapus
                                ),
                                child: const Text("batal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              

                              const SizedBox(width: 12),

                              // ✅ terapkan
                              ElevatedButton(
                                onPressed: (){
                                  Navigator.pop(context,{
                                    "kosong":localKosong,
                                    "sebagian":localSebagian,
                                    "penuh":localPenuh,
                                    "ac":localAc,
                                    "wifi":localWifi,
                                    "lemari":localLemari,
                                    "kamar_mandi":localKamarMandi,
                                  });
                                }, 
                                child: const Text("Terapkan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              )
                            ],
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );

          //KIRIM NILAI KELUAR
          if(result != null){
            tangkapResult(result);
          }
        },
      ),
    ],
  );
}

Widget choiceChipCustom({
  required BuildContext context,
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return ChoiceChip(
    label: Text(label),

    selected: selected,
    onSelected: onSelected,

    // 🎨 warna utama
    backgroundColor: colorScheme.surfaceContainerHighest,
    selectedColor: colorScheme.primary,

    // 🧠 warna text auto adapt
    labelStyle: TextStyle(
      color: selected
          ? colorScheme.onPrimary
          : colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    ),

    // ✨ biar lebih clean & modern
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected
            ? colorScheme.primary
            : colorScheme.outline,
      ),
    ),

    // optional: padding biar enak dilihat
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}

import 'package:flutter/material.dart';
import 'package:kos_management/features/kos/widget/appbar_button_fillter.dart';

class AppBarHelper {
  static PreferredSizeWidget appbar_costum({
    required BuildContext context,
    final int height = 55,
    required TextEditingController controller,
    required Function(String result_search) ftombol_cari,
    bool Kosong = false,
    bool Sebagian = false,
    bool penuh = false,
    Function(Map<String, bool>)? tangkap_result,
    bool showFilter = true,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height.toDouble() + 20),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        elevation: 0,
        toolbarHeight: height.toDouble() + 20,
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'PENYEWA',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                ),
              ),
            ),
            Row(
              children: [
                actionButton(
                  context,
                  Icons.arrow_back,
                  Colors.white,
                  Colors.black,
                  () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: controller,
                      cursorColor: Theme.of(context).colorScheme.primary,
                      cursorWidth: 2,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.onPrimary,
                        hintText: 'Cari penyewa...',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            ftombol_cari(controller.text);
                            FocusScope.of(context).unfocus();
                          },
                          icon: Icon(
                            Icons.search,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showFilter) ...[
                  const SizedBox(width: 8),
                  tombolFilter(context, Kosong, Sebagian, penuh, (result) {
                    if (result != null && tangkap_result != null) {
                      tangkap_result(result);
                    }
                  }),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

Widget actionButton(
  BuildContext context,
  IconData icon,
  Color colorBackground,
  Color colorIcon,
  VoidCallback onTap,
) {
  return Padding(
    padding: const EdgeInsets.all(6),
    child: Material(
      color: colorBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(60),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(60),
        onTap: onTap,
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        child: SizedBox(
          width: 45,
          height: 40,
          child: Icon(icon, color: colorIcon),
        ),
      ),
    ),
  );
}

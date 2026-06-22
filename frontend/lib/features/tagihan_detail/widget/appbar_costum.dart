import 'package:flutter/material.dart';

PreferredSizeWidget appBar({
  context
}){
  return AppBar(
    toolbarHeight: 50,
    backgroundColor: Theme.of(context).colorScheme.primary,
    title: Text(
      "TAGIHAN DETAIL",
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 20
      ),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30))
    ),
    centerTitle: true,
    automaticallyImplyLeading: false,
    leading: actionButton(context,Icons.arrow_back, Colors.white, Colors.black, (){
      Navigator.pop(context);
    })

  );
}

Widget actionButton(
  context,
  IconData icon,
  Color colorBackground,
  Color colorIcon,
  VoidCallback onTap,
) {
  return Padding(
    padding: EdgeInsetsGeometry.all(6),
     child: Material(
    color: colorBackground,
    elevation: 0,
    // shadowColor: Theme.of(context).colorScheme.primary,
    // surfaceTintColor: Theme.of(context).colorScheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(60),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(60),
      onTap: onTap,
      splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(
          icon,
          color: colorIcon,
        ),
      ),
    ),
  )
  );
}
import 'package:flutter/material.dart';

class GenreContainer extends StatelessWidget {
  final String genre;
  final Function onTap;
  final IconData icon;

  const GenreContainer({
    required this.genre,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        height: 150,
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Color(0xFFDDDAE7),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 8.0),
              Text(
                genre,
                // textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                icon,
                color: Colors.black,
                size: 50.0,
              ),
              SizedBox(width: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}

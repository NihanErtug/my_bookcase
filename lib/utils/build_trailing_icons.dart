import 'dart:io';

import 'package:bookcase/models/book.dart';
import 'package:bookcase/providers/firebase_service_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget buildTrailingIcons(BuildContext context, WidgetRef ref, Book book) {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Transform.scale(
        scale: 0.7,
        child: Switch(
          value: book.isRead,
          onChanged: (value) async {
            await ref
                .read(firebaseServicesProvider)
                .booksService
                .updateBookStatus(book.id!, isRead: value);

            _refreshBookDetail(ref, book.id!, userId);
          },
        ),
      ),
      IconButton(
        icon: Icon(
          book.isStarred ? Icons.star : Icons.star_border,
          color: book.isStarred ? Colors.amber : Colors.grey,
        ),
        onPressed: () async {
          await ref
              .read(firebaseServicesProvider)
              .booksService
              .updateBookStatus(book.id!, isStarred: !book.isStarred);

          _refreshBookDetail(ref, book.id!, userId);
        },
      ),
    ],
  );
}

void _refreshBookDetail(WidgetRef ref, String bookId, String userId) {
  // ignore: unused_result
  ref.refresh(bookDetailProvider((bookId, userId)));
}

Widget buildImage(String? imageUrlOrPath, BuildContext context) {
  final double imageWidth = MediaQuery.of(context).size.width * 0.3;
  final double imageHeight = MediaQuery.of(context).size.width * 0.4;

  Widget imageWidget;

  if (imageUrlOrPath == null) {
    imageWidget = Image.asset(
      'assets/pictures/default_pic.png',
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.contain,
    );
  } else if (imageUrlOrPath.startsWith('/')) {
    imageWidget = Image.file(
      File(imageUrlOrPath),
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.contain,
    );
  } else {
    imageWidget = Image.network(
      imageUrlOrPath,
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/pictures/default_pic.png',
          width: imageWidth,
          height: imageHeight,
        );
      },
    );
  }

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageWidget,
    ),
  );
}

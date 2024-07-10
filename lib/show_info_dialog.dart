import 'package:apps_check_metadata/primary_button.dart';
import 'package:apps_check_metadata/state_util.dart';
import 'package:flutter/material.dart';

Future showInfoDialog(String message) async {
  await showDialog<void>(
    context: globalContext,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            controller: ScrollController(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Informasi",
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SingleChildScrollView(
                    controller: ScrollController(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        message,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PrimaryButton(
                    onPressed: () {
                      Get.back();
                    },
                    text: "Ya, saya mengerti",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

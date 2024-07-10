// ignore_for_file: camel_case_types
import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final Function()? onPressed;
  final String text;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: Colors.lightBlue[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

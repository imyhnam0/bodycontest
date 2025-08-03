import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitInquiry() async {
    final String content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문의 내용을 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String nowString =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      await FirebaseFirestore.instance
          .collection('inquiry')
          .doc(nowString) // 문서 이름 = 날짜+시간
          .set({
        '내용': content,
        '작성일': nowString,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문의가 성공적으로 전송되었습니다.")),
      );

      Navigator.pop(context); // 문의 완료 후 페이지 닫기
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("문의하기"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "문의 내용을 입력하세요",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: Colors.black),
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "문의 내용을 작성해주세요...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitInquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, // 버튼 색상
                  foregroundColor: Colors.black, // 텍스트 색상
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  "확인",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

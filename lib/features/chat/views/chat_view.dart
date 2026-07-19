import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

/// 두 사람 사이의 1:1 실시간 채팅 화면.
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.myUid,
    required this.otherUid,
    required this.otherName,
  });

  final String myUid;
  final String otherUid;
  final String otherName;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatRepository _repository = context.read<ChatRepository>();
  late final String _roomId =
      _repository.roomIdFor(widget.myUid, widget.otherUid);

  @override
  void initState() {
    super.initState();
    _repository.markRead(roomId: _roomId, uid: widget.myUid);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await _repository.send(
      roomId: _roomId,
      participants: [widget.myUid, widget.otherUid],
      senderId: widget.myUid,
      text: text,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: SafeArea(
        minimum: EdgeInsets.only(bottom: 10.h),
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: AppColors.rowBg,
                child: StreamBuilder<List<ChatMessage>>(
                stream: _repository.watchMessages(_roomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return Center(
                      child: Text('첫 메시지를 보내보세요',
                          style: TextStyle(
                              fontSize: 14.sp, color: AppColors.gray)),
                    );
                  }
                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _Bubble(
                        text: msg.text,
                        isMine: msg.senderId == widget.myUid,
                      );
                    },
                  );
                },
              ),
              ),
            ),
            _InputBar(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isMine});

  final String text;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 260.w),
        decoration: BoxDecoration(
          color: isMine ? AppColors.pink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMine ? 18.r : 4.r),
            topRight: Radius.circular(isMine ? 4.r : 18.r),
            bottomLeft: Radius.circular(18.r),
            bottomRight: Radius.circular(18.r),
          ),
          boxShadow: isMine
              ? null
              : [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.35,
            color: isMine ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: '메시지 입력…',
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow(blur: 8, y: 3),
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 22.sp),
            ),
          ),
        ],
      ),
    );
  }
}

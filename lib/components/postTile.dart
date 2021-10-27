import 'package:flutter/material.dart';

class _ArticleDescription extends StatelessWidget {
  /// 타일용 자료구조 - DB 에서 필요한 정보만 추출
  const _ArticleDescription({
    Key key,
    this.title,
    this.subtitle,
    this.author,
    this.publishDate,
    // this.category,
    this.likes,
  }) : super(key: key);

  final String title;
  final String subtitle;
  final String author;
  final String publishDate;
  // final String category;
  final int likes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 게시글 제목 영역
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'NanumSquareRoundR',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 4.0)),

              /// 게시글 본문(미리보기) 영역 2줄초과시 뒷부분 ... 처리
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'NanumSquareRoundR',
                  fontSize: 12.0,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              /// 작성자 영역(카테고리 제거)
              Text(
                '$author',
                style: const TextStyle(
                  fontFamily: 'NanumSquareRoundR',
                  fontSize: 12.0,
                  color: Colors.black87,
                ),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 2.0)),

              /// 작성날짜 영역 (DB 개선후 좋아요 기능 추가시 수정)
              Text(
                // '$publishDate - ♥️: $likes',
                publishDate,
                style: const TextStyle(
                  fontFamily: 'NanumSquareRoundR',
                  fontSize: 12.0,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomListItem extends StatelessWidget {
  const CustomListItem({
    Key key,
    this.thumbnail,
    this.title,
    this.subtitle,
    this.author,
    this.publishDate,
    // this.category,
    this.likes,
  }) : super(key: key);

  final Widget thumbnail;
  final String title;
  final String subtitle;
  final String author;
  final String publishDate;
 // final String category;
  final int likes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: SizedBox(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _ArticleDescription(
                title: title,
                subtitle: subtitle,
                author: author,
                publishDate: publishDate,
                // category: category,
                likes: likes,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: thumbnail,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

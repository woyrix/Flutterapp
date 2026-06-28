class RelatedBookData {
  final String title;
  final String? downloadUrl;

  const RelatedBookData({
    required this.title,
    this.downloadUrl,
  });
}

class RelatedBooksData {
  static const List<RelatedBookData> all = [
    RelatedBookData(
      title: '॥ विहंगिनी काव्य ॥',
      downloadUrl:
          'https://drive.google.com/file/d/1FXCR4qKsMcN6YnG1YbsSIZrvjeDIJdQl/view?usp=drive_link',
    ),
    RelatedBookData(
      title: 'चलौ री, आज ब्रजराज मुख निरखिये',
      downloadUrl:
          'https://drive.google.com/file/d/1R9SD9L9BjCZvT5o2RY8LuB_n3EjZrtzP/view?usp=drive_link',
    ),
    RelatedBookData(
      title: 'जय जय प्रियतम (सरलार्थ)',
      downloadUrl:
          'https://drive.google.com/file/d/13VsMxqeaYRh39YZ4A0WgAJi5wfaSK6Qg/view?usp=drive_link',
    ),
    RelatedBookData(
      title: 'जय जय प्रियतम',
      downloadUrl:
          'https://drive.google.com/file/d/1bBOU27gXTK_LVfzT5ZaH-alc-CZ2KlMU/view?usp=drive_link',
    ),
    RelatedBookData(
      title: 'प्रेम-देशके पथिकका प्रणय-गीत- प्रियतमसे संवाद',
      downloadUrl:
          'https://drive.google.com/file/d/1zQJPwBsyRwDqj12y0j4Ok1efUCfsV5gv/view?usp=drive_link',
    ),
    RelatedBookData(
      title: 'महाभाव-दिनमणि श्रीराधाबाबा षष्ठम खण्ड (प्रथम भाग)',
      downloadUrl:
          'https://drive.google.com/file/d/158C54ZfB6ikmz7SGlIIROMdSCEvzl_Cc/view?usp=drive_link',
    ),
    RelatedBookData(
      title: 'महाभाव-दिनमणि श्रीराधाबाबा षष्ठम खण्ड (द्वितीय भाग)',
      downloadUrl:
          'https://drive.google.com/file/d/1YtcOGLfkFnfrCw_akCYRVJVaVAK5U_Ky/view?usp=drive_link',
    ),
  ];
}

import 'dart:io';

/// A wrapper around a file upload.
class HttpBodyFileUpload {
  /// The filename of the uploaded file.
  final String filename;

  /// The [ContentType] of the uploaded file.
  ///
  /// For `text/*` and `application/json` the [content] field will a String.
  final ContentType? contentType;

  /// The content of the file.
  ///
  /// Either a [String] or a [List<int>].
  final dynamic content;

  HttpBodyFileUpload(this.contentType, this.filename, this.content);
}
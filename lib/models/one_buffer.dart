import 'record.dart';
import 'image_buffer.dart';

class OneBuffer {
  Record record;
  YUVImages yuvImages = YUVImages.empty();

  void update(Record _record, YUVImages _yuvImages) {
    record = _record;
    yuvImages = _yuvImages;
  }
}

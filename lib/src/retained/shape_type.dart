class ShapeType {
  static const ShapeType rect = const ShapeType._internal("Boxangle");
  static const ShapeType ellipse = const ShapeType._internal("Ellipse");
  final String name;

  const ShapeType._internal(this.name);
}
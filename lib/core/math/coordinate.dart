class Coordinate {
  final num x, y;

  const Coordinate([this.x = 0, this.y = 0]);

  /**
   * Computes the distance to another [Coordinate].
   **/
  num getDistance (Coordinate other) => (this - other).length;

  /**
   * Subtract a [Coordinate] and returns the result as new [Vector].
   **/
  Vector operator -(Coordinate other) => difference(this, other);

  bool operator ==(Coordinate other) {
    return other !== null && x == other.x && y == other.y;
  }

  static Vector difference(Coordinate a, Coordinate b) {
    return new Vector(a.x - b.x, a.y - b.y);
  }

  String toString() => '{"x":${x},"y":${y}}';
}
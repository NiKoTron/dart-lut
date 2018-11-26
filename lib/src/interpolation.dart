class Interpolation {
  static double lerp(num x, num x0, num x1, num y0, num y1) =>
      ((x1 - x0) == 0.0)
          ? (y0 + (y1 - y0) / 2.0).toDouble()
          : (y0 + (x - x0) * (y1 - y0) / (x1 - x0)).toDouble();

  static double bilerp(num x, num y, num q00, num q01, num q10, num q11, num x0,
      num x1, num y0, num y1) {
    final r1 = ((x1 - x) / (x1 - x0)) * q00 + ((x - x0) / (x1 - x0)) * q10;
    final r2 = ((x1 - x) / (x1 - x0)) * q01 + ((x - x0) / (x1 - x0)) * q11;

    final p = ((y1 - y) / (y1 - y0)) * r1 + ((y - y0) / (y1 - y0)) * r2;

    return p.toDouble();
  }

  static double trilerp(
      num x,
      num y,
      num z,
      num c000,
      num c001,
      num c010,
      num c011,
      num c100,
      num c101,
      num c110,
      num c111,
      num x0,
      num x1,
      num y0,
      num y1,
      num z0,
      num z1) {
    final xd = (x - x0) / (x1 - x0);
    final yd = (y - y0) / (y1 - y0);
    final zd = (z - z0) / (z1 - z0);

    final c00 = c000 * (1.0 - xd) + c100 * xd;
    final c01 = c001 * (1.0 - xd) + c101 * xd;
    final c10 = c010 * (1.0 - xd) + c110 * xd;
    final c11 = c011 * (1.0 - xd) + c111 * xd;

    final c0 = c00 * (1.0 - yd) + c10 * yd;
    final c1 = c01 * (1.0 - yd) + c11 * yd;

    final c = c0 * (1.0 - zd) + c1 * zd;

    return c.toDouble();
  }
}

#ifndef SHADER_LIBRARY_PRINT_NUMBER
#define SHADER_LIBRARY_PRINT_NUMBER

// 参考 https://www.shadertoy.com/view/clffRB

// ---- 文件作用域：3x5 bitmap font，bit = x + 3*y ----
// index: 0 = '-', 1 = '.', 2~11 = '0'~'9'
static const int GLYPHS[12] =
{
  0x01C0, // '-'
  0x4000, // '.'
  0x7B6F, // '0'
  0x4924, // '1'
  0x73E7, // '2'
  0x79E7, // '3'
  0x49ED, // '4'
  0x79CF, // '5'
  0x7BCF, // '6'
  0x4927, // '7'
  0x7BEF, // '8'
  0x79EF // '9'
};

// 使用 3x5 位图字体在屏幕上绘制单个 float 值
// 适合 Shader Graph 调试、后处理叠加、UI Shader 调试显示
float PrintFloat(
  float2 screenUV,
  float value,
  float2 position,
  float scale
)
{
  screenUV = float2(screenUV.x, 1.0 - screenUV.y);
  float2 resolution = _ScreenParams.xy;
  float2 screenPx = screenUV * resolution;

  int charScale = 2;
  int stretchX = 1;
  int stretchY = 1;

  float2 basePx = position * resolution;
  float2 localPx = (screenPx - basePx) / max(scale, 0.001);

  int2 px = int2(localPx);

  if (px.y < 0 || px.x < 0)
    return 0.0;

  px /= charScale;

  int yMid = 2 + stretchY;
  int yEnd = 4 + stretchY * 2;

  if (px.y == 0)
    px.y = 0;
  else if (px.y > 0 && px.y < yMid)
    px.y = 1;
  else if (px.y == yMid)
    px.y = 2;
  else if (px.y > yMid && px.y < yEnd)
    px.y = 3;
  else if (px.y == yEnd)
    px.y = 4;
  else
    return 0.0;

  int xEnd = 2 + stretchX;

  int gx = px.x % (4 + stretchX);
  int whichDigit = px.x / (4 + stretchX);

  if (gx == 0)
    px.x = 0;
  else if (gx > 0 && gx < xEnd)
    px.x = 1;
  else if (gx == xEnd)
    px.x = 2;
  else
    return 0.0;

  // 3x5 bitmap font
  // index: -2 = '-', -1 = '.', 0~9 = '0'~'9'
  int glyphBit = 1 << (px.x + 3 * px.y);

  int intDigits = 1;
  int num2 = abs(int(value));

  while (num2 >= 10)
  {
    intDigits += 1;
    num2 /= 10;
  }

  if (whichDigit - intDigits > 5)
    return 0.0;

  int digit = -1;

  if (value < 0.0)
  {
    if (whichDigit == 0)
      digit = -2;

    whichDigit -= 1;
  }

  if (whichDigit >= 0 && whichDigit < intDigits)
  {
    whichDigit = intDigits - whichDigit - 1;

    digit = abs(int(value));

    for (int i = 0; i < whichDigit; i++)
      digit /= 10;

    digit = (digit % 10 + 10) % 10;
  }
  else if (whichDigit > intDigits)
  {
    whichDigit = whichDigit - intDigits;

    float factor = 1.0;

    for (int i = 0; i < whichDigit; i++)
      factor *= 10.0;

    int num3 = int(abs(frac(abs(value))) * factor);
    digit = num3 % 10;
  }

  int mask = 0;

  if (digit >= -2 && digit <= 9)
    mask = GLYPHS[digit + 2];

  return (mask & glyphBit) > 0 ? 1.0 : 0.0;
}


#endif // SHADER_LIBRARY_PRINT_NUMBER
void setup()
{
  pinMode(9, OUTPUT);
  pinMode(10, OUTPUT);
  pinMode(11, OUTPUT);
  pinMode(13, OUTPUT);

  //set up timer1
  TCCR1A = (1 << COM1A1) | (1 << COM1A0) | (1 << COM1B1) | (1 << COM1B0) |
           (0 << FOC1A)  | (0 << FOC1B)  | (1 << WGM11)  | (0 << WGM10);
  TCCR1B = (0 << ICNC1)  | (0 << ICES1)  | (1 << WGM13)  | (0 << WGM12)  |
           (0 << CS12)   | (1 << CS11)   | (0 << CS10);
  ICR1 = 4080; //12 bit pwm (almost)

  //set up timer2
  TCCR2 = (0 << FOC2)  | (1 << WGM20) | (1 << COM21) | (1 << COM20) |
          (0 << WGM21) | (0 << CS22)  | (1 << CS21)  | (0 << CS20);
  TIMSK |= (1 << TOIE2) | (0 << OCIE2);

  TCNT0 = 0;
  TCNT1 = 0;

  sei();

  Serial.begin(115200);
}

volatile uint16_t newval;
volatile bool     hasnewval;

uint8_t           pwmcount;
uint16_t          pwmval;
uint16_t          outval;

//make 12 bit pwm out of 8 bit pwm by loading in a new value on the overflow interrupt
ISR(TIMER2_OVF_vect)
{
  if (outval < 256)
  {
    OCR2 = outval;
    outval = 0;
  }
  else
  {
    OCR2 = 255;
    outval -= 255;
  }

  if (hasnewval)
  {
    pwmval = newval;
    hasnewval = false;
  }

  pwmcount++;
  if (pwmcount == 16)
  {
    pwmcount = 0;
    outval = pwmval;
  }
}

#define LIGHTNR 0
#define REDCH   (LIGHTNR * 3)
#define GREENCH (LIGHTNR * 3 + 1)
#define BLUECH  (LIGHTNR * 3 + 2)

void loop()
{
  fade(); //little animation to annoy people

  uint8_t i, channels;
  uint16_t r, g, b;

  while(1)
  {
    WaitForPrefix();

    while (!Serial.available());
    channels = Serial.read();

    for (i = 0; i < channels; i++)
    {
      if (i == REDCH)
      {
        r = ReadSerial();
        r <<= 8;
        r |= ReadSerial();
      }
      else if (i == GREENCH)
      {
        g = ReadSerial();
        g <<= 8;
        g |= ReadSerial();
      }
      else if (i == BLUECH)
      {
        b = ReadSerial();
        b <<= 8;
        b |= ReadSerial();
      }
      else
      {
        ReadSerial();
        ReadSerial();
      }
    }
    while(hasnewval);
    WriteRGBasync(r, g, b);
  }
}

//boblightd needs to send 0x55 0xAA before sending the channel bytes
void WaitForPrefix()
{
  uint8_t first = 0, second = 0;
  while (second != 0x55 || first != 0xAA)
  {
    while (!Serial.available());
    second = first;
    first = Serial.read();
  }
}

uint16_t ReadSerial()
{
  while (!Serial.available());
  return Serial.read();
}

void fade()
{
  for (uint16_t i = 0; i < 4096; i++)
    WriteRGB(i, 0, 0);
  for (uint16_t i = 4095; i > 0; i--)
    WriteRGB(i, 0, 0);

  for (uint16_t i = 0; i < 4096; i++)
    WriteRGB(0, i, 0);
  for (uint16_t i = 4095; i > 0; i--)
    WriteRGB(0, i, 0);

  for (uint16_t i = 0; i < 4096; i++)
    WriteRGB(0, 0, i);
  for (uint16_t i = 4095; i > 0; i--)
    WriteRGB(0, 0, i);

    WriteRGB(0, 0, 0);
}

void WriteRGB(uint16_t r, uint16_t g, uint16_t b)
{
  WriteRGBasync(r, g, b);
  while(hasnewval);
}

void WriteRGBasync(uint16_t r, uint16_t g, uint16_t b)
{
  if (r > 4080)
    r = 4080;
  if (g > 4080)
    g = 4080;
  if (b > 4080)
    b = 4080;
  newval = r;
  hasnewval = true;
  OCR1B  = g;
  OCR1A  = b;
}


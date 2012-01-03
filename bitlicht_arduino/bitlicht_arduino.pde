void setup()
{
  pinMode(9, OUTPUT);
  pinMode(10, OUTPUT);
  pinMode(11, OUTPUT);
  pinMode(13, OUTPUT);

  //set up timer1
  TCCR1A = (1 << COM1A1) | (0 << COM1A0) | (1 << COM1B1) | (0 << COM1B0) | (0 << FOC1A) | (0 << FOC1B) | (1 << WGM11) | (0 << WGM10);
  TCCR1B = (0 << ICNC1)  | (0 << ICES1)  | (1 << WGM13)  | (1 << WGM12)  | (0 << CS12)  | (1 << CS11)  | (0 << CS10);
  ICR1 = 4095; //12 bit pwm

  //set up timer2
  TCCR2 = (0 << FOC2) | (1 << WGM20) | (1 << COM21) | (0 << COM20) | (1 << WGM21) | (0 << CS22) | (1 << CS21) | (0 << CS20);
  TIMSK |= (1<<TOIE2) | (0<<OCIE2);
  sei();
}

volatile uint16_t newval;
volatile bool     hasnewval;

uint8_t           pwmcount;
uint16_t          pwmval;
uint16_t          outval;
uint8_t           makelow;

ISR(TIMER2_OVF_vect)
{
  if (makelow == 2)
  {
    PORTB &= ~(1 << PB3);
    TCCR2 &= ~(1 << COM21);
    makelow = 0;
  }

  if (outval < 256)
  {
    OCR2 = outval;
    if (outval > 0)
      makelow = 1;
    else if (makelow == 1)
      makelow = 2;

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
    if (outval > 0)
      TCCR2 |= 1 << COM21;
  }
}

void loop()
{
  /*newval = 128;
  hasnewval = true;
  return;*/

  for (uint16_t i = 0; i < 1024; i++)
  {
    OCR1A = i;
    OCR1B = i;
    newval = i;
    hasnewval = true;
    delay(1);
  }

  for (uint16_t i = 1023; i > 0; i--)
  {
    OCR1A = i;
    OCR1B = i;
    newval = i;
    hasnewval = true;
    delay(1);
  }
}


/* rs485.c: Get and set RS485 device parameters.
 *
 * Copyright © 2020 Revolution Robotics, Inc.
 *
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <linux/serial.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "getopt.h"

/* Maximum length of device, e.g., /dev/ttymxc1 */
#define DEVICE_MAX 13
#define PATH_MAX 4096

struct bool_option {
  int set;
  bool value;
};

struct int_option {
  int set;
  int value;
};

struct options {
  struct bool_option mode;
  struct bool_option rts_on_send;
  struct bool_option rts_after_send;
  struct bool_option receive_while_send;
  struct int_option rts_delay_before_send;
  struct int_option rts_delay_after_send;
} opts;

void
usage (char *pgm)
  {
    fprintf (stderr,
             "Usage: %s --device|-d DEVICE OPTIONS\n"
             "OPTIONS:\n"
             "    -a, --rts-after-send=0|1\n"
             "                    Set RTS high (1) or low (0) after send.\n"
             "    -h              Show this help, then exit.\n"
             "    -m, --mode=0|1  Enable (1) or disable (0) RS485 mode.\n"
             "    -o, --rts-on-send=0|1\n"
             "                    Set RTS high (1) or low (0) on send.\n"
             "    -r, --receive-while-send=0|1\n"
             "                    Enable (1) or disable (0) receive while send.\n"
             "    -s, --status    Show device status.\n"
             "    -x, --rts-delay-before-send=ms.\n"
             "                    Set RTS delay before send in milliseconds.\n"
             "    -y, --rts-delay-after-send=ms\n"
             "                    Set RTS delay after send in milliseconds.\n",
             pgm);
    exit (1);
  }

void
rs485_status (int fd, struct serial_rs485 *scp)
  {
    bool rs485_enabled;

    rs485_enabled = (scp->flags & SER_RS485_ENABLED) ? true : false;

    printf ("RS485 mode is %s\n", rs485_enabled ? "enabled" : "disabled");

    if (rs485_enabled)
      {
        printf ("RTS is %s while sending\n",
                (scp->flags & SER_RS485_RTS_ON_SEND) ? "high" : "low");
        printf ("RTS is %s after sending\n",
                (scp->flags & SER_RS485_RTS_AFTER_SEND) ? "high" : "low");
        printf ("Receiving is %s while sending\n",
                (scp->flags & SER_RS485_RX_DURING_TX) ?
                "enabled" : "disabled");
        printf ("RTS delay before sending: %d ms\n",
                scp->delay_rts_before_send);
        printf ("RTS delay after sending: %d ms\n",
                scp->delay_rts_after_send);
      }
  }

void
rs485_mode (int fd, bool enable, struct serial_rs485 *scp)
  {
    printf ("%s RS485 mode\n", enable ? "Enabling" : "Disabling");

    if (enable)

      /* Enable RS485 mode. */
      scp->flags |= SER_RS485_ENABLED;
    else

      /* Disable RS485 mode. */
      scp->flags &= ~(SER_RS485_ENABLED);
  }

void
rts_on_send (int fd, bool high_on_send, struct serial_rs485 *scp)
  {
    printf ("%s RTS on send\n", high_on_send ? "Raising" : "Lowering");

    if (high_on_send)

      /* Set logical level for RTS pin equal to 1 when sending: */
      scp->flags |= SER_RS485_RTS_ON_SEND;
    else

      /* Set logical level for RTS pin equal to 0 when sending: */
      scp->flags &= ~(SER_RS485_RTS_ON_SEND);
  }

void
rts_after_send (int fd, bool high_after_send, struct serial_rs485 *scp)
  {
    printf ("%s RTS after send\n", high_after_send ? "Raising" : "Lowering");

    if (high_after_send)

      /* Set logical level for RTS pin equal to 1 after sending: */
      scp->flags |= SER_RS485_RTS_AFTER_SEND;
    else

      /* Set logical level for RTS pin equal to 0 after sending: */
      scp->flags &= ~(SER_RS485_RTS_AFTER_SEND);
  }


void
receive_while_send (int fd, bool receive, struct serial_rs485 *scp)
  {
    printf ("%s receive while sending\n", receive ? "Enabling" : "Disabling");

    if (receive)

      /* Enable receiving data while sending: */
      scp->flags |= SER_RS485_RX_DURING_TX;
    else

      /* Disable receiving data while sending: */
      scp->flags &= ~(SER_RS485_RX_DURING_TX);
  }

void
rts_delay_before_send (int fd, int delay, struct serial_rs485 *scp)
  {
    printf ("Delaying RTS before send by %d ms\n", delay);

    scp->delay_rts_before_send = delay;
  }

int
rts_delay_after_send (int fd, int delay, struct serial_rs485 *scp)
  {
    printf ("Delaying RTS after send by %d ms\n", delay);

    scp->delay_rts_after_send = delay;
  }

int
main(int argc, char *argv[])
{
  static struct option long_options[] =
    {
      {"device", required_argument, NULL, 'd'},
      {"mode", required_argument, NULL, 'm'},
      {"help", no_argument, NULL, 'h'},
      {"status", no_argument, NULL, 's'},
      {"rts-on-send", required_argument, NULL, 'o'},
      {"rts-after-send", required_argument, NULL, 'a'},
      {"receive-while-send", required_argument, NULL, 'r'},
      {"rts-delay-before-send", required_argument, NULL, 'x'},
      {"rts-delay-after-send", required_argument, NULL, 'y'},
      {0, 0, 0, 0},
    };
  struct serial_rs485 sc;
  char *device = NULL;
  char *pgm = strndup(argv[0], PATH_MAX);
  int c;
  int fd;
  bool status = false;

  while ((c = getopt_long (argc, argv, "a:d:hm:o:r:sx:y:", long_options, NULL)) != -1)
    switch (c) {
    case 0:
      break;
    case 'a':                   /* Set RTS after send (1 == high, 0 == low). */
      opts.rts_after_send.set = 1;
      opts.rts_after_send.value = atoi (optarg) == 0 ? false : true;
      break;
    case 'd':                   /* Set RS485 device. */
      device = strndup (optarg, DEVICE_MAX);
      break;
    case 'h':                   /* Show help, then exit. */
      usage (pgm);
    case 'm':                   /* Set RS485 mode (1 == enable, 0 == disable) */
      opts.mode.set = 1;
      opts.mode.value = atoi (optarg) == 0 ? false : true;
      break;
    case 'o':                   /* Set RTS on send (1 == high, 0 == low). */
      opts.rts_on_send.set = 1;
      opts.rts_on_send.value = atoi (optarg) == 0 ? false : true;
      break;
    case 'r':                   /* Set receive while sending (1 == enable,
                                   0 == disable). */
      opts.receive_while_send.set = 1;
      opts.receive_while_send.value = atoi (optarg) == 0 ? false : true;
      break;
    case 's':                   /* Get RS485 settings. */
      status = true;
      break;
    case 'x':                   /* Set RTS delay before send (in ms). */
      opts.rts_delay_before_send.set = 1;
      opts.rts_delay_before_send.value = atoi (optarg);
      break;
    case 'y':                   /* Set RTS delay after send (in ms). */
      opts.rts_delay_after_send.set = 1;
      opts.rts_delay_after_send.value = atoi (optarg);
      break;
    default:
      usage (pgm);
    }
  argv += optind;
  argc -= optind;

  if (argc > 0 || device == NULL)
    {
      usage (pgm);
    }

  /* Open serial device, e.g., `/dev/ttymxc1' */
  if ((fd = open (device, O_RDWR)) < 0)
    {
      fprintf (stderr, "%s\n", strerror(errno));
      exit (1);
    }

  printf ("Serial device: %s\n", device);

    if (ioctl (fd, TIOCGRS485, &sc) < 0) {
      fprintf (stderr, "TIOCGRS485: %s\n", strerror(errno));
      goto error;
    }

  if (status)
    {
      rs485_status (fd, &sc);
    }
  else
    {
      if (opts.mode.set)
        rs485_mode (fd, opts.mode.value, &sc);

      if (opts.rts_on_send.set)
        rts_on_send (fd, opts.rts_on_send.value, &sc);

      if (opts.rts_after_send.set)
          rts_after_send (fd, opts.rts_after_send.value, &sc);

      if (opts.receive_while_send.set)
          receive_while_send (fd, opts.receive_while_send.value, &sc);

      if (opts.rts_delay_before_send.set)
          rts_delay_before_send (fd, opts.rts_delay_before_send.value, &sc);

      if (opts.rts_delay_after_send.set)
          rts_delay_after_send (fd, opts.rts_delay_after_send.value, &sc);

      if (ioctl (fd, TIOCSRS485, &sc) < 0) {
        fprintf (stderr, "TIOCSRS485: %s\n", strerror(errno));
        goto error;
      }
    }

  if (close (fd) < 0) {
      fprintf (stderr, "%s\n", strerror(errno));
      goto error;
  }

  exit (0);

 error:
  exit (1);
}

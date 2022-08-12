#!/usr/bin/env python3
import os, re, glob

# Generate dictionary of gpiochips keyed by I2C address, e.g.,
#     gpiochip['i2c1@20'] => 'gpiochip7'
# and dictionary of gpiochip bases, e.g.,
#     gpiobase['gpiochip7'] => 496
gpiochip = {}
gpiobase = {}

for link in glob.glob('/sys/class/gpio/gpiochip*'):
    base = int(re.sub(r'.*/gpiochip', '', link))
    chip = re.sub(r'.*/', '', glob.glob(link + '/device/gpiochip*')[0])
    gpiobase[chip] = base
    path = os.readlink(link)
    match = re.match(r'.*\.i2c/i2c-([0-9]+)/\1-0*([1-9][0-9]*)', path)
    if match:
        i2c_addr = 'i2c' + match[1] + '@' + match[2]
        gpiochip[i2c_addr] = chip

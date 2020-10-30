#!/usr/bin/env node
/*
 * @(#) markov-pwgen.js
 *
 * Copyright © 2020, Revolution Robotics, Inc.
 *
 */
import { genMarkovPass } from '../index.js';
import parseArgs from 'minimist';

const pgm = process.argv[1].replace(/^.*\//, '');
const argv = parseArgs(process.argv.slice(2))

if (argv.help || argv.h) {
    console.log(`Usage: ${pgm} OPTIONS`);
    console.log(`OPTIONS (defaults are random within the given range):
  --count=N         Generate N hyphen-delimited passwords (default: 2)
  --order=N         Specify Markov chain order (default: 3 or 4)
  --minLength=N     Minimum password length (default: 3 or 4)
  --maxLength=N     Maximum password length (default: 6 or 7)
  --maxAttempts=N   Fail after N attempts to generate chain (default: 100)
  --allowDuplicates Allow dictionary passwords (default: false)`);
    process.exit(0);
}

const markovPass = genMarkovPass(argv);

if (markovPass.result.length < markovPass.options.count) {
    console.log(`${pgm}: Unable to generate password with given constraints.`);
    process.exit(1);
} else {
    console.log(markovPass.result.join('-'));
}

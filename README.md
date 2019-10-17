# md5_6502
### Speed-optimized MD5 hashing for MOS6502.

Just as the title says. I tried to strike a balance between code size and
performance, which resulted in around 2KB of code and around 1750 bytes/s
when hashing on a Commodore 64.

You will need cc65 (https://github.com/cc65/cc65) to build.

### How to use:

In order to calculate MD5 hash of a message:

1. Call `_md5_init`.
2. Call `_md5_next_block` for every 64-byte block of the message, passing a
   pointer to beginning of the block in A/X (lo/hi) and size of the block
   in Y. Only the final's block size can be smaller than 64 bytes!
3. Call `_md5_finalize`.
4. Find computed MD5 hash in 16 bytes starting at `_md5_hash`.

See `tests.s` for examples.


### Testing

Sure. Run `make test`. If it fails, you optimized too much.


### Did you say Commodore c64?

Yes. `make md5.prg` and have fun benchmarking.


### Author

Milek Smyk (firstlast on gmail)

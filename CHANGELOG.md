## Next

## 2.7.1
- fix fix File::EXCL flag usage

## 2.7.0
- add param flags for File.open
- fix File::EXCL flag

## 2.6.0
- fix rename not changing content
- add experimental flock

## 2.5.0
- Ensure separation of positional/kwargs for Kernel.open

## 2.4.0

- Add fakefs/irb to be able to use irb after activating fakefs

## 2.3.0

- Fix find globbing bug

## 2.2.0

- Fix Dir.open with yield issue

## 2.1.0

- Add fakefs/pry to be able to use pry after activating fakefs

## 2.0.0

- Drop `.exists?` in favor of `.exist?`

## 1.9.0

- Support ruby 3.2
- Drop support for EOL Rubies (2.4/2.5/2.6)

## 1.8.0

- Support ::File#readpartial

## 1.7.0

- Add .activate supports io_mocks

## 1.6.0

- Add File#binmode?

## 1.5.0

- Add File#binwrite

## 1.4.0

- Pathnam#glob + glob flags support

## 1.3.2

- Fix passed in escaped characters to not get doube-escaped

## 1.3.1

- Fix `Dir.glob` fails to return correct matches when a path contains plus sign(s)

## 1.2.3

- fix File.mv deleting when src and dest are the same

## 1.2.2

- Tempfile.create works without creating tempdir first

## 1.2.1

- fix deletion of file objects not working

## 1.2.0

- more ruby 2.7 fixes / warnings removed

## 1.1.0

- remote taint/untaint methods from Pathname
- support ruby 2.7

## 1.0.0

- No changes, this is a cosmetic release to signal stableness

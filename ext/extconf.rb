require 'mkmf'

dir_config('redland')

$LDFLAGS = [
  $LDFLAGS,
  ENV['LDFLAGS'],
  `pkg-config redland --libs`.strip
].join(' ')

$CFLAGS = [
  $CFLAGS,
  ENV['CFLAGS'],
  `pkg-config redland --cflags`.strip
].join(' ')

create_makefile('redland')

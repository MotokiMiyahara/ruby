# vim:set fileencoding=sjis ts=2 sw=2 sts=2 et:


# TODO
APP = 'H:\\tools\\at_picture_0_1_31_1\\at_picture.exe'

if $0 == __FILE__
  command = "#{APP} -n -c"
  10.times do
    system "#{command}"
  end
  %Q{aaaa\a\b }
  "aaa\a"
end


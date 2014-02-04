
require 'tk'

t = TkText.new('width' => 30, 'height' => 20).pack
img = TkPhotoImage.new('file' => "a.gif")
TkTextImage.new(t, 'end', 'image' => img)
Tk.mainloop

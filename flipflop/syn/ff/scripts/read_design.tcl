set SRC_PATH  "../../../source/design"

if {[file exists PKG_SV_FILES]} {
   set PKG_SV_FILES   [concat [glob $SRC_PATH/*/*pkg*]]
   set MAIN_SV_FILES  [concat $PKG_SV_FILES \
                      [glob $SRC_PATH/$DESIGN/*.*v]]
} else {
   set MAIN_SV_FILES  [glob $SRC_PATH/$DESIGN/*.*v]
}

foreach file $MAIN_SV_FILES {
   read_hdl -language sv  $file
}

// The iosMath fonts for the math game, built into the tweak so it works as a single dylib
// (no resource bundle has to be added to the app). Written to the app's cache on first use.

.section __DATA,__const

.globl _psi_font_latinmodern_otf
.globl _psi_font_latinmodern_otf_end
.p2align 4
_psi_font_latinmodern_otf:
    .incbin "modules/iosMath/iosMath/fonts/latinmodern-math.otf"
_psi_font_latinmodern_otf_end:

.globl _psi_font_latinmodern_plist
.globl _psi_font_latinmodern_plist_end
.p2align 4
_psi_font_latinmodern_plist:
    .incbin "modules/iosMath/iosMath/fonts/latinmodern-math.plist"
_psi_font_latinmodern_plist_end:

.globl _psi_font_italic_otf
.globl _psi_font_italic_otf_end
.p2align 4
_psi_font_italic_otf:
    .incbin "modules/iosMath/iosMath/fonts/lmroman10-italic.otf"
_psi_font_italic_otf_end:

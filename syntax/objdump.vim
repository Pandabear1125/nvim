" Syntax highlighting for objdump disassembly output.
if exists("b:current_syntax")
  finish
endif

syn case match

" File and section headers.
syn match objdumpFileFormat  /^.*file format.*$/
syn match objdumpSectionHead /^Disassembly of section .*:$/
syn match objdumpSymTabHead  /^SYMBOL TABLE:$/

" Symbol table rows:  60001400 l     F .text.code<Tab>00000012 memory_copy
syn match objdumpSymLine /^\x\{8} [lgu!* ][w ][C ][W ][Ii ][dD ][FfO ] \S.*$/
      \ contains=objdumpSymValue,objdumpSymFlags,objdumpSymSection,objdumpSymSize,objdumpSymName
syn match objdumpSymValue   /^\x\{8}/ contained
syn match objdumpSymFlags   /\%(^\x\{8} \)\@<=.\{7}/ contained
syn match objdumpSymSection /\%(^\x\{8} .\{7} \)\@<=\S\+/ contained
syn match objdumpSymSize    /\%(\t\)\@<=\x\{8}\ze / contained
syn match objdumpSymName    /\%(\t\x\{8} \)\@<=.*$/ contained

" Function label:  60001400 <memory_copy>:
syn match objdumpLabelLine /^\x\+ <.\{-}>:$/ contains=objdumpLabelAddr,objdumpLabelName
syn match objdumpLabelAddr /^\x\+/ contained
syn match objdumpLabelName /<.\{-}>/ contained

" Instruction rows:  60001404:<Tab>f851 3b04 <Tab>ldr.w<Tab>r3, [r1], #4
syn match objdumpAddrCol /^\s*\x\+:/ nextgroup=objdumpBytes skipwhite
syn match objdumpBytes /\%(\x\x\+ \?\)\+/ contained
      \ nextgroup=objdumpMnemonic,objdumpDirective skipwhite
syn match objdumpMnemonic /[a-z][a-z0-9._]*/ contained
      \ nextgroup=objdumpOperands skipwhite
syn match objdumpDirective /\.[a-z][a-z0-9._]*/ contained
      \ nextgroup=objdumpOperands skipwhite
syn match objdumpOperands /.*$/ contained
      \ contains=objdumpComment,objdumpRef,objdumpImm,objdumpHex,objdumpReg,objdumpBracket

" Operand and comment tokens.
syn match objdumpComment /@.*$/ contains=objdumpRef,objdumpHex
syn match objdumpRef     /<[^>]*>/ contained
syn match objdumpImm     /#-\?\%(0x\)\?\x\+/ contained
syn match objdumpHex     /\<0x\x\+\>/ contained
syn match objdumpBracket /[[\]{}]/ contained
syn keyword objdumpReg contained
      \ r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15
      \ sp lr pc sl fp ip sb

hi def link objdumpFileFormat  PreProc
hi def link objdumpSectionHead Title
hi def link objdumpSymTabHead  Title
hi def link objdumpSymValue    Number
hi def link objdumpSymFlags    Type
hi def link objdumpSymSection  Statement
hi def link objdumpSymSize     Number
hi def link objdumpSymName     Identifier
hi def link objdumpLabelAddr   Number
hi def link objdumpLabelName   Function
hi def link objdumpAddrCol     LineNr
hi def link objdumpBytes       Comment
hi def link objdumpMnemonic    Statement
hi def link objdumpDirective   PreProc
hi def link objdumpReg         Identifier
hi def link objdumpImm         Constant
hi def link objdumpHex         Number
hi def link objdumpRef         Special
hi def link objdumpBracket     Delimiter
hi def link objdumpComment     Comment

let b:current_syntax = "objdump"

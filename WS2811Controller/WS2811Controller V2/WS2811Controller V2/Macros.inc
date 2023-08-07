/*
 * Macros.inc
 *
 *  Created: 28.06.2013 12:22:25
 *   Author: Tom
 */ 

  ;Register für RTemporäre Werte
 .def RTemp = r17



.macro ReadPort  ;(Port, Register) 
  .if @0 < 0x40
	in	@1, @0
  .else
  	lds	@1, @0
  .endif
.endm

.macro WritePort   ;(Port, Register)
  .if @0 < 0x40
	out	@0, @1
  .else
  	sts	@0, @1
  .endif
.endm


.macro WritePortValue ;(Port,Value)
  ldi Rtemp,@1
  WritePort @0, RTemp
.endm

.MACRO SetPortBit ;(Port, Bit)
        .if @0<0x20
		  sbi @0,@1
		.else
		  ReadPort @0,RTemp
		  ori RTemp,(1<<@1)
		  WritePort @0,RTemp
		.endif
.ENDMACRO

.MACRO ClearPortBit ;(Port, Bit)
        .if @0<0x20
		  cbi @0,@1
		.else
		  ReadPort @0,RTemp
		  andi RTemp,-(1<<@1)
		  WritePort @0,RTemp
		.endif
.ENDMACRO



 

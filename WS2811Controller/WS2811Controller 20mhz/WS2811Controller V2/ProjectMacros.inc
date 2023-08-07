/*
 * ProjectMacros.inc
 *
 *  Created: 28.06.2013 14:30:12
 *   Author: Tom
 */ 


.macro WaitUs ;(Number of microseconds)
	ldi RTemp,@0 ; 1 Takt
    WaitUsLoop: ; Schleifenbeginn
	  nop	;1 
	  nop	;1
	  nop	;1
	  nop	;1
	  nop	;1 
	  nop	;1
	  nop	;1
	  nop	;1
	  nop	;1 
	  nop	;1
	  nop	;1
	  nop	;1
	  nop	;1 
	  nop	;1
	  nop	;1
	  nop	;1
 	  nop														;1  additional nop for 20mhz
	  nop														;1  additional nop for 20mhz
	  nop														;1  additional nop for 20mhz
	  nop														;1  additional nop for 20mhz
	  nop	;1 = total 13 cycles
	  dec RTemp ; 1 Takte
	brne WaitUsLoop ; 2 Takte wenn nicht Null, 1 Takt bei Null
.endm


.macro FT245_ClearInputBuffer
  nop
  nop
  sbic FT245_StatusPin, FT245_RxfBit
  rjmp FT245_ClearInputBufferExit
  FT245_ClearInputBufferLoop:
  cbi FT245_StatusPort, FT245_RdBit
  nop
  nop
  sbi FT245_StatusPort, FT245_RdBit
  nop
  nop
  sbis FT245_StatusPin, FT245_RxfBit
  rjmp FT245_ClearInputBufferLoop
  FT245_ClearInputBufferExit:
.endm


.macro FT245_SetInput
  //WritePortValue FT245_DataPort,0x00
  WritePortValue FT245_DataDDR,0x00
.endm

.macro FT245_SetOutput
  WritePortValue FT245_DataDDR,0xff
.endm

.macro FT245_WaitForRead 
  FT245_WaitForReadLoop:
         sbic FT245_StatusPin, FT245_RxfBit
	 rjmp FT245_WaitForReadLoop
.endm

.macro FT245_WaitForRead_PayLoad ;(Payload)
  FT245_WaitForReadLoop:
         rcall @0 
         sbic FT245_StatusPin, FT245_RxfBit
	 rjmp FT245_WaitForReadLoop
.endm


.macro FT245_ReadByte  ;(Register) 

	 cbi FT245_StatusPort, FT245_RdBit
	 nop
     nop
	 in @0, FT245_DataPin
	 sbi FT245_StatusPort, FT245_RdBit
.endm



.macro FT245_WaitForWrite
  FT245_WaitForWriteLoop:
         sbic FT245_StatusPin, FT245_TxeBit
	 rjmp FT245_WaitForWriteLoop
.endm


.macro FT245_WriteByte;(Register)

	 sbi FT245_StatusPort, FT245_WrBit
	 out FT245_DataPort,@0
	 cbi FT245_StatusPort, FT245_WrBit
.endm


.macro FT245_SendByte;(Register)
  FT245_WaitForWrite
  FT245_SetOutput
  FT245_WriteByte @0
  FT245_SetInput
.endm

.macro FT245_SendAck
  FT245_WaitForWrite
  FT245_SetOutput
  ldi RTemp,'A'
  FT245_WriteByte RTemp
  FT245_SetInput
.endm

.macro FT245_SendNAck
  FT245_WaitForWrite
  FT245_SetOutput
  ldi RTemp,'N'
  FT245_WriteByte RTemp
  FT245_SetInput
.endm


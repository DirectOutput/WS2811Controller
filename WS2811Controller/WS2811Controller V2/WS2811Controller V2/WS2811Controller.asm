

 .include "m644Pdef.inc" 
 .LISTMAC
 ;********************************************************
 ;** Constants
 ;********************************************************

 .equ DataBufferSize=SRAM_SIZE-64

 ;********************************************************
 ;** Ports
 ;********************************************************

 ;FT245RL
 ;Use ports with adresses<0x20 for the FT245 to allow for most efficient communication
 .EQU FT245_DataPort = PORTC
 .equ FT245_DataPin = PINC
 .equ FT245_DataDDR = DDRC

 .equ FT245_StatusPin=PIND
 .equ FT245_StatusPort=PORTD
 .equ FT245_StatusDDR=DDRD

 .equ FT245_TXEBit=6
 .equ FT245_RXFBit=5
 .equ FT245_WRBit=4
 .equ FT245_RDBit=7

 ;Leds
 .equ Led_DDR=DDRA
 .equ Led_Port=PORTA
 .equ Led0_Bit=0
 .equ Led1_Bit=1

 ;WS2811 Data Line
 .equ WS2811_DDR=DDRD
 .equ WS2811_Port=PORTD
 .equ WS2811_Bit=1;



 ;********************************************************
 ;** Registers
 ;********************************************************

 ;R17 is RTemp (defined in macros.inc)

 .def RBufferLoopCounter=R24
 .def RBufferLoopCounterHigh=R25
 
 .def RCommandByte=R18
 
 .def RData=R0
 
 ;*******************************************************
 ;** Calculated constants
 ;*******************************************************
 
 

 ;*******************************************************
 ;** Macros
 ;*******************************************************
 

 .include "macros.inc" 
 .include "ProjectMacros.inc"

;*********************************************
;** Init
;*********************************************
.CSEG
Init:	
  ;Set IO direction for FT245 data port (input)
  FT245_SetInput

  ;Set IO Directtion for FT245 status connectors
  SetPortBit FT245_StatusDDR,FT245_WRBit
  SetPortBit FT245_StatusDDR,FT245_RDBit
  ClearPortBit FT245_StatusDDR,FT245_RxfBit
  ClearPortBit FT245_StatusDDR,FT245_TXEBit

  ;Set Rd and WR to initial values
  SetPortBit FT245_StatusPort,FT245_RDBit
  SetPortBit FT245_StatusPort,FT245_WRBit


  
  ;Empty input buffer
  FT245_ClearInputBuffer
  
  ;Set led port bits to output & turn leds off
  SetPortBit Led_DDR,Led0_Bit
  SetPortBit Led_DDR,Led1_Bit
  SetPortBit Led_Port,Led0_Bit
  SetPortBit Led_Port,Led1_Bit

  ;Set IO direction to output for WS2811 connector
  SetPortBit WS2811_DDR,WS2811_Bit
  ClearPortBit WS2811_Port,WS2811_Bit
  
  Main:
     FT245_WaitForRead
	 
	 FT245_ReadByte RCommandByte

	 //FT245_SendByte RCommandByte
	 RCall Processcommand

  rjmp Main




  ProcessCommand:
    subi RCommandByte,MinCommandByte
	cpi RCommandByte,(MaxCommandByte-MinCommandByte-1)
	brsh ProcessCommand_NoValidCommand
	ldi ZL,low(ProcessCommandJumps);
	ldi ZH,high(ProcessCommandJumps);
	add ZL,RCommandByte
	ldi RCommandByte,0
	adc ZH,RCommandByte
	ijmp

  ProcessCommand_NoValidCommand:
  rjmp UnknownCommand

  ;Use RJMP for the process command jumps. If the JMP statement has to be used to accomodate longer jumps, 
  ;the added command byte value has to be shifted left one position to support the JMP statement (4 byte vs 2 bytes) 
  ;and the calculation for MaxCommandByte has to be adjusted as well.
  ;The procedures called in the following section must all end with Ret
  ProcessCommandJumps:   
    rjmp UnknownCommand		;A
	rjmp UnknownCommand		;B
    rjmp ClearDataBuffer	;C
    rjmp UnknownCommand		;D
    rjmp UnknownCommand		;E
    rjmp UnknownCommand		;F
    rjmp UnknownCommand		;G
    rjmp UnknownCommand		;H
    rjmp UnknownCommand		;I
    rjmp UnknownCommand		;J
    rjmp UnknownCommand		;K
    rjmp UnknownCommand		;L
    rjmp UnknownCommand		;M
    rjmp UnknownCommand		;N
    rjmp OutputData			;O
    rjmp UnknownCommand		;P
    rjmp UnknownCommand		;Q
    rjmp ReceiveData		;R
    rjmp UnknownCommand		;S
    rjmp UnknownCommand		;T
    rjmp UnknownCommand		;U
    rjmp UnknownCommand		;V
    rjmp UnknownCommand		;W
    rjmp UnknownCommand		;X
    rjmp UnknownCommand		;Y
    rjmp UnknownCommand		;Z
    
  ;The folowing label must follow immediately after the jump statements. It is used to detemine the max command number  
  ProcessCommandJumpsEnd:
  .equ MinCommandByte = 'A'
  .equ MaxCommandByte = 'Z'


;Is called when a unknown command byte has been received
UnknownCommand:
  FT245_SendNack
ret

;Clears the data buffer
ClearDataBuffer:
  SetPortBit Led_Port,Led0_Bit
   
  FT245_SendAck
  LDI XH,HIGH(DataBuffer)
  LDI XL,LOW(DataBuffer)

  ldi RBufferLoopCounterHigh,HIGH(DataBufferSize) 
  ldi RBufferLoopCounter,LOW(DataBufferSize)

  ldi Rtemp,0
  ClearDataBufferLoop: 
     ST X+,RTemp
	 sbiw RBufferLoopCounter,1
   brne ClearDataBufferLoop 

  ClearPortBit Led_Port,Led0_Bit

ret

//Receives data from the FT245
ReceiveData:
  SetPortBit Led_Port,Led0_Bit
  //Read number of bytes to receive
  FT245_WaitForRead
  FT245_ReadByte RBufferLoopCounterHigh
  nop
  nop
  FT245_WaitForRead
  FT245_ReadByte RBufferLoopCounter
      

    //Load starting address of data buffer
  LDI XH,HIGH(DataBuffer)
  LDI XL,LOW(DataBuffer)

  ReceiveData_Loop:
    FT245_WaitForRead
    FT245_ReadByte RData
	st x+,RData
  //     FT245_SendByte RData
  //    FT245_SendByte RBufferLoopCounterHigh
//	  FT245_SendByte RBufferLoopCounter
  
  sbiw RBufferLoopCounter,1
  brne ReceiveData_Loop 
  FT245_SendAck

  ClearPortBit Led_Port,Led0_Bit

ret


;Sends data to the WS2811 based Led strip. Expects 2 bytes with the number of bytes to be sent (high byte first, low byte second)
OutputData:
    SetPortBit Led_Port,Led0_Bit
  //Read number of bytes to send
  FT245_WaitForRead
  FT245_ReadByte RBufferLoopCounterHigh
  nop
  nop
  FT245_WaitForRead
  FT245_ReadByte RBufferLoopCounter


  //Load starting address of data buffer
  LDI XH,HIGH(DataBuffer)
  LDI XL,LOW(DataBuffer)


	Channel_loop_800:
		ld RData,x+                                                ;1 to 3 (likely 2)
		nop			                                            ;1

		;-------- Bit0
		lsl RData                                                  ;1
		brcc Bit0_0_800                                         ;1 or 2 on branch


		Bit0_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		rjmp Bit0_Tail_800                                      ;2

		Bit0_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		Bit0_tail_800:
		Nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

			;-------- Bit1
		lsl RData                                                  ;1
		brcc Bit1_0_800                                         ;1 or 2 on branch


		Bit1_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		rjmp Bit1_Tail_800                                      ;2

		Bit1_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		Bit1_tail_800:
		Nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

			   ;-------- Bit2
		lsl RData                                                  ;1
		brcc Bit2_0_800                                         ;1 or 2 on branch


		Bit2_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		rjmp Bit2_Tail_800                                      ;2

		Bit2_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		Bit2_tail_800:
		Nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1


			;-------- bit3
		lsl RData                                                  ;1
		brcc bit3_0_800                                         ;1 or 2 on branch


		Bit3_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		rjmp bit3_Tail_800                                      ;2

		Bit3_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		Bit3_tail_800:
		Nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1


			;-------- bit4
		lsl RData                                                  ;1
		brcc bit4_0_800                                         ;1 or 2 on branch


		Bit4_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		rjmp bit4_Tail_800                                      ;2

		Bit4_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		Bit4_tail_800:
		Nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1


			;-------- bit5
		lsl RData                                                  ;1
		brcc bit5_0_800                                         ;1 or 2 on branch


		Bit5_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		rjmp bit5_Tail_800                                      ;2

		Bit5_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		Bit5_tail_800:
		Nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

			   ;-------- bit6
		lsl RData                                                  ;1
		brcc bit6_0_800                                         ;1 or 2 on branch


		Bit6_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		rjmp bit6_Tail_800                                      ;2

		Bit6_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		Bit6_tail_800:
		Nop                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

			;-------- bit7
		lsl RData                                                  ;1
		brcc bit7_0_800                                         ;1 or 2 on branch


		Bit7_1_800:
		NOP                                                     ;1 extra cycle since the previous branch uses 2 cycles on branch

		Sbi WS2811_Port, WS2811_Bit                                           ;2  High 10 cycles

		SBIW r24,1                                              ;2
		breq bit7_islasthighbit_800                             ;1 or 2 on branch

		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		cbi WS2811_Port, WS2811_Bit                                           ;2  Low


		Rjmp CHANNEL_LOOP_800                                   ;2

		Bit7_islasthighbit_800:
		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1
		NOP
		NOP                                                     ;2
		cbi WS2811_Port, WS2811_Bit                                           ;2  Low

		rjmp leave_loop_800                                     ;2


		Bit7_0_800:
		Sbi WS2811_Port, WS2811_Bit                                           ;2   High 4 cycles
		nop                                                     ;1
		NOP                                                     ;1

		cbi WS2811_Port, WS2811_Bit                                           ;2  Low

		NOP                                                     ;1
		NOP                                                     ;1
		NOP                                                     ;1

		SBIW RBufferLoopCounter,1                               ;2
		breq Leave_loop_800                                     ;1 or 2 on branch

		RJMP CHANNEL_LOOP_800                                   ;2


    Leave_loop_800:

    FT245_SendAck

    WaitUs 65
    ClearPortBit Led_Port,Led0_Bit

ret




.DSEG

DataBuffer: .BYTE DataBufferSize
 

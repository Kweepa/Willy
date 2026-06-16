; ==============================================================================
; VIC-20 1541 RESIDENT FASTLOADER & INTERMITTENT ROOM FETCHER
; ==============================================================================

; ------------------------------------------------------------------------------
; PART 1: 1541 DRIVE PAYLOAD
; This code is uploaded to the drive's RAM at $0300 via the KERNAL before SEI.
; ------------------------------------------------------------------------------
.segment "DRIVECODE"
* = $0300

VIA1_PRA = $1800        ; 1541 Serial Port (Bit 1=DAT OUT, Bit 3=CLK OUT, Bit 7=ATN IN)
JOB_CMD  = $01          ; 1541 Job 1 Command Register
JOB_TRK  = $09          ; 1541 Job 1 Track
JOB_SEC  = $0A          ; 1541 Job 1 Sector
BUFFER   = $0400        ; 1541 Job 1 Memory Buffer

DriveStart:
DriveIdle:
    ; 1. Command Phase: Count ATN pulses to get the Room ID (0-63)
    ldx #$00            ; Pulse count
.wait_low:
    lda VIA1_PRA
    bmi .wait_low       ; Wait for ATN to go active (LOW bus = bit 7 is 0)
.wait_high:
    lda VIA1_PRA
    bpl .wait_high      ; Wait for ATN to go inactive (HIGH bus = bit 7 is 1)
    inx                 ; Register 1 pulse

    ; Wait for another pulse or timeout (signaling command is done)
    ldy #$80            ; Timeout delay
.timeout:
    lda VIA1_PRA
    bpl .got_pulse      ; If it goes low again, we got another pulse
    dey
    bne .timeout
    
    ; Timeout reached, command finished
    dex                 ; Subtract the +1 offset (so 1 pulse = Room 0)
    
    ; 2. Fetch Track and Sector from Lookup Tables (3 rooms per track layout)
    lda TrackLUT,x
    sta JOB_TRK
    lda SectorLUT,x
    sta JOB_SEC

    ; 3. Transmit 1450 bytes (5 full sectors + 170 bytes)
    ldy #$05            ; 5 full sectors (1280 bytes)
.send_full_sectors:
    jsr ReadSector      
    ldx #$00            ; X=0 means 256 bytes
    jsr SendBuffer
    inc JOB_SEC         ; Move to next sector
    dey
    bne .send_full_sectors

    ; Send final partial sector (170 bytes)
    jsr ReadSector
    ldx #170            ; Send 170 bytes ($AA)
    jsr SendBuffer
    
    jmp DriveIdle       ; Return to idle state for next intermittent load

; -- Drive Subroutines --

ReadSector:
    lda #$80            ; Execute Job (Read Sector)
    sta JOB_CMD
.wait_job:
    lda JOB_CMD
    bmi .wait_job       ; When MSB clears, 1541 ROM finished reading
    rts

SendBuffer:
    sty $06             ; Save Y
    ldy #$00
.send_loop:
    lda BUFFER,y
    jsr SendByte2Bit
    iny
    dex
    bne .send_loop
    ldy $06             ; Restore Y
    rts

SendByte2Bit:
    ; Split A into 4 bit-pairs, pre-calculate VIA outputs into ZP
    stx $07             ; Save X
    tax
    and #$03
    sty $08
    tay
    lda BitLUT,y
    sta $05             ; Bits 1/0
    
    txa
    lsr
    lsr
    and #$03
    tay
    lda BitLUT,y
    sta $04             ; Bits 3/2

    txa
    lsr
    lsr
    lsr
    lsr
    and #$03
    tay
    lda BitLUT,y
    sta $03             ; Bits 5/4

    txa
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    tay
    lda BitLUT,y
    sta $02             ; Bits 7/6
    ldy $08             ; Restore Y

    ; Transmit cycle-matched to the VIC-20
    lda $02
    sta VIA1_PRA        ; Send 7/6
    nop                 ; Padding to match VIC's 13-cycle gap
    nop
    nop

    lda $03
    sta VIA1_PRA        ; Send 5/4
    nop                 ; Padding to match VIC's 16-cycle gap
    nop
    nop
    nop

    lda $04
    sta VIA1_PRA        ; Send 3/2
    nop                 ; Padding to match VIC's 16-cycle gap
    nop
    nop
    nop

    lda $05
    sta VIA1_PRA        ; Send 1/0

    ; Wait for VIC-20 to ACK by pulsing ATN
.wait_ack1:
    lda VIA1_PRA
    bmi .wait_ack1
.wait_ack2:
    lda VIA1_PRA
    bpl .wait_ack2

    ldx $07             ; Restore X
    rts

; Translates %00, %01, %10, %11 into inverted CLK(bit 3)/DAT(bit 1) bits
BitLUT:
    .byte %00001010, %00001000, %00000010, %00000000 

; Tables for 63 rooms (Expand to 63 bytes each). Layout: 3 rooms per track.
TrackLUT:
    .byte 1, 1, 1, 2, 2, 2, 3, 3, 3 ; ...
SectorLUT:
    .byte 0, 6, 12, 0, 6, 12, 0, 6, 12 ; ...
DriveEnd:


; ------------------------------------------------------------------------------
; PART 2: VIC-20 INITIAL BOOTSTRAPPER (Loaded at $1000 initially)
; ------------------------------------------------------------------------------
.segment "BOOTSTRAP"
* = $1000

    ; KERNAL vectors
    SETLFS  = $FFBA
    SETNAM  = $FFBD
    OPEN    = $FFC0
    CHKOUT  = $FFC9
    BSOUT   = $FFD2
    CLRCHN  = $FFCC

    ; 1. Upload Drive Code via KERNAL
    lda #$01
    ldx #$08            ; Drive 8
    ldy #$0F            ; Command Channel
    jsr SETLFS
    lda #MW_Len
    ldx #<MW_Cmd
    ldy #>MW_Cmd
    jsr SETNAM
    jsr OPEN
    ldx #$01
    jsr CHKOUT
    
    ldy #$00
.send_drive_payload:
    lda $0300,y         ; Assuming payload was assembled here in memory
    jsr BSOUT
    iny
    cpy #(DriveEnd - DriveStart)
    bne .send_drive_payload
    jsr CLRCHN

    ; 2. Execute Drive Code (M-E $0300)
    ; (Standard M-E execution omitted for brevity, identical KERNAL usage to above)
    
    ; 3. Lockdown and Relocate Fastloader
    sei                 ; KILL INTERRUPTS. KERNAL is now dead.
    
    ldx #$00
.copy_loader:
    lda ResidentLoader,x
    sta $0200,x
    inx
    cpx #(ResidentEnd - ResidentLoader)
    bne .copy_loader
    
    ; 4. Jump to the newly resident loader to pull the main game
    jmp $0200

MW_Cmd:
    .byte "M-W"
    .word $0300
    .byte (DriveEnd - DriveStart)
MW_Len = * - MW_Cmd


; ------------------------------------------------------------------------------
; PART 3: VIC-20 RESIDENT LOADER ($0200)
; ------------------------------------------------------------------------------
.segment "RESIDENT"
ResidentLoader:
.logical $0200

    ; Setup initial game load ($1000 - $1FFF)
    lda #$10
    sta $FC
    lda #$00
    sta $FB
    
    ; Load 16 pages (4096 bytes)
    ldx #$10
    ldy #$00
.load_game_page:
    jsr ReadByte
    sta ($FB),y
    iny
    bne .load_game_page
    inc $FC
    dex
    bne .load_game_page
    
    ; Hand off to the main game
    jmp $1000

; --- High Speed Receive ---
ReadByte:
    ; Sync: Wait for 1541 to put first bits on bus (CLK goes low)
.wait_sync:
    lda $9111
    and #$01
    bne .wait_sync

    ; Read Bits 7/6  (13 cycles)
    lda $9111
    and #$03
    asl
    asl
    sta $FE

    ; Read Bits 5/4  (16 cycles)
    lda $9111
    and #$03
    ora $FE
    asl
    asl
    sta $FE

    ; Read Bits 3/2  (16 cycles)
    lda $9111
    and #$03
    ora $FE
    asl
    asl
    sta $FE

    ; Read Bits 1/0  (9 cycles)
    lda $9111
    and #$03
    ora $FE

    ; ACK: Pulse ATN to tell 1541 we are done
    ldx $9121
    txa
    ora #$80            ; Pull ATN LOW
    sta $9121
    txa
    and #$7F            ; Release ATN HIGH
    sta $9121
    
    rts

ResidentEnd:
.here


; ------------------------------------------------------------------------------
; PART 4: VIC-20 INTERMITTENT LOAD ROUTINE (Include in your Main Game)
; ------------------------------------------------------------------------------
.segment "GAMECODE"
; * = $xxxx (Wherever you put your game routines)

; FetchRoom:
; Fetches 1450 bytes for a room.
; Expects: A = Room ID (0-63), Zero Page $FB/$FC = Target Address
FetchRoom:
    tax
    inx                 ; Convert Room ID to pulse count (Room 0 = 1 pulse)

    ; 1. Send Command (Pulse Count Protocol via ATN line)
.pulse_loop:
    lda $9121
    ora #$80            ; ATN LOW
    sta $9121
    nop                 ; Slight delay for 1541 to register
    nop
    lda $9121
    and #$7F            ; ATN HIGH
    sta $9121
    
    ; Delay between pulses
    ldy #$10
.pulse_delay:
    dey
    bne .pulse_delay
    
    dex
    bne .pulse_loop

    ; 2. Read 1450 bytes using the Resident Loader at $0200
    ldx #$05            ; 5 full pages (1280 bytes)
    ldy #$00
.read_pages:
    jsr $0200 + (ReadByte - ResidentLoader) ; Call resident ReadByte directly
    sta ($FB),y
    iny
    bne .read_pages
    inc $FC
    dex
    bne .read_pages

    ldx #$AA            ; Remaining 170 bytes
.read_partial:
    jsr $0200 + (ReadByte - ResidentLoader)
    sta ($FB),y
    iny
    dex
    bne .read_partial

    rts
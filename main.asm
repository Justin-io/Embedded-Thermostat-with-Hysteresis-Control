# ----------------------------------------------------------
# Project: Embedded Thermostat - Simulation Mode
# ----------------------------------------------------------
# This version fixes the "Unknown System Call 5" error.
# Instead of asking for user input, it reads test data from memory.
# This simulates a "Hardware In the Loop" test environment.

.data
    # 1. USER INTERFACE STRINGS
    prompt:     .string "Simulating Sensor Data...\n"
    heat_on:    .string ">> TEMP_LOW:  HEATER ON \n"
    heat_off:   .string ">> TEMP_HIGH: HEATER OFF\n"
    stable:     .string ">> STABLE:    NO CHANGE \n"
    separator:  .string "-----------------------\n"
    
    # 2. TEST DATA (Simulating Sensor Readings over time)
    # Sequence: Starts hot (22), cools down (18), heats back up (22)
    sensor_stream: .word 22, 21, 20, 19, 18, 18, 20, 21, 22
    stream_end:

.text
main:
    # ------------------------------------------------------
    # INITIALIZATION
    # ------------------------------------------------------
    li s0, 0        # System State: 0=OFF, 1=ON
    li s1, 19       # LOW_THRESHOLD  (Turn ON below this)
    li s2, 21       # HIGH_THRESHOLD (Turn OFF above this)

    # Load the address of our test data
    la s4, sensor_stream   # s4 = Current Read Address
    la s5, stream_end      # s5 = End Address

    # Print start message
    li a7, 4
    la a0, prompt
    ecall

control_loop:
    # ------------------------------------------------------
    # 1. READ SENSOR (From Memory Array instead of User)
    # ------------------------------------------------------
    # Check if we have reached the end of the test data
    beq s4, s5, program_exit

    # Load current temperature from memory
    lw s3, 0(s4)       # Load word at address s4 into s3
    addi s4, s4, 4     # Move pointer to next word (4 bytes)

    # ------------------------------------------------------
    # 2. PRINT CURRENT TEMP (For debugging visibility)
    # ------------------------------------------------------
    li a7, 1           # ECALL: Print Integer
    mv a0, s3          # Print the current temp
    ecall
    
    li a7, 4           # ECALL: Print String (formatting)
    la a0, separator
    ecall

    # ------------------------------------------------------
    # 3. HYSTERESIS CONTROL LOGIC
    # ------------------------------------------------------
    beqz s0, check_on_logic   # If state is OFF, check if we should turn ON

check_off_logic:
    # STATE is currently ON. Should we turn OFF?
    bgt s3, s2, do_turn_off   # If (temp > 21), turn off
    j do_nothing              # Else, maintain state

check_on_logic:
    # STATE is currently OFF. Should we turn ON?
    blt s3, s1, do_turn_on    # If (temp < 19), turn on
    j do_nothing              # Else, maintain state

do_turn_on:
    li s0, 1                  # Set State ON
    li a7, 4
    la a0, heat_on
    ecall
    j control_loop

do_turn_off:
    li s0, 0                  # Set State OFF
    li a7, 4
    la a0, heat_off
    ecall
    j control_loop

do_nothing:
    li a7, 4
    la a0, stable
    ecall
    j control_loop

program_exit:
    # End of simulation
    nop

VHDL code to implement virtual seven segment displays on a VGA screen.
Tested with a Papilio FPGA, should work on any platform due to the simplicity of the code.

Seven segment displays are useful for showing data, debug info such as addresses, etc.
Instead of using a physical expansion board (wing) which costs money and has a limited number of digits, this simply uses an existing VGA output on a wing to implement any number of seven segment displays limited only by the available screen real estate.

The position, size and color of each digit is configurable.
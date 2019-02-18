Verilog implementation of the HP saturn processor

licence: GPLv3 or later


timings:
           ___________   
reset:                |____________________________________________________
                ____      ____      ____      ____      ____      ____
clk :      ____|    |____|    |____|    |____|    |____|    |____|    |____
                          _________ _________ _________ _________ _________
counter:   ______________/____0____X____1____X____2____X____3____X____0____
                          _________                               _________
phase_0:   ______________|         |_____________________________|
                                    _________
phase_1:   ________________________|         |_____________________________
                                              _________
phase_2:   __________________________________|         |___________________
                                                        _________
phase_3:   ____________________________________________|         |_________

notes for using the ULX3S

Maybe linux ujprog won't find port because of insufficient priviledge. Either run ujprog as root or have udev rule:# this is for usb-serial tty device
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", \
MODE="664", GROUP="dialout"
this is for ujprog libusb access

ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", \
GROUP="dialout", MODE="666"


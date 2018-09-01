# predict
### _Jeff Francis <jeff@gritch.org>_

This is a library to talk to the predict API to extract satellite
orbit predictions. Obviously, it's a bit short on documentation, but
it follows the predict documenation almost perfectly.

http://www.qsl.net/kd2bd/predict.html

Here's a quick example. First, properly configure and start predict on your local machine. Make sure to include the "-s" flag telling it to turn on the API.:

```
jfrancis@desktop ~ $ predict -s
```

Now load the predict package and connect to the server (note than you can also connect to remote servers, as well as servers on non-standard ports - RTSL):

```
CL-USER> (ql:quickload :predict)
(ql:quickload :predict)
To load "predict":
  Load 1 ASDF system:
    predict
; Loading "predict"
[package predict]..
(:PREDICT)
CL-USER> (in-package :predict)
#<PACKAGE "PREDICT">
PREDICT> (connect-to-predict)
#<USOCKET:DATAGRAM-USOCKET {1007097CD3}>
PREDICT>
```

Start with asking predict for a list of satellites currently being tracked:

```
PREDICT> (get-list)
("HUBBLE" "ISS" "LO-19" "AO-91" "AO-92" "SO-50" "AO-85")
PREDICT>
```

You can get the current position of a satellite, and the data is returned as an object:

```
PREDICT> (describe (get-sat "AO-91"))
#<SATELLITE {10072EFE83}>
  [standard-object]

Slots with :INSTANCE allocation:
  NAME                           = "AO-91"
  TIMESTAMP                      = 1535761303
  LON                            = 73.39
  LAT                            = -82.21
  AZ                             = 171.99
  EL                             = -64.9
  NEXT-AOS-LOS                   = 1535787950
  FOOTPRINT                      = "5871.93"
  RANGE                          = 12313.15
  ALTITUDE                       = 741.01
  VELOCITY                       = 7.44
  ORBIT-NUMBER                   = 4231
  IN-SUNLIGHT                    = T
  VISIBLE                        = NIL
  ORBITAL-PHASE                  = 246.23
  ECLIPSE-DEPTH                  = -15.07
  SQUINT                         = NIL
; No value
PREDICT>
```

Likewise, try each of the various functions in the predict documentation, located here:

https://github.com/koansys/predict/tree/master/clients/samples

Each function requires the same parameters as the docs, and returns the same data (though it's returned as objects).

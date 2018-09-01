;;;; predict.lisp

(in-package #:predict)

;; This global stores the socket object.
(defparameter *socket* nil)

(defclass satellite ()
  ((name :accessor name :initarg :name :initform nil)
   (timestamp :accessor timestamp :initarg :timestamp :initform nil)
   (lon :accessor lon :initarg :lon :initform nil)
   (lat :accessor lat :initarg :lat :initform nil)
   (az :accessor az :initarg :az :initform nil)
   (el :accessor el :initarg :el :initform nil)
   (next-aos-los :accessor next-aos-los :initarg :next-aos-los :initform nil)
   (footprint :accessor footprint :initarg :footprint :initform nil)
   (range :accessor range :initarg :range :initform nil)
   (altitude :accessor altitude :initarg :altitude :initform nil)
   (velocity :accessor velocity :initarg :velocity :initform nil)
   (orbit-number :accessor orbit-number :initarg :orbit-number :initform nil)
   (in-sunlight :accessor in-sunlight :initarg :in-sunlight :initform nil)
   (visible :accessor visible :initarg :visible :initform nil)
   (orbital-phase :accessor orbital-phase :initarg :orbital-phase :initform nil)
   (eclipse-depth :accessor eclipse-depth :initarg :eclipse-depth :initform nil)
   (squint :accessor squint :initarg :squint :initform nil)))

(defmethod above-the-horizon ((s satellite))
    "Is this satellite above the horizon?"
    (if (> (el s) 0) t nil))

(defclass sun-moon ()
  ((name :accessor name :initarg :name :initform nil)
   (timestamp :accessor timestamp :initarg :timestamp :initform nil)
   (azimuth :accessor azimuth :initarg :azimuth :initform nil)
   (elevation :accessor elevation :initarg :elevation :initform nil)
   (declination :accessor declination :initarg :declination :initform nil)
   (greenwich-hour-angle :accessor greenwich-hour-angle :initarg :greenwich-hour-angle :initform nil)
   (right-ascension :accessor right-ascension :initarg :right-ascension :initform nil)))

(defclass qth ()
  ((callsign :accessor callsign :initarg :callsign :initform nil)
   (lon :accessor lon :initarg :lon :initform nil)
   (lat :accessor lat :initarg :lat :initform nil)
   (altitude :accessor altitude :initarg :altitude :initform nil)))

(defun english-time (ts)
  "Convert a time_t timestamp to something local and readable."
  (format nil "~A" (local-time:unix-to-timestamp ts)))

(defun parse-float (float)
  "Parse a float from a string."
  (with-input-from-string (in float) (read in)))

(defun connect-to-predict (&key (host "127.0.0.1") (port 1210))
  "Connect to the server (well, not really, it's UDP). Defaults to
host localhost and port 1210. Uses global *socket*."
  (setf *socket*
	(usocket:socket-connect
	 host port
	 :protocol :datagram
	 :element-type '(unsigned-byte 8))))

(defun disconnect-from-predict ()
  "All done. Disconnect. Uses global *socket*."
  (usocket:socket-close *socket*))

(defun send-predict-command (cmd arg &optional (clean-up t))
  "Send a command to predict and clean up the response. If an optional
nil is provided, the response will be returned without cleaning it
up."
  (let ((send (if arg (format nil "~A ~A~%" cmd arg) (format nil "~A~%" cmd)))
	(array (make-array 1024 :element-type '(unsigned-byte 8) :initial-element 0)))
    (unwind-protect
	 (progn
	   (usocket:socket-send *socket* send (length send))
	   (usocket:socket-receive *socket* array (length array))
	   (if clean-up
	       (mapcar
		(lambda (s) (string-trim '(#\Space) s))
		(remove ""
			(split-sequence:split-sequence
			 #\Newline
			 (babel:octets-to-string
			  (remove-if (lambda (n) (= n 0)) array)))
			:test 'equal))
	       (string-trim
		'(#\Newline)
		(babel:octets-to-string
		 (remove-if (lambda (n) (= n 0)) array))))))))

(defun send-predict-command-multiline (cmd arg)
  "Send a command to predict and clean up the response. If an optional
nil is provided, the response will be returned without cleaning it
up."
  (let ((send (if arg (format nil "~A ~A~%" cmd arg) (format nil "~A~%" cmd)))
	(array (make-array 1024 :element-type '(unsigned-byte 8) :initial-element 0))
	(flag t))
    (unwind-protect
	 (progn
	   (usocket:socket-send *socket* send (length send))
		   (mapcar
		    (lambda (line)
		      (remove ""
			      (split-sequence:split-sequence #\Space (first line))
			      :test 'equal))
		    (remove nil
			    (loop while flag
			       do (usocket:socket-receive *socket* array (length array))
			       collect (progn
					 (setf flag (not (equal 26 (aref array 0))))
					 (when flag
					   (remove ""
						   (split-sequence:split-sequence
						    #\Newline
						    (babel:octets-to-string
						     (remove-if (lambda (n) (= n 0)) array)))
						   :test 'equal))))))))))

(defun get-time ()
  "Argument: none
   Purpose: To read the system date/time from the PREDICT server.
   Return value: Number of seconds since midnight UTC on January 1, 1970."
  (parse-integer (first (send-predict-command "GET_TIME" nil))))

(defun get-time$ ()
  "Argument: none
   Purpose: To read the system date/time from the PREDICT server.
   Return value: UTC Date/Time as an ASCII string."
  (first (send-predict-command "GET_TIME$" nil)))

(defun get-sat (sat)
  "Argument: satellite name or object number
   Purpose: To poll PREDICT for live tracking data.
   Return value: Newline ('\n') delimited string of tracking data."
  (let ((state (send-predict-command "GET_SAT" sat)))
    (make-instance 'satellite
		   :name (nth 0 state)
		   :timestamp (get-time)
		   :lon (parse-float (nth 1 state))
		   :lat (parse-float (nth 2 state))
		   :az (parse-float (nth 3 state))
		   :el (parse-float (nth 4 state))
		   :next-aos-los (parse-integer (nth 5 state))
		   :footprint (nth 6 state)
		   :range (parse-float (nth 7 state))
		   :altitude (parse-float (nth 8 state))
		   :velocity (parse-float (nth 9 state))
		   :orbit-number (parse-integer (nth 10 state))
		   :in-sunlight (if (or (equal "D" (nth 11 state)) (equal "V" (nth 11 state))) t nil)
		   :visible (if (equal "V" (nth 11 state)) t nil)
		   :orbital-phase (parse-float (nth 12 state))
		   :eclipse-depth (parse-float (nth 13 state))
		   :squint (if (equal "360.00" (nth 14 state))
			       nil
			       (parse-float (nth 14 state))))))

(defun get-doppler (sat)
  "Argument: satellite name or object number
   Purpose: To poll PREDICT for normalized Doppler shift information.
   Return value: Doppler shift information."
  (parse-float (first (send-predict-command "GET_DOPPLER" sat))))

(defun get-sun ()
  "Argument: none
   Purpose: To poll PREDICT for the Sun's current position.
   Return value: The Sun's positional data."
  (let ((state (send-predict-command "GET_SUN" nil)))
    (make-instance 'sun-moon
		   :name "SUN"
		   :timestamp (get-time)
		   :azimuth (parse-float (nth 0 state))
		   :elevation  (parse-float (nth 1 state))
		   :declination  (parse-float (nth 2 state))
		   :greenwich-hour-angle  (parse-float (nth 3 state))
		   :right-ascension  (parse-float (nth 4 state)))))

(defun get-moon ()
  "Argument: none
   Purpose: To poll PREDICT for the Moon's current position.
   Return value: The Moon's positional data."
  (let ((state (send-predict-command "GET_MOON" nil)))
    (make-instance 'sun-moon
		   :name "MOON"
		   :timestamp (get-time)
		   :azimuth (parse-float (nth 0 state))
		   :elevation  (parse-float (nth 1 state))
		   :declination  (parse-float (nth 2 state))
		   :greenwich-hour-angle  (parse-float (nth 3 state))
		   :right-ascension  (parse-float (nth 4 state)))))

(defun get-list ()
  "Argument: none
   Purpose: To poll PREDICT for the satellite names in the current database.
   Return value: String containing all satellite names in PREDICT's database."
  (send-predict-command "GET_LIST" nil))

(defun reload-tle ()
  "Argument: none
   Purpose: To force a re-read of PREDICT's orbital database file.
   Return value: none"
  (send-predict-command "RELOAD_TLE" nil)
  t)

(defun get-version ()
  "Argument: none
   Purpose: To determine what version of PREDICT is running as a server.
   Return value: String containing the version number."
  (first (send-predict-command "GET_VERSION" nil)))

(defun get-qth ()
  "Argument: none
   Purpose: To determine the groundstation location (QTH) information.
   Return value: String containing the info stored in the user's predict.qth file."
  (let ((state (send-predict-command "GET_QTH" nil)))
    (make-instance 'qth
		   :callsign (nth 0 state)
		   :lat (parse-float (nth 1 state))
		   :lon (parse-float (nth 2 state))
		   :altitude (parse-float (nth 3 state)))))

(defun get-tle (sat)
  "Argument: satellite name or catalog number
   Purpose: To read the Keplerian elements for a particular satellite.
   Return value: String containing NASA Two-Line Keplerian orbital data."
  (send-predict-command "GET_TLE" sat nil))

(defun get-sat-pos (sat start-timestamp &optional (end-timestamp nil))
  "Argument: satellite name or object number, starting date/time, ending
   date/time (optional).
   Purpose: To obtain the location of a satellite at a specified date/time.
   Return value: Sub-satellite point and local azimuth and elevation headings."
  (mapcar
   (lambda (s)
     (make-instance 'satellite
		    :name sat
		    :timestamp (parse-integer (nth 0 s))
		    :el (parse-integer (nth 4 s))
		    :az (parse-integer (nth 5 s))
		    :orbital-phase (parse-integer (nth 6 s))
		    :lat (parse-integer (nth 7 s))
		    :lon (parse-integer (nth 8 s))
		    :range (parse-float (nth 9 s))
		    :in-sunlight (if (or (equal "*" (nth 11 s)) (equal "+" (nth 11 s))) t nil)
		    :visible (if (equal "+" (nth 11 s)) t nil)))
   (if end-timestamp
       (send-predict-command-multiline "GET_SAT_POS"
				       (concatenate
					'string
					sat " "
					(format nil "~A" start-timestamp)
					" "
					(format nil "~A" end-timestamp)))
       (send-predict-command-multiline "GET_SAT_POS"
				       (concatenate
					'string
					sat " "
					(format nil "~A" start-timestamp))))))

(defun predict (sat &optional (start-timestamp nil))
  "Argument: satellite name or object number, starting date/time (optional).
   Purpose: To obtain orbital predictions for a single pass starting at the
   specified date/time, or earlier if the satellite is already in range.
   Return value: Satellite orbital prediction information."
  (mapcar
   (lambda (s)
     (make-instance 'satellite
		    :name sat
		    :timestamp (parse-integer (nth 0 s))
		    :el (parse-integer (nth 4 s))
		    :az (parse-integer (nth 5 s))
		    :orbital-phase (parse-integer (nth 6 s))
		    :lat (parse-integer (nth 7 s))
		    :lon (parse-integer (nth 8 s))
		    :range (parse-float (nth 9 s))
		    :in-sunlight (if (or (equal "*" (nth 11 s)) (equal "+" (nth 11 s))) t nil)
		    :visible (if (equal "+" (nth 11 s)) t nil)))
   (if start-timestamp
       (send-predict-command-multiline "PREDICT"
				       (concatenate
					'string
					sat " "
					(format nil "~A" start-timestamp)))
       (send-predict-command-multiline "PREDICT" sat))))
  
(defun get-mode ()
  "Argument: none
   Purpose: To determine PREDICT's current tracking mode.
   Return value: String containing program mode information."
  (first (send-predict-command "GET_MODE" nil)))

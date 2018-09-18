;;;; package.lisp

(defpackage #:predict
  (:use #:cl)
  (:export :satellite
	   :above-the-horizon
	   :sun-moon
	   :qth
	   :english-time
	   :parse-float
	   :connect-to-predict
	   :disconnect-from-predict
	   :send-predict-command
	   :send-predict-command-multiline
	   :get-time
	   :get-time$
	   :get-sat
	   :get-doppler
	   :get-sun
	   :get-moon
	   :get-list
	   :reload-tle
	   :get-version
	   :get-qth
	   :get-tle
	   :get-sat-pos
	   :predict
	   :get-mode
	   :chart-line
	   :sat-chart
	   :predict-all))

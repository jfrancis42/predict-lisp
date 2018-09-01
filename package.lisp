;;;; package.lisp

(defpackage #:predict
  (:use #:cl)
  (:export :satellite
	   :sun-moon
	   :qth
	   :english-time
	   :connect-to-predict
	   :disconnect-from-predict
	   :above-the-horizon
	   :get-time
	   :get-time$
	   :get-sat
	   :get-doppler
	   :get-sun
	   :get-moon
	   :reload-tle
	   :get-version
	   :get-qth
	   :get-tle
	   :get-sat-pos
	   :predict
	   :get-mode))

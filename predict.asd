;;;; predict.asd

(asdf:defsystem #:predict
  :description "A library to talk to the predict satellite prediction API"
  :author "Jeff Francis <jeff@gritch.org>"
  :license "MIT, see file LICENSE"
  :version "0.0.1"
  :serial t
  :depends-on (#:usocket
	       #:babel
	       #:local-time)
  :components ((:file "package")
               (:file "predict")))

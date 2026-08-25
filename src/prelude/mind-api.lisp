;;;; mind-api.lisp — session cortex API (implement fully in phases 6–7)
;;;; *mind/retrieved* is REPLACED each reify, never appended unbounded.

;; Placeholder specials — host/prelude will defparameter these on load.
;; (defparameter *mind/retrieved* nil)
;; (defparameter *mind/user* nil)
;; (defparameter *mind/ux* nil)
;; (defparameter *mind/pins* nil)
;; (defparameter *mind/max-pins* 40)

;;;; mind/reify! — REPLACE turn retrieval
;;;; (defun mind/reify! (&key retrieved merge-prefs) ...)

;;;; mind/note! mind/prefer! mind/fail! mind/skip! — phase 6–7

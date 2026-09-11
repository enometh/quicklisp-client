(defpackage #:ql-info
  (:export #:*version*))

;; set later
(defvar ql-info:*version* nil)

(defpackage #:ql-setup
  (:use #:cl)
  (:export #:*quicklisp-home*
           #:qmerge
           #:qenough
           #:setup-alt
           #:*registry*))

(in-package #:ql-setup)

;; set later
(defvar *quicklisp-home* nil)

(defun qmerge (pathname)
  "Return PATHNAME merged with the base Quicklisp directory."
  (merge-pathnames pathname *quicklisp-home*))

(defun qenough (pathname)
  (enough-namestring pathname *quicklisp-home*))

(defvar *registry* nil)

(defun setup-alt (root)
  (setq *quicklisp-home* root)
  (if (find-package "QUICKLISP")
      (funcall (find-symbol "SETUP" "QUICKLISP"))
      (warn "CALL SETUP-ALT after loading quicklisp")))

#+nil
(setup-alt
 "~/scratch/extern/roswell/lisp/quicklisp/")
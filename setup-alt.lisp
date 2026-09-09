(defpackage #:ql-info
  (:export #:*version*))

;; set later
(defvar ql-info:*version* nil)

(defpackage #:ql-setup
  (:use #:cl)
  (:export #:*quicklisp-home*
           #:qmerge
           #:qenough))

(in-package #:ql-setup)

;; set later
(defvar *quicklisp-home* nil)

(defun qmerge (pathname)
  "Return PATHNAME merged with the base Quicklisp directory."
  (merge-pathnames pathname *quicklisp-home*))

(defun qenough (pathname)
  (enough-namestring pathname *quicklisp-home*))

(defun qenough (pathname)
  (enough-namestring pathname *quicklisp-home*))


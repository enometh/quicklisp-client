;;; -*- Mode: LISP; Package: :cl-user; BASE: 10; Syntax: ANSI-Common-Lisp; -*-
;;;
;;;   Time-stamp: <>
;;;   Touched: Wed Sep 09 14:36:11 2026 +0530 <enometh@net.meer>
;;;   Bugs-To: enometh@net.meer
;;;   Status: Experimental.  Do not redistribute
;;;   Copyright (C) 2026 Madhu.  All Rights Reserved.
;;;

;;; modes of operation
;;;
;;; (and asdf (not mk-defsystem)) -> asdf
;;; (and mk-defsystem (not asdf)) -> mk-defsystem
;;; (and mk-defsystem asdf) -> mk-defsystem

(defpackage "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"
  (:use "CL")
  (:export
   "FIND-SYSTEM"
   "SYSTEM-SOURCE-DIRECTORY"
   "CLEAR-SYSTEM"
   "COMPONENT-NAME"
   "LOAD-SYSTEM"
   "MAP-SYSTEMS"))

(defpackage "QUICKLISP-FUDGE-MK"
  (:use "CL" "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM")
  (:export
   "SET-MK"
   "SET-ASDF"
   "SWITCH-ASDF-PACKAGE"
   "RESTORE-ASDF-PACKAGE"))

(in-package "QUICKLISP-FUDGE-MK")



;;; ----------------------------------------------------------------------
;;;
;;; ~/.cmucl-init.lisp functions
;;;

(defun package-add-nicknames (pkg &rest nicknames)
  (rename-package (find-package pkg)
		  (package-name pkg)
		  (union nicknames (package-nicknames pkg) :test #'string=)))


(defun package-remove-nicknames (pkg &rest nicknames)
  (rename-package (find-package pkg)
		  (package-name pkg)
		  (set-difference (package-nicknames pkg) nicknames
				  :test #'string=)))

(defun rename-package-1 (package new-name)
  (let* ((package (package-name package))
	 (nicknames (package-nicknames package)))
    (rename-package package new-name nicknames)))

(defun featurep (x)
  (when (or (keywordp x)
	    (setq x (find-symbol (symbol-name x) :keyword)))
    (find x *features*)))

(defun push-feature (&rest features)
  (dolist (feature features)
    (pushnew feature *features*))
  features)

(defun pop-feature (&rest features)
  (let ((deleted nil))
    (dolist (feature features)
      (cond ((featurep feature)
	     (pushnew feature deleted)
	     (setq *features* (delete feature *features*)))))
    deleted))


;;; ----------------------------------------------------------------------
;;;
;;;
;;;

(defun switch-asdf-package
    (&aux
     (p (find-package "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"))
     (q (find-package "ASDF")) n)
  (assert (equal (package-name p) "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"))
  (cond ((equal p q)
	 (assert (equal (package-name q) "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"))
	 (assert (find "ASDF" (package-nicknames p)))
	 t)
	(q (cond ((setq n (equal (package-name q) "ASDF"))
		  (assert (not (find-package "ASDF-THE-REAL")))
		  (rename-package-1 "ASDF" "ASDF-THE-REAL")
		  (package-add-nicknames p "ASDF"))
		 (t (error "ASDF is some unknown package ~A" n))))
	(t (package-add-nicknames p "ASDF"))))

(defun restore-asdf-package
    (&aux
     (p (find-package "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"))
     (q (find-package "ASDF")) r)
  (assert (equal (package-name p) "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"))
  (cond ((equal p q)
	 (cond ((setq r (find-package "ASDF-THE-REAL"))
		(package-remove-nicknames p "ASDF")
		(rename-package-1 r "ASDF"))
	       (t (package-remove-nicknames p "ASDF"))))
	(q (assert (equal (package-name q) "ASDF"))
	   (assert (not (setq r (find-package "ASDF-THE-REAL"))))
	   t)
	((setq r (find-package "ASDF-THE-REAL"))
	 (rename-package-1 r "ASDF"))))

(defun feat ()
  (append (and (featurep :mk-defsystem) '(:mk-defsystem))
	  (and (featurep :asdf) '(:asdf))))

(defun set-asdf (&aux p)
  (cond ((and (setq p (find-package "ASDF"))
	      (equal (package-name p) "ASDF"))
	 t)
	(p (assert (equal (package-name p)
			   "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"))
	   (restore-asdf-package))
	(t (error "NO ASDF PACKAGE")))
  (unless (featurep :asdf)
    (push-feature :asdf))
  (when (featurep :mk-defsystem)
    (pop-feature :mk-defsystem))
  (feat))


(defun set-mk (&aux p)
  (cond ((and (setq p (find-package "ASDF"))
	      (equal (package-name p) "ASDF"))
	 (switch-asdf-package))
	(p (assert (equal (package-name p)
			  "QUICKLISP-MK-DEFSYSTEM-ASDF-SHIM"))
	   t)
	((and (setq p (find-package "ASDF-THE-REAL"))
	      (equal (package-name p) "ASDF-THE-REAL"))
	 (switch-asdf-package))
	(t
	 (warn "NO ASDF PACKAGE")))
  (when (featurep :asdf)
    (pop-feature :asdf))
  (unless (featurep :mk-defsystem)
    (push-feature :mk-defsystem))
  (feat))

#||
(switch-asdf-package)
(find-package "ASDF")
(restore-asdf-package)
(find-package "ASDF-UTILITIES")
(package-nicknames "ASDF-UTILITIES")
(package-name (find-package  "ASDF"))
(feat)
(set-mk)
(set-asdf)
(equalp 'find-system 'quicklisp-mk-defsystem-asdf-shim:find-system)
(and (equalp (feat) '(:mk-defsystem))
||#


;; TODO COND from FLAVORS

(defun find-system (system &optional error-p)
  #+(and asdf (not mk-defystem))
  (asdf:find-system system error-p)
  #+mk-defsystem
  (mk:find-system system (if error-p :error :load-or-nil)))

(defun system-source-directory (system-designator)
  #+(and asdf (not mk-defystem))
  (asdf:system-source-directory system-designator)
  #+mk-defsystem			; XXX
  (mk::system-relative-pathname system-designator ""))

(defun clear-system (system)
  #+(and asdf (not mk-defystem))
  (asdf:clear-system system)
  #+mk-defsystem
  (mk:undefsystem system))

(defun component-name (component)
  #+(and asdf (not mk-defsystem))
  (asdf:component-name  component)
  #+mk-defsystem
  (mk::component-name component))

(defun load-system (system &rest keys &key force force-not verbose version)
  #+mk-defsystem(declare (ignorable keys force-not))
  #+(and asdf (not mk-defsystem))
  (asdf:load-system :force force :force-not force-not
		    :verbose verbose :version version)
  #+mk-defsystem
  (progn
    (when version
      (warn "version not handled in (load-system ~A :version ~S)"
	    system version))
    (mk:load-system system :verbose verbose :force force)))

(defun map-systems (function)
  #+(and asdf (not mk-defsystem))
  (asdf:map-system function)
  #+mk-defsystem
  (loop :for registered :being :the :hash-values :of mk::*defined-systems*
	:do (funcall function registered)))

#||
(load "~/cl/extern/Github/quicklisp-client/quicklisp-client.system")
(switch-asdf-package)
(mk:load-system :quicklisp :compile-during-load niL)
(mk:compile-system  :quicklisp)
(find-package "ASDF")
(set-mk)
||#
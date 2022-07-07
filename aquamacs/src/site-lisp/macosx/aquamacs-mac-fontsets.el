;; Aquamacs-mac-fontsets

;; specify some default fontsets that should work on the Mac
;; some fonts might not be found - a warning is issued
;; this should eventually be replaced by a complete font selection
;; dialog

;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs fonts

;; This file is part of Aquamacs Emacs
;; http://www.aquamacs.org/


;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Copyright (C) 2005, 2012, 2016 David Reitter


(eval-when-compile (require 'aquamacs-macros))

;;; FONT DEFAULTS

;; This seems to be required in Emacs 24 now
;; (set-fontset-font t 'symbol (font-spec :name "AppleSymbol"))
;; (set-fontset-font t 'symbol '("Apple Symbol" . "iso10646-1"))

;; AppleGothic does not have all characters...
;; Euro symbol (needed in Emacs 24)  20AC
;; RUPEE SIGN
(set-fontset-font t '(#x20AB . #x20B6) (font-spec :name "AppleSymbol"))
;; SINGLE LOW-9 QUOTATION MARK  and others
(set-fontset-font t '(#x2017 . #x201A) (font-spec :name "AppleSymbol"))

;; Emoji

(set-fontset-font t 'symbol (font-spec :family "Apple Color Emoji")
                  nil 'prepend)

;; (set-fontset-font t '( #x2000 . #x21FF) (font-spec :name "AppleGothic"))
;; (set-fontset-font t '( #x2000 . #x21FF) (font-spec :name "AppleSymbol"))

;; ;; the following doesn't work - needs display
;; (with-temp-buffer
;;   ;; should choose default font
;;   (loop for i from #x2000 to #x21FF do
;; 	(insert i))
;;   (beginning-of-buffer)
;;   (loop for i from #x2000 to #x21FF do
;; 	(print (internal-char-font (point)))
;; 	(when (equal 0 (cdr-safe (internal-char-font (point))))
;; 	  (print i)
;; 	  (set-fontset-font t '(i . i) (font-spec :name "AppleSymbol")))
;; 	(forward-char)))


;; commented out, doesn't work
;;(set-fontset-font
;; "fontset-default"
;; 'symbol
;; '("Lucida Grande" . "iso10646-1"))

;; Define special characters in the default fontset
;; because they would otherwise be taken from the Apple Symbols font
;; which has more "symbol" class characters than Lucida Grande.
;; we cannot use Lucida generally for the symbol class, because that
;; would hide math characters like  2208, "element of", which
;; aren't defined in Lucida and it would defeat the purpose of
;; the underlying font selection algorithm

(when (fontset-exist-p "fontset-startup")
  ;; does not exist when started with -nw
  (mapc (lambda (c)
	  (set-fontset-font
	   "fontset-startup"
	   (cons c c)
	   '("Lucida Grande" . "iso10646-1"))
	  )
	'( ?\x2318 ;; command symbol
	   ?\x2325 ;; option key symbol
	   ?\x2326 ;; erase to right
	   ?\x232B ;; erase to left (backspace)
	   ?\x21e7 ;; shift
	   )))

(setq ignore-font-errors t)

(setq aquamacs-ring-bell-on-error-saved
      (if (boundp 'aquamacs-ring-bell-on-error-flag)
	  aquamacs-ring-bell-on-error-flag
	nil))
(setq aquamacs-ring-bell-on-error-flag nil)

(defun signal-font-error (arg)
  (unless ignore-font-errors
    (print arg)
    )
  )
;; this requires fontset-add-font-fast
;; as defined by an aquamacs patch to fontset.c

(defun create-aquamacs-fontset (maker name weight variety style sizes  &optional fontsetname)
  "Create a mac fontset with the given properties (leave nil to under-specify).
SIZES is a list of integers, indicating the desired font sizes in points.
Errors are signalled with ``signal-font-error'', unless ''ignore-font-errors''
is non-nil. (This function is part of Aquamacs and subject to change.)"
  (condition-case e
      (dolist (size (if (listp sizes) sizes (list sizes)))
	(let ((fontset-name (concat (or fontsetname name) (format "%s" size))))
	  (unless (fontset-exist-p (format "fontset-%s" fontset-name))
	    (message "Defining fontset: %s" fontset-name)
	    (create-fontset-from-mac-roman-font
	     (format "-%s-%s-%s-%s-%s-*-%s-*-*-*-*-*-mac-roman"
	     (or maker "*")
	     (or name "*")
	     (or weight "*")
	     (or variety "*")
	     (or style "*")
	     size)
	     nil
	     fontset-name)))
	)
    (error (signal-font-error e))))


;; don't do this at the moment
;; carbon-font uses the somewhat dysfunctional
;; create-fontset-from-fontset-spec
;; (and also overwrites any monaco12 definitions)
;(if (string= "mac" window-system)
;    (require 'carbon-font)
;  )

(defvar aquamacs-additional-fontsets
  (append
	   (mapcar (lambda (x) (list "apple" "monaco*" "medium" "r" "normal" x "monaco")) '(9 10 11 12 13 14 16 18))
	   (mapcar (lambda (x) (list "apple" "lucida grande*" "medium" "r" "normal" x "lucida")) '(9 10 11 12 13 14 16 18))
	   (mapcar (lambda (x) (list "apple" "lucida sans typewrite*" "medium" "r" "normal" x "lucida_typewriter" )) '(9 10   12   14))
	   (list (list "apple" "lucida console*" "medium" "r" nil 11 "lucida_console" ))
	   (mapcar (lambda (x) (list nil "courier*" "medium" "r" nil x "courier" )) '(11 13))
	   (mapcar (lambda (x) (list nil "bitstream vera sans mono" "medium" "r" "normal" x "vera_mono" )) '(10 12 14))
	   )
  "List of fontsets defined on startup.
This variable is reduced by `aquamacs-mac-fontsets.el' to
contain only those fontsets referred to by `custom-file'.

Thus, this variable is not intended to be changed by users.
Use `create-aquamacs-fontset' to create a custom fontset.")


(defun aquamacs-create-additional-fontsets ()
  "Define a number of fontsets to be used with Aquamacs.
As of Aquamacs 1.1, this is not called on startup any more."
  (interactive)

  (dolist (font aquamacs-additional-fontsets)
    (apply #'create-aquamacs-fontset font)))

; (aquamacs-create-customization-fontsets)
(defun aquamacs-create-customization-fontsets ()
  "Defines fontsets referred to in `custom-file'.
Only fontsets in `aquamacs-additional-fontsets' are defined.
This variable is changed to reflect the needed fontsets."
  (protect
   (let ((standard-fontsets nil)
	 (buf (find-file-noselect custom-file 'nowarn 'lit)))
     (when (bufferp buf)
       (dolist (font aquamacs-additional-fontsets)
	 (let ((fontset-name (concat (nth 6 font) (int-to-string (nth 5 font)))))
	   (with-current-buffer buf
	     (beginning-of-buffer)
	     (if (search-forward fontset-name nil 'no)
	 (add-to-list 'standard-fontsets font )))))
       (kill-buffer buf))
     ;; reduce the fontsets - they will be saved in customizations.
     ;; the next time, it'll be quicker.
     ;; if custom-file is not readable, we'll reduce the fontsets to nil
     (setq aquamacs-additional-fontsets standard-fontsets))
   (aquamacs-create-additional-fontsets)))

(if (or (not (boundp 'aquamacs-additional-fontsets)) aquamacs-additional-fontsets)
    (add-hook 'after-init-hook 'aquamacs-create-customization-fontsets))

;; want more fonts?
;; (print-elements-of-list (x-list-fonts "*arial*"))



;; interesting thread about fonts:
;; http://lists.gnu.org/archive/html/help-gnu-emacs/2004-01/msg00398.html
;; http://lists.gnu.org/archive/html/help-gnu-emacs/2003-03/msg00436.html


(defun print-elements-of-list (list)
  "Print each element of LIST on a line of its own."
  (while list
    (insert (car list)) (insert "\n")
    (setq list (cdr list))))



(setq aquamacs-ring-bell-on-error-flag aquamacs-ring-bell-on-error-saved)
(provide 'aquamacs-mac-fontsets)

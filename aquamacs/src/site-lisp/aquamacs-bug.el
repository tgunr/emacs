;; Aquamacs-bug.el

;; Maintainer: David Reitter
;; Keywords: mac bug report

;; This file is part of Aquamacs Emacs
;; http://www.aquamacs.org/

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; Aquamacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Aquamacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Copyright (C) 1985, 1994, 1997, 1998, 2000, 2001, 2002
;; Free Software Foundation, Inc.

;; Copyright (C) 2005, 2008, 2009, 2010, 2013 David Reitter



(provide 'aquamacs-bug)

(require 'aquamacs-macros)
(require 'aquamacs-tools)
;; Request by RMS 06/2005: do not report Aquamacs bugs
;; to the Emacs mailing lists.

;; use standard emacs bug reporting technology.

(defun aquamacs-webbug-send-it ()
  "Pass current buffer on to the Aquamacs website for bug reporting."

; to be implemented.  Perhaps this is easier to do with an authenticated SSH request or so, but that might
; make it more insecure.  HTTP post would probably do the job.

)

; (report-aquamacs-bug)
(defun report-aquamacs-bug (topic &optional recent-keys insert-file)
  "Report a bug in Aquamacs Emacs.
Prompts for bug subject.  Leaves you in a mail buffer."
  ;; This strange form ensures that (recent-keys) is the value before
  ;; the bug subject string is read.
  (interactive
   (reverse (list (recent-keys)
	  (if (eq send-mail-function 'mailclient-send-it)
	      nil (read-string "Bug Subject: ")))))
  ;; If there are four numbers in emacs-version, this is a pretest
  ;; version.

  ;; need to load emacsbug before temporarily binding any of the
  ;; defcustom'ed variables in there, because we'd otherwise avoid
  ;; declaring and initializing them.
  (require 'emacsbug)

  (let  (
;;	 (send-mail-function 'aquamacs-webbug-send-it)
	 (report-emacs-bug-address "aquamacs-bugs@aquamacs.org")
	 (report-emacs-bug-pretest-address "aquamacs-bugs@aquamacs.org")
	 (report-emacs-bug-no-confirmation t))

    (if (not (eq send-mail-function 'mailclient-send-it))
	(report-emacs-bug topic recent-keys)
			; else

      (let ((one-buffer-one-frame nil)
	    (mail-interactive nil))
	(save-window-excursion
	  (let (backup-buffer)
	    (when (get-buffer "*mail*")
	      (with-current-buffer (get-buffer "*mail*")
	(setq backup-buffer (rename-buffer "mail-backup" t))))
	    (report-emacs-bug topic recent-keys)
	    (insert "Enter your bug report here.")
	    (when insert-file
	      (search-forward "Major mode:" nil 'move-to-limit-if-not-found)
	      (beginning-of-line)
	      (delete-region (point) (point-max)))
	    (end-of-buffer)
	    (insert (format "\nCommand line: %s\n\nPATH: %s\n\nexec-path: %s"
	    command-line-args (getenv "PATH") exec-path))
	    (when insert-file
	      (end-of-buffer)
	      (insert "\n\n")
	      (insert-file-contents insert-file))
	    (set-buffer-modified-p t)
	    (let ((buf (current-buffer))
	  (kill-buffer-query-functions nil))
	      (mail-send)
	      (set-buffer-modified-p nil)
	      (if (buffer-live-p buf) (kill-buffer buf)))
	    (if backup-buffer
	(with-current-buffer backup-buffer
	  (rename-buffer "*mail*" t)))
	    ))))))


(defun check-for-aquamacs-crashes (&optional old-ones)
  "Check for crashes of Aquamacs since last start.
Offer to send a bug report."
  (interactive "P")
  (protect
   (let* ((logfiles (append
	    (directory-files "~/Library/Logs/CrashReporter" t "^Aquamacs.*")
	    (directory-files "~/Library/Logs/DiagnosticReports" t "^Aquamacs.*.crash$")))
	  (reportable-crashes nil)
	  (ln (length logfiles))
	  (last-nonmenu-event nil)
	  (shell-file-name "/bin/bash"))
     (mapc
      (lambda (file)
	(when (or old-ones (file-newer-than-file-p file aquamacs-id-file))
	  (push file reportable-crashes)))
      (if (> ln 4)
	  (nthcdr (- (length logfiles) 3) logfiles)
	logfiles))
     (and reportable-crashes
	  (aquamacs-ask-for-confirmation (format "Aquamacs crashed the last time you ran it.  Send report%s?
Please send a simple bug report by e-mailing the automatically generated crash report to the Aquamacs developers. If possible, please describe briefly what you were doing when it happened."
				 (if (cdr reportable-crashes) "s" "")) nil nil nil nil t)
	   (mapc (lambda (file)
     (let* ((locations (aquamacs-get-crash-location file))
	    (location (car locations))
	    (last-lisp-location (cdr locations)))
       (report-aquamacs-bug (concat "Crash in " location
		    (if last-lisp-location (concat " / " last-lisp-location) ""))
	    nil file))) reportable-crashes))
     nil)))

(defun aquamacs-get-crash-location (file)
  (protect
   (with-temp-buffer
     (insert-file-contents file)
     (aquamacs-get-crash-location-in-buffer))))

(defun aquamacs-get-crash-location-in-buffer (&optional lineinfo)
  (let ((cpos nil) (fpos nil))
    (goto-char (point-min))
    (protect
     (when
	 ;; we're assuming it is thread 0.
	 ;; others might crash, but this is where Aquamacs is at
	 (or (search-forward "Thread 0 Crashed:" nil t)
	     (search-forward "Thread 0:" nil t))
       (set-mark (point))
       (or (search-forward "Thread 1:" nil t)
	   (goto-char (point-max)))
       (narrow-to-region (mark) (point))
       ;; find last occ of signal

       (when
	   (and (or (search-backward "_signal " nil t)
	    (goto-char (point-min)))
	(or (search-forward "emacs_abort " nil t) t)
	(or (search-forward "syms_of_" nil t) t)
	(or (search-forward "org.gnu.Aquamacs" nil t) (search-forward "Aquamacs" nil t))
	(search-forward-regexp "[\s\t _]+[0-9a-fxA-FX]*[\s\t _]*" nil t))
	 (set-mark (point))
	 (if lineinfo
	     (end-of-line)
	   (progn (search-forward " " nil t) (backward-char)))
	 (setq cpos (buffer-substring-no-properties (mark) (point)))
	 (when
	     (search-forward-regexp "org.gnu.Aquamacs .* F" nil t)
	   (backward-char)
	   (set-mark (point))
	   (if lineinfo
	       (end-of-line)
	     (progn (search-forward " " nil t) (backward-char)))
	   (setq fpos (buffer-substring-no-properties (mark) (point)))))
       (widen))
     (cons cpos fpos))))


;; (aq-chomp (shell-command-to-string
;; 			    (format "grep org.gnu.Aquamacs \"%s\" | grep -v -e 'Identifier' -e 'fatal' -e 'ns_term_shutdown' -e 'shut_down_emacs' -e 'signal' -e 'emacs_abort' | head -n1 | grep -o -e '0x.*' | grep -o -e ' .*'" file)))
;; (aq-chomp
;; (shell-command-to-string
;; 	(format "grep org.gnu.Aquamacs \"%s\" | grep -v -e 'Identifier' -e 'fatal' -e 'ns_term_shutdown' -e 'shut_down_emacs' -e 'signal' -e 'emacs_abort'  | grep '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]\sF[a-z]' | head -n1 | grep -o -e '0x.*' | grep -o -e ' .*'" file))


(defun start-aquamacs-with-args (kill-session &rest args)
  "Start Aquamacs with optional arguments.
Starts a new instance of Aquamacs with arguments args.
If kill-session is non-nil, kills the current session
\(requires Mac OS X 10.6 or greater)."
  (let ((osx-version (shell-command-to-string
	      "/usr/bin/sw_vers | /usr/bin/awk '/ProductVersion/ {print $2}'"))
	(aquamacs-args (or args (list "-q"))))
    (if (string< osx-version "10.6")
	(progn
	  (apply #'call-process "open" nil 0 nil
	 "-a" (car command-line-args)
	 "-n"
	 "--args" aquamacs-args)
	  (if kill-session (kill-emacs)))
      (apply 'start-process "aquamacs-with-args" nil
	     (car command-line-args) aquamacs-args))))

(defun start-vanilla-aquamacs (&optional kill-session)
  "Start a vanilla Aquamacs.
Starts another instance of the current session.
With prefix argument KILL-SESSION, kills the current session
\(requires Mac OS X 10.6 or greater)."
  (interactive "P")
  (start-aquamacs-with-args kill-session "-q"))

(defun start-vanilla-emacs (&optional kill-session)
  "Start a vanilla Emacs.
Starts another instance of the current session, omitting
the initialization of many of Aquamacs extended features
that distinguish it from GNU Emacs.

With prefix argument KILL-SESSION, kills the current session
\(requires Mac OS X 10.6 or greater)."
  (interactive "P")
  (start-aquamacs-with-args kill-session "-Q"))


(defun start-debug-aquamacs (&optional kill-session)
  "Start Aquamacs for init file debugging.
Starts another instance of the current session, enabling
informative error messages (see `debug-on-error') during
processing of user-supplied initialization files.

With prefix argument KILL-SESSION, kills the current session
\(requires Mac OS X 10.6 or greater)."
  (interactive "P")
  (start-aquamacs-with-args kill-session "--debug-init"))

(defun aquamacs-prefs-file-remove-elc ()
  "Delete corresponding .elc file."
  (let ((f (concat buffer-file-name "c")))
    (when (file-exists-p f) ;; .elc
      (when (y-or-n-p (format "Delete byte-compiled %s " f))
	(message "Deleting %s" f)
	(delete-file f)))))

(defun aquamacs-edit-preferences-files ()
  "Open the preferences files for editing.
This command will open `user-init-file' and all files
in `aquamacs-preference-files' for editing."
  (interactive)
  (let ((pref-file))
    (mapcar
     (lambda (f)
       (setq pref-file f)
       (when (file-exists-p f)
	 (dnd-open-local-file (concat "file:" f) nil)
	 (add-hook 'after-save-hook 'aquamacs-prefs-file-remove-elc nil 'local)))
     (cons user-init-file (mapcar (lambda (x) (concat x ".el")) aquamacs-preference-files)))
    ;; ensure last file is open and visible, regardless of existence:
    (unless (file-exists-p pref-file) (dnd-open-local-file (concat "file:" f) nil))))

(defvar menu-bar-bug-help-menu (make-sparse-keymap "Diagnose and Report Bug"))

(define-key menu-bar-bug-help-menu [send-emacs-bug-report]
  `(menu-item "Send Bug Report..."
	      report-aquamacs-bug
	      :help "Report a Bug in Aquamacs Emacs"))
(define-key menu-bar-bug-help-menu [start-vanilla-aquamacs]
  `(menu-item "Try Aquamacs without customizations"
	      start-vanilla-aquamacs
	      :help "Start Aquamacs Emacs without any user-specific settings."))
(define-key menu-bar-bug-help-menu [start-debug-aquamacs]
  `(menu-item "Start Aquamacs and debug preference files"
	      start-debug-aquamacs
	      :help "Start Aquamacs Emacs and enter debugger on error in init files."))
(define-key menu-bar-bug-help-menu [edit-init-files]
  `(menu-item "Edit preferences files"
	      aquamacs-edit-preferences-files
	      :help "Edit Aquamacs Emacs user preference files."))

(define-key menu-bar-bug-help-menu [debug-sep] '("--"))

(define-key menu-bar-bug-help-menu [debug-on-quit]
  (menu-bar-make-toggle toggle-debug-on-quit debug-on-quit
	"Enter Debugger on Quit/C-g" "Debug on Quit %s"
	"Enter Lisp debugger when C-g is pressed"))
(define-key menu-bar-bug-help-menu [debug-on-error]
  (menu-bar-make-toggle toggle-debug-on-error debug-on-error
	"Enter Debugger on Error" "Debug on Error %s"
	"Enter Lisp debugger when an error is signaled"))
(define-key menu-bar-options-menu [debug-on-quit] nil)
(define-key menu-bar-options-menu [debug-on-error] nil)
(define-key menu-bar-options-menu [debugger-separator] nil)

(define-key-after menu-bar-help-menu [bug-diagnosis]
  `(menu-item "Diagnose and Report Bug "
	      ,menu-bar-bug-help-menu
	      :help "Bug diagnosis")
  'menu-aquamacs-homepage)
(define-key menu-bar-help-menu [send-emacs-bug-report] nil)

;; code to print non-standard values
;; (mapatoms
;;  (lambda (sym)
;;    (when (default-boundp sym)
;;      (princ (format "%s:" sym))
;;      (let ((print-level 2)
;; 	   (print-length 3))
;;        (prin1 (eval sym)))
;;      (princ "\n"))))

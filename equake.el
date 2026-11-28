;;; equake.el --- Drop-down console for (e)shell & terminal emulation -*- lexical-binding: t; -*-

;; *EQUAKE* - emacs shell dropdown console

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                         _         ;;;
;;   ___  __ _ _   _  __ _| | _____  ;;;
;;  / _ \/ _` | | | |/ _` | |/ / _ \ ;;;
;; |  __/ (_| | |_| | (_| |   <  __/ ;;;
;;  \___|\__, |\__,_|\__,_|_|\_\___| ;;;
;;          |_|                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Copyright (C) 2018-2026 Benjamin Slade

;; Author: Benjamin Slade <LfLg.gg.Lx.f.xx@lambda-y.net>
;; Maintainer: Benjamin Slade <LfLg.gg.Lx.f.xx@lambda-y.net>
;; URL: https://github.com/emacsomancer/equake
;; Package-Version: 0.9999111
;; Version: 0.9999111
;; Package-Requires: ((emacs "27.1"))
;; Created: 2018-12-12
;; Keywords: convenience, frames, terminals, tools, window-system

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package is designed to recreate a Quake-style drop-down console fully
;; within Emacs, compatible with 'eshell, 'term, 'ansi-term, and 'shell modes.
;; It has multi-tab functionality, and the tabs can be moved and renamed
;; (different shells can be opened and used in different tabs).  It is intended
;; to be bound to shortcut key like F12 to toggle it off-and-on.

;;; Installation:
;; To install manually, clone the git repo somewhere and put it in your
;; load-path, e.g., add something like this to your init.el:
;; (add-to-list 'load-path
;;             "~/.emacs.d/equake/")
;;  (require 'equake)

;;; Usage:
;; Run with:---
;; emacsclient -n -e '(equake-invoke)' ,
;; after launching an Emacs daemon of course.
;;
;; I recommend binding the relevant command to a key like F12 in your DE/WM.
;; Executing this command will create a new equake console
;; on your screen the first time, and subsequently toggle
;; the console (i.e. hide or show it).
;;
;; It works with eshell, ansi-term, term, shell.  But it was
;; really designed to work with eshell, which is the default.
;; New console tabs can be specified to open with a shell
;; other than the default shell.
;;
;; Equake is designed to work with multi-screen setups,
;; with a different set of tabs for each screen.
;;
;; Additional functionality when xprop and wmctrl are installed.
;;
;; You'll probably also want to configure your WM/DE to
;; ignore the window in the task manager etc and
;; have no titlebar or frame. It's most throughly tested with
;; KDE Plasma 5 & StumpWM, but should be able to be made to work
;; well with most DEs/WMs (I welcome notes on other environments).
;;
;;; In Stumpwm:
;; add the following to your .stumpwmrc or ~/.stumpwm.d/init.lisp or other
;; initialisation file (please adjust your mouse focus policy as below to
;; get optimal Equake behaviour):
;; ;; BEGIN COMMON LISP HERE;;
;; (defun calc-equake-width ()
;;   (let ((screen-width (caddr (with-input-from-stringp (s (run-shell-command (concat emacsclient-launch " -n -e '(equake--get-monitor-attribute 'workarea t)'") t)) (read s))))
;;         (desired-width-perc (read-from-string (run-shell-command (concat emacsclient-location " -n -e 'equake-size-width'") t))))
;;     (truncate (* screen-width desired-width-perc))))

;; (defun calc-equake-height ()
;;   (let ((screen-height (cadddr (with-input-from-string (s (run-shell-command (concat emacsclient-location " -n -e '(equake--get-monitor-attribute 'workarea t)'") t)) (read s))))
;;         (desired-height-perc (read-from-string (run-shell-command (concat emacsclient-location " -n -e 'equake-size-height'") t))))
;;     (truncate (* screen-height desired-height-perc))))

;; (setf *equake-width* 1368)
;; (setf *equake-height* 768)

;; (defcommand invoke-equake () ()
;;   "Raise/lower Equake drop-down console."
;; (let* ((on-top-windows (group-on-top-windows (current-group)))
;;          (equake-on-top (find-equake-in-group on-top-windows))
;;          (equake-in-group (find-equake-in-group (group-windows (current-group))))
;;          (equake-width (car (calc-screen-dimensions)))
;;          (equake-height (round (* .40 (cadr (calc-screen-dimensions))))))
;;     (when (and equake-on-top (not (find-equake-globally (screen-groups (current-screen)))))
;;       (setf (group-on-top-windows (current-group)) (remove equake-on-top on-top-windows)))
;;     (if (and equake-on-top (eq (current-group) (window-group (find-equake-globally (screen-groups (current-screen))))))
;;         (progn (if (eq (find-class 'float-group) (class-of (current-group)))
;;                    (when (> (length (group-windows (current-group))) 1)
;;                      (xwin-hide equake-on-top)
;;                      (hide-window equake-on-top))
;;                    (progn (unfloat-window equake-on-top (current-group))
;;                           (xwin-hide equake-on-top)
;;                           (move-windows-to-group (list equake-on-top) "void")))
;;                 ;; then hide Equake window via native Stumpwm method.)
;;                (setf (group-on-top-windows (current-group)) (remove equake-on-top on-top-windows))) 
;;         (let ((found-equake (find-equake-globally (screen-groups (current-screen))))) ; Otherwise, search all groups of current screen for Equake window:
;;           (if (not found-equake)          ; If Equake cannot be found,
;;               (progn (run-shell-command (concat emacsclient-location " -n -e '(equake-invoke)'")))  
;;               (progn (unless (eq (current-group) (window-group found-equake)) ; But if Equake window is found, and if it's in a different group
;;                        (move-window-to-group found-equake (current-group)))   ; move it to the current group,
;;                      (if (eq (find-class 'float-group) (class-of (current-group)))
;;                          (xwin-unhide (window-xwin found-equake) (window-parent found-equake))
;;                          (progn (unhide-window found-equake) ; unhide window, in case hidden
;;                                 (raise-window found-equake)
;;                                 (float-window-move-resize (find-equake-globally (screen-groups (current-screen))) :width equake-width :height equake-height) ; set size
;;                                 (float-window found-equake (current-group))
;;                                 (focus-window found-equake))) ; float window
;;                      (focus-window found-equake t)
;;                      (push found-equake (group-on-top-windows (current-group))))))))) ; make on top

;; (defun find-equake-in-group (windows-list)
;;   "Search through WINDOWS-LIST, i.e. all windows of a group, for an Equake window. Sub-component of '#find-equake-globally."
;;   (let ((current-searched-window (car windows-list)))
;;     (if (equal current-searched-window 'nil)
;;         'nil
;;         (if (search "*EQUAKE*[" (window-name current-searched-window))
;;             current-searched-window
;;             (find-equake-in-group (cdr windows-list))))))

;; (defun find-equake-globally (group-list)
;;   "Recursively search through GROUP-LIST, a list of all groups on current screen, for an Equake window."
;;   (if (equal (car group-list) 'nil)
;;       'nil
;;       (let ((equake-window (find-equake-in-group (list-windows (car group-list)))))
;;         (if equake-window
;;             equake-window               ; stop if found and return window
;;             (find-equake-globally (cdr group-list))))))

;; ;; Set the mouse focus policy;
;; (setf *mouse-focus-policy* :click) ;; options: :click, :ignore, :sloppy
;; ;; END COMMON LISP HERE;;
;; And add an appropriate keybinding to your stumpwm init to toggle, e.g.:
;; (define-key *top-map* (kbd "F12") "invoke-equake")
;;
;;; In GNOME Shell (Wayland):
;; use the shell script =equake-invoke-wayland.sh=:
;;
;; #!/bin/sh

;; equakestatus=$(emacsclient -n -e '(frame-live-p (alist-get (equake--get-monitor) equake--frame))')

;; if [ "$equakestatus" = "nil" ]; then
;;     emacsclient -c -e "(progn (select-frame-set-input-focus (selected-frame))
;;                               (equake--transform-existing-frame-into-equake-frame)
;;                               (goto-char (1- (point-max))))"
;; else
;;     emacsclient -n -e '(progn (setq equake-use-frame-hide nil)
;;                               (equake-invoke))'
;; fi
;;
;;; In KDE Plasma 5:
;; systemsettings > Window Management > Window Rules:
;; Button: New
;;
;; In Window matching tab:
;; Description: equake rules
;; Window types: Normal Window
;; Window title: Substring Match : *EQUAKE*
;;
;; In Arrangement & Access tab:
;; Check: 'Keep above' - Force - Yes
;; Check: 'Skip taskbar' - Force - Yes
;; Check: 'Skip switcher' - Force - Yes
;;
;; In Appearance & Fixes tab:
;; Check: 'No titlebar and frame' - Force - Yes
;; Check: Focus stealing prevention - Force - None
;; Check: Focus protection - Force - Normal
;; Check: Accept focus - Force - Yes
;;
;;; Other environments:
;; In awesomewm, probably adding to your 'Rules' something
;; like this:
;;
;;  { rule = { name = "\\*EQUAKE\\*.*",
;;     properties = { titlebars_enabled = false, floating = true, ontop = true } },
;;
;; Or, if you're using a [[https://fennel-lang.org/][Fennel]] configuration, add:
;;      {:rule_any {
;;                  :name [
;;                   "\\*EQUAKE\\*.*"
;;                    ]}
;;          :properties {:floating true
;;                       :titlebars_enabled false
;;                       :ontop true}}
;; *And*, importantly, you need to set equake-restore-frame-use-offset (otherwise, for some reason the Equake frame gradually creeps up and to left as you hide and unhide it) to t and set a horizontal and/or vertical offset in equake-restore-frame-x-offset and/or equake-restore-frame-y-offset in order to reposition the unhidden Equake frame, i.e. include in your init.el something like:
;;
;; (setq equake-restore-frame-use-offset t)
;; (setq equake-restore-frame-y-offset 20)
;; or else use customize to set "Equake Restore Frame Use Offset" to "t" and "Equake Restore Frame Y Offset" to "20" (or whatever offset value).
;;
;;
;;; Advice:
;; add (advice-add #'save-buffers-kill-terminal :before-while #'equake-kill-emacs-advice)
;; to your settings to prevent accidental closure of equake frames

;;; Code:

(eval-when-compile (require 'cl-lib))
;; (require 'dash)                         ; for -let*
(require 'gv)
(require 'rx)                           ; for sane regexps
(require 'subr-x)

;;;###autoload
(define-minor-mode equake-mode
  "Minor mode for drop-down consoles for eshell and terminal emulation."
  :lighter " equake"
  :keymap (let ((map (make-sparse-keymap)))
            map))

(defvar equake--emulation-alist `((equake-mode . ,equake-mode-map)))
(add-to-list 'emulation-mode-map-alists 'equake--emulation-alist)

(define-minor-mode equake-rash-mode
  "Minor mode for drop-down consoles for rash console."
  :lighter " rash"
  :keymap (let ((map (make-sparse-keymap)))
            map))

(setq equake-rash-installed
      (and (executable-find "raco")
           (not (equal " [none]" (shell-command-to-string "printf \"$(raco pkg show rash | tail -1)\"")))))

(setq equake-nshell-installed (executable-find "nshell"))
(setq equake-hilbish-installed (executable-find "hilbish"))

(defvar equake-persistent-display-file
  (expand-file-name "equake-persistent-display" user-emacs-directory)
  "A file to store memorized DISPLAY in.")

(defgroup equake ()
  "Equake, a drop-down console for eshell and terminal emulation."
  :group 'shell)

(defgroup equake-bindings ()
  "Keybindings for Equake drop-down console."
  :group 'equake)

(defcustom equake-inhibit-message-choice nil
  "Whether or not messages are displayed in the echo area."
  :group 'equake
  :type 'boolean)

(defcustom equake-hide-from-taskbar-choice t
  "Whether or not to hide Equake from taskbar (may not work in all DEs or WMs)."
  :group 'equake
  :type 'boolean)

(defcustom equake-open-non-terminal-in-new-frame nil
  "If non-nil, then redirect non-terminal buffers to new frame."
  :group 'equake
  :type 'boolean)

(defcustom equake-shell-mode-setup nil
  "Shell commands to run when opening a tab in shell-mode.
E.g. \"bash \n clear \n\" to run bash and clear the screen."
  :group 'equake
  :type 'string)

(defcustom equake-display-buffer-function #'display-buffer-pop-up-frame
  "Sensible choices are are `display-buffer-pop-up-frame' for
opening in a new frame, or `display-buffer-use-some-frame' to
open in an existing (non-Equake) frame."
  :group 'equake
  :type 'function)

(defun equake-inhibit-message-locally ()
  "Set `inhibit-message' buffer-locally."
  (if equake-inhibit-message-choice
      (setq-local inhibit-message t)
    (setq-local inhibit-message nil)))

(defcustom equake-new-tab-binding "C-+"
  "Keybinding for creating new Equake tab using default shell."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-new-tab-binding) 'equake-new-tab))
  :group 'equake-bindings)

(defcustom equake-new-tab-different-shell-binding "C-M-+"
  "Keybinding for creating new Equake tab with ad hoc specified shell."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-new-tab-different-shell-binding) 'equake-new-tab-different-shell))
  :group 'equake-bindings)

(defcustom equake-prev-tab-binding "C-{"
  "Keybinding for switching to previous Equake tab."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-prev-tab-binding) 'equake-prev-tab))
  :group 'equake-bindings)

(defcustom equake-next-tab-binding "C-}"
  "Keybinding for switching to next Equake tab."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-next-tab-binding) 'equake-next-tab))
  :group 'equake-bindings)

(defcustom equake-move-tab-left-binding "C-M-{"
  "Keybinding for moving current Equake tab left."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-move-tab-left-binding) 'equake-move-tab-left))
  :group 'equake-bindings)

(defcustom equake-move-tab-right-binding "C-M-}"
  "Keybinding for moving current Equake tab right."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-move-tab-right-binding) 'equake-move-tab-right))
  :group 'equake-bindings)

(defcustom equake-rename-etab-binding "C-|"
  "Keybinding for renaming current Equake tab."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-rename-etab-binding) 'equake-rename-etab))
  :group 'equake-bindings)

(defcustom equake-close-tab-binding "C-M-_"
  "Keybinding for closing current Equake tab."
  :type 'string
  :set (lambda (sym defs)
         (custom-set-default sym defs)
         (define-key equake-mode-map (kbd equake-close-tab-binding) 'equake-close-tab-without-query))
  :group 'equake-binding)

(defcustom equake-external-shells
  '((rash
     :program "racket"
     :args ("-l" "rash/repl" "--")
     :mode equake-rash-mode)
    (nshell
     :program "nshell"
     :args nil)
    (hilbish
     :program "hilbish"
     :args nil))
  "External shell definitions for Equake.

Each entry has the form:

  (NAME :program PROGRAM :args ARGS [:mode MODE])

NAME is the shell identifier.
PROGRAM is the executable name.
ARGS is its argument list.
MODE, when present, is the Emacs mode to activate."
  :type '(alist
          :key-type symbol
          :value-type (plist
                       :options
                       ((:program (string :tag "Program"))
                        (:args (repeat string))
                        (:mode (choice
                                (const :tag "None" nil)
                                function)))))
  :group 'equake)

(defcustom equake-available-shells
  (append
   '("eshell" "term" "ansi-term" "shell")
   (when (locate-library "vterm") '("vterm"))
   (when (locate-library "eat") '("eat"))
   (when (locate-library "ghostel") '("ghostel"))
   (mapcar (lambda (definition)
             (symbol-name (car definition)))
           (seq-filter
            (lambda (definition)
              (let ((program (plist-get (cdr definition) :program)))
                (and program (executable-find program))))
            equake-external-shells)))
  "List of available shell choices for Equake.

Built-in shells are always available. Terminal backends are
included when their libraries can be located. External shells
are included when their configured executables are available."
  :group 'equake
  :type '(repeat string))

(defcustom equake-size-width 1.0
  "Fraction (.01-1.0) for width of Equake console."
  :type 'float
  :group 'equake)

(defcustom equake-size-height 0.4
  "Fraction (.01-1.0) for height of Equake console."
  :type 'float
  :group 'equake)

(defcustom equake-opacity-active 75
  "Amount of opacity of Equake console when active."
  :type 'integer
  :group 'equake)

(defcustom equake-opacity-inactive 60
  "Amount of opacity of Equake console when inactive."
  :type 'integer
  :group 'equake)

(defcustom equake-default-shell 'eshell
  "Default shell used by Equake, potential choices are
`eshell', `ansi-term', `term', `shell', `vterm', `rash',
`eat', `ghostel'."
  :type  'symbol
  :group 'equake)

(defcustom equake-default-sh-command ""
  "Default shell command used by `(ansi-)term' in Equake tab.
If set to empty string, Equake will fall back to system's default SHELL
environment variable."
  :type 'string
  :group 'equake)

(defcustom equake-show-monitor-in-mode-line nil
  "Toggle to show monitor id string as part of Equake mode-line."
  :type 'boolean
  :group 'equake)

(defcustom equake-use-frame-hide t
  "Hide frames rather than destroying frames."
  :type 'boolean
  :group 'equake)


(defcustom equake-close-frame-on-focus-loss nil
  "When non-nil, close (hide or destroy) the frame when it loses focus."
  :group 'equake
  :type 'boolean)

(defcustom equake-restore-frame-use-offset 'nil
  "Enable applying offset when restoring hidden frames (hack for AwesomeWM)."
  :type 'boolean
  :group 'equake)

(defcustom equake-restore-frame-x-offset 0
  "Horizontal offset for restoring hidden frames (hack for AwesomeWM)."
  :type 'integer
  :group 'equake)

(defcustom equake-restore-frame-y-offset 0
  "Vertical offset for restoring hidden frames (hack for AwesomeWM)."
  :type 'integer
  :group 'equake)

(defcustom equake-display-guess-list
  '(":0" ":1" "w32")
  "A list of displays to try to connect to, when the actual DISPLAY is
not yet known."
  :type 'list
  :group 'equake)

(defcustom equake-close-frame-after-last-etab-closes t
  "Whether or not to close the Equake frame after the last etab is closed."
  :type 'boolean
  :group 'equake)

(defgroup equake-faces nil
  "Faces for the Equake drop-down console."
  :group 'equake
  :group 'faces)

(defface equake-buffer-face
  '((t (:inherit 'default)))
  "Face used for internal Equake buffer text.
Includes font typeface and background colour."
  :group 'equake-faces)

(defface equake-tab-inactive
  '((t (:background "black" :foreground "lightblue" :inherit equake-buffer-face)))
  "Face used for inactive Equake tabs in the mode-line."
  :group 'equake-faces)

(defface equake-tab-active
  '((t (:background "lightblue" :foreground "black" :inherit equake-buffer-face)))
  "Face used for active Equake tabs in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-eshell
  '((t (:background "midnight blue" :foreground "#B68DFC"
         :inherit equake-buffer-face)))
  "Face used for indicating `eshell' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-term
  '((t (:background "midnight blue" :foreground "#FFCC00"
         :inherit equake-buffer-face)))
  "Face used for indicating `(ansi-)term' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-shell
  '((t (:background "midnight blue" :foreground "#39FF14"
         :inherit equake-buffer-face)))
  "Face used for indicating (inferior) `shell' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-vterm
  '((t (:background "midnight blue" :foreground "#B8FCFF"
         :inherit equake-buffer-face)))
  "Face used for indicating `vterm' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-nshell
  '((t (:background "midnight blue" :foreground "#FF3B3B"
         :inherit equake-buffer-face)))
  "Face used for indicating `nshell' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-hilbish
  '((t (:background "midnight blue" :foreground "#FF70A6"
         :inherit equake-buffer-face)))
  "Face used for indicating `hilbish' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-rash
  '((t (:background "midnight blue" :foreground "#D946EF"
         :inherit equake-buffer-face)))
  "Face used for indicating `rash' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-eat
  '((t (:background "midnight blue" :foreground "#FF8000"
         :inherit equake-buffer-face)))
  "Face used for indicating `eat' shell type in the mode-line."
  :group 'equake-faces)

(defface equake-shell-type-ghostel
  '((t (:background "midnight blue" :foreground "ghost white"
         :inherit equake-buffer-face)))
  "Face used for indicating `ghostel' shell type in the mode-line."
  :group 'equake-faces)

(defun equake-kill-emacs-advice (&rest _)
  "Ask whether a user wants to kill an Equake frame.

Intended as `:before-while' advice for
`save-buffers-kill-terminal'"
  (or (not (frame-parameter nil 'equakep))
      (y-or-n-p (concat
                 "Are you sure you want to close the equake console frame?\n"
                 "[Advice: Cancel and use `C-x k` to close the buffer or "
                 "invoke 'bury-buffer' instead, returning to your shell session.]"))))

(defun equake-ask-before-closing-equake ()
  "Make sure user really wants to close Equake, ask again."
  (declare (obsolete equake-kill-emacs-advice "Equake 0.96"))
  (interactive)
  (if (y-or-n-p (concat
                 "PLEASE, CHANGE YOUR CONFIGURATION FILE TO USE `equake-kill-emacs-advice' "
                 "INSTEAD OF `equake-check-if-in-equake-frame-before-closing'.\n"
                 "Are you sure you want to close the equake console frame?\n"
                 "[Advice: Cancel and use `C-x k` to close the buffer or invoke 'bury-buffer' instead, returning to your shell session.]?"))
      (save-buffers-kill-terminal)
    (print "Wisely cancelling the closing of the equake console frame...")))

(defun equake-check-if-in-equake-frame-before-closing ()
  "Check if we're in an Equake frame."
  (declare (obsolete equake-kill-emacs-advice "Equake 0.96"))
  (interactive)
  (if (frame-parameter nil 'equakep)
      (equake-ask-before-closing-equake)
    (save-buffers-kill-terminal)))

(defun equake--open-in-new-frame (buffer alist)
  "A predicate indicating whether equake should open in a new frame.
Called during processing of the `display-buffer-alist'.  Both arguments
\='BUFFER\=' and \='ALIST\=' are unused."
  (and (symbolp 'equake-mode)
       (symbol-value 'equake-mode)
       equake-open-non-terminal-in-new-frame))

(defun equake--display-buffer-function (buffer alist)
  "For use in `display-buffer-alist'."
  (funcall equake-display-buffer-function buffer alist))

(add-to-list 'display-buffer-alist
             '(equake--open-in-new-frame . ((display-buffer-reuse-window equake--display-buffer-function) . ((reusable-frames . 0)))))

(defun equake-invoke ()
  "Toggle Equake frames.
Invoke Equake externally via \"emacsclient -n -e \='(equake-invoke)\='\"."
  (interactive)
  (equake--select-some-graphic-frame)
  (let* ((monitor (equake--get-monitor))
         (current-equake-frame (alist-get monitor equake--frame)))
    (if (frame-live-p current-equake-frame)
        (if (frame-visible-p current-equake-frame)
            (equake--hide-or-destroy-frame current-equake-frame)
          (raise-frame current-equake-frame)
          (when equake-restore-frame-use-offset
            (set-frame-position current-equake-frame
                                equake-restore-frame-x-offset
                                equake-restore-frame-y-offset)))
      (equake--set-up-new-frame))))

;;; Tabs

(defvar equake--tab-list ()
  "A monitor to tab list mapping.")

(defvar equake--max-tab-no ()
  "A monitor to maximum tab number mapping.

Needed to assign a new name for a new tab (e.g. its number)")

(defun equake-new-tab-different-shell ()
  "Open a new shell tab, but using a shell different from the default."
  (interactive)
  (equake-new-tab
   (intern
    (message "%s"
             (completing-read "Choose shell:"
                                  equake-available-shells nil t nil nil)))))

(defun equake-new-tab (&optional override)
  "Open a new shell tab on monitor, optionally OVERRIDE default shell."
  (interactive)
  (let ((launchshell (or override equake-default-shell))
        (equake-open-non-terminal-in-new-frame nil))
    (if (not (equake--launch-shell launchshell))
        (let ((inhibit-message t))
          (message "No such shell or relevant shell not installed."))
      (buffer-face-set 'equake-buffer-face)
      (let* ((monitor (equake--get-monitor))
             (new-tab (current-buffer))
             (tab-no (1+ (alist-get monitor equake--max-tab-no -1)))
             (tab-name (number-to-string tab-no)))
        (setf (alist-get monitor equake--max-tab-no) tab-no)
        (cl-callf -snoc (alist-get monitor equake--tab-list) new-tab)
        (puthash new-tab
                 `((monitor . ,monitor)
                   (tab-name . ,tab-name)
                   ,@(when (memq launchshell '(rash nshell hilbish))
                       `((shell-type . ,launchshell))))
                 equake--tab-properties)
        (equake--rename-tab tab-name)
        (equake-mode 1) ; set Equake minor mode for buffer
        (equake--update-mode-line monitor)
        (equake--record-frame-history))))) ; make sure to record new tab

(defun equake-move-tab-right ()
  "Move current tab one position to the right."
  (interactive)
  (let* ((monitor (equake--get-tab-property 'monitor))
          (etab-list (alist-get monitor equake--tab-list)))
    (equake--shift-item etab-list (current-buffer) +1)
    (equake--update-mode-line monitor)))

(defun equake-move-tab-left ()
  "Move current tab one position to the left."
  (interactive)
  (let* ((monitor (equake--get-tab-property 'monitor))
          (etab-list (alist-get monitor equake--tab-list)))
    (equake--shift-item etab-list (current-buffer) -1)
    (equake--update-mode-line monitor)))

(defun equake-next-tab ()
  "Switch to the next tab."
  (interactive)
  (let* ((monitor (equake--get-tab-property 'monitor))
          (next-tab (equake--find-next-tab monitor (current-buffer)))
          (equake-open-non-terminal-in-new-frame nil))
    (if (eq next-tab (current-buffer))
        (print "No other tab to switch to.")
      (switch-to-buffer next-tab))))

(defun equake-prev-tab ()
  "Switch to the previous tab."
  (interactive)
  (let* ((monitor (equake--get-tab-property 'monitor))
          (prev-tab (equake--find-next-tab monitor (current-buffer) -1))
          (equake-open-non-terminal-in-new-frame nil))
    (if (eq prev-tab (current-buffer))
        (print "No other tab to switch to.")
      (switch-to-buffer prev-tab))))

(defun equake-rename-etab ()
  "Rename current Equake tab."
  (interactive)
  (when-let* ((old-name (equake--get-tab-property 'tab-name))
              (new-name (read-string "Enter a new tab name: " nil nil old-name)))
    (equake--rename-tab new-name)))

(defun equake-restore-last-etab ()
  "Restore last visited etab in Equake frame."
  (interactive)
  (let ((monitor (equake--get-tab-property 'monitor)))
    (if equake-mode
        (message "Currently in an Equake tab already.")
      (switch-to-buffer (alist-get monitor equake--last-tab)))))

(defun equake-close-tab-without-query ()
  "Close the current Equake tab/buffer without querying."
  (interactive)
  (if (equake--tab-p)
      (let ((kill-buffer-query-functions nil))
        (kill-buffer (current-buffer)))
    (message "Not an Equake tab.")))

(defun equake--on-kill-buffer ()
  "Things to do when an Equake buffer is killed." ; TODO: prevent last equake tab from being killed?
  (when equake-mode
    (let ((killed-tab (current-buffer))
          (monitor (equake--get-tab-property 'monitor)))
      (when (frame-parameter nil 'equakep) ; if we're in an equake frame,
        (switch-to-buffer (equake--find-next-tab monitor killed-tab)))
      (cl-callf2 delq killed-tab (alist-get monitor equake--tab-list))
      (equake--update-mode-line monitor)
      (when (and equake-close-frame-after-last-etab-closes ;; if user-chosen and
                 (null (cdr (assoc monitor equake--tab-list)))) ;; if no more etabs,
        (setf (alist-get monitor equake--max-tab-no) -1) ;; reset the "highest tab number" and
        ;; destroy the corresponding equake frame:
        (delete-frame (select-frame-by-name (concat "*EQUAKE*[" (symbol-name monitor) "]")))))))

(defun equake--tab-p (&optional buffer)
  "Return t if BUFFER is an Equake tab."
  (buffer-local-value 'equake-mode (or buffer (current-buffer))))

(defvar equake--tab-properties
  (make-hash-table :test #'eq :weakness 'key))

(defun equake--get-tab-properties (&optional buffer)
  "Get properties of an Equake tab BUFFER.
Properties include its monitor name and tab number.

If BUFFER is omitted or nil use `current-buffer'.

If BUFFER is not an Equake tab return nil."
  (gethash (or buffer (current-buffer)) equake--tab-properties))

(gv-define-setter equake--get-tab-properties (v &optional b)
  `(puthash (or ,b (current-buffer)) ,v equake--tab-properties))

(defun equake--get-tab-property (property &optional buffer)
  "Get PROPERTY of an Equake tab BUFFER.
See `equake--get-tab-properties'."
  (alist-get property (equake--get-tab-properties buffer)))

(gv-define-setter equake--get-tab-property (v p &optional b)
  `(setf (alist-get ,p (equake--get-tab-properties ,b)) ,v))

(defun equake--find-next-tab (monitor tab &optional offset)
  "Return a tab following TAB on MONITOR.

If OFFSET is a number, instead of a following tab, return such a
tab that its index is the index of TAB + OFFSET (possibly wrapped
around).

OFFSET might be negative."
  (let* ((offset (or offset +1))
         (etab-list (alist-get monitor equake--tab-list))
         (current-index (-elem-index tab etab-list))
         (next-index (mod (+ offset current-index) (length etab-list))))
    (elt etab-list next-index)))

(defun equake--rename-tab (base-name)
  "Rename the current buffer (presumed Equake tab) to BASE-NAME.
The actual buffer name is changed to some unique name that
includes BASE-NAME."
  (setf (equake--get-tab-property 'tab-name) base-name)
  (let ((monitor (equake--get-tab-property 'monitor)))
    (rename-buffer (format "*Equake[%s]*<%s>" monitor base-name) t)))

;;; Mode line
(defun equake--update-mode-line (monitor)
  "Update the Equake mode line on MONITOR."
  (let* ((etab-list (alist-get monitor equake--tab-list))
         (tabs-part (mapconcat #'equake--format-tab etab-list "  "))
         (initial-part (if equake-show-monitor-in-mode-line
                           (format "%s:" monitor) ""))
         (shell-type (or (equake--get-tab-property 'shell-type)
                         major-mode))
         (final-part
          (equake--style-shell-type
           (or (equake--get-tab-property 'shell-type)
               major-mode)))
         (format (string-join `(,initial-part ,tabs-part ,final-part) " ")))
    (setq mode-line-format format)
    (force-mode-line-update)))

(defun equake--style-shell-type-svg (shell)
  "Style the shell-type indicator as per SHELL."
  (pcase shell
    ((or 'rash 'equake-rash-mode)
     (propertize "((rash))" 'face 'equake-shell-type-rash))
    ((or 'nshell 'nshell-mode)
     (propertize "((nshell))" 'face 'equake-shell-type-nshell))
    ((or 'hilbish 'hilbish-mode)
     (propertize "((hilbish))" 'face 'equake-shell-type-hilbish))
    ('vterm-mode
     (propertize "((vterm))" 'face 'equake-shell-type-vterm))
    ('eshell-mode
     (propertize "((eshell))" 'face 'equake-shell-type-eshell))
    ('term-mode
     (propertize "((term))" 'face 'equake-shell-type-term))
    ('shell-mode
     (propertize "((shell))" 'face 'equake-shell-type-shell))
    ('ghostel-mode
     (propertize "((ghostel))" 'face 'equake-shell-type-ghostel))
    ('eat-mode
     (propertize "((eat))" 'face 'equake-shell-type-eat))))

(defun equake--format-tab (tab)
  "Format an Equake TAB for the mode line."
  (let* ((tab-name (equake--get-tab-property 'tab-name tab))
         (tab-active-p (eq tab (current-buffer)))
         (face (if tab-active-p 'equake-tab-active 'equake-tab-inactive)))
    (propertize (concat "[ " tab-name " ]") 'face face))) ; for ghostel


;;; Frames

(defvar equake--frame ()
  "A monitor to Equake frame mapping.")

(defvar equake--last-buffer ()
  "A monitor to last visited buffer mapping.")

(defvar equake--win-history ()
  "A monitor to window history mapping.")

(defvar equake--last-tab ()
  "A monitor to last visited Equake tab mapping.")

(defun equake--get-monitor (&optional frame)
  "Get a name of the monitor of FRAME as a symbol (i.e. `intern'ed).

If there is no name (e.g. in a terminal), return nil.

See `equake--get-monitor-attribute'."
  (when-let* ((name (equake--get-monitor-attribute 'name frame)))
    (intern name)))

(defun equake--get-monitor-attribute (attr &optional frame)
  "Get an attribute ATTR of the monitor of FRAME.

If FRAME is omitted or nil, get an attribute of the monitor under
the mouse cursor."
  (if frame
      (frame-monitor-attribute attr frame)
    (let* ((pos (mouse-absolute-pixel-position))
           (x (car pos))
           (y (cdr pos)))
      (frame-monitor-attribute attr nil x y))))

(defun equake--record-frame-history ()
  "Record important properties of the current frame.

The current frame is presumed to be an Equake frame.  We store
several parameters of it (e.g window history, last visited buffer
etc) in variables, in order to be able to restore them when the
frame is destroyed."
  (let ((monitor (equake--get-monitor (selected-frame))))
    (when (equake--tab-p (current-buffer))
      (setf (alist-get monitor equake--last-buffer) (current-buffer))
      (setf (alist-get monitor equake--win-history) (window-prev-buffers)))
    (when (and equake-mode (equake--tab-p (current-buffer)))
      (setf (alist-get monitor equake--last-tab) (current-buffer)))))

(defun equake--hide-or-destroy-frame (current-frame)
  "Hide or destroy CURRENT-FRAME, depending on `equake-use-frame-hide'."
  (select-frame current-frame)
  (equake--record-frame-history)
  (if equake-use-frame-hide ; if user has make-frame-(in)visible option set
      (progn ;; double-tap, otherwise frame lands in limbo
        (make-frame-invisible current-frame)
        (make-frame-invisible current-frame))
    (delete-frame current-frame)))

(defun equake--set-up-new-frame ()
  "Begin new Equake frame setup, including cosmetic alterations."
  ;; N.B. the resulting frame should be marked as a finished Equake
  ;; frame only when it's fully configured. That means,
  ;; `(set-frame-parameter frame 'equakep t)' only at the end of
  ;; initialization. Otherwise, things will break.
  (let* ((frame (equake--make-new-frame))
         (monitor (equake--get-monitor frame)))
    (setf (alist-get monitor equake--frame) frame)
    (select-frame frame)
    (equake--finish-equake-frame-setup frame monitor)))

(defun equake--transform-existing-frame-into-equake-frame ()
  "Transform an existing frame into an Equake frame.
For GNOME Shell under Wayland, used with an emacsclient call."
  ;; N.B. the resulting frame should be marked as a finished Equake
  ;; frame only when it's fully configured. That means,
  ;; `(set-frame-parameter frame 'equakep t)' only at the end of
  ;; initialization. Otherwise, things will break.
  (let* ((frame (selected-frame))
         (monitor (equake--get-monitor frame))
         (workarea (equake--get-monitor-attribute 'workarea)))
    (setf (alist-get monitor equake--frame) frame)
    (modify-frame-parameters frame (equake--make-frame-parameters monitor workarea))
    (when (and (executable-find "wmctrl") (not equake-close-frame-on-focus-loss))
      (shell-command "wmctrl -r :ACTIVE: -b toggle,above"))
    (equake--finish-equake-frame-setup frame monitor)))

(defun equake--finish-equake-frame-setup (frame monitor)
  "Common operations for setting up Equake frames."
  (unless (alist-get monitor equake--tab-list)
    (equake-new-tab))
  (->> (alist-get monitor equake--win-history)
       (equake--filter-history)
       (set-window-prev-buffers nil))
  (when-let* ((last-tab (alist-get monitor equake--last-tab)))
    (switch-to-buffer last-tab))
  (when-let* ((last-buffer (alist-get monitor equake--last-buffer)))
    (switch-to-buffer last-buffer))
  (unless (equake--tab-p) ; make sure to restore to an Equake buffer
    (bury-buffer))
  (buffer-face-set 'equake-buffer-face)
  (when equake-hide-from-taskbar-choice
    (equake--hide-from-taskbar))
  (raise-frame)
  (set-frame-parameter frame 'equakep t)) ; mark a finished Equake frame


(defun equake--make-new-frame ()
  "Make a new Equake frame on a current monitor on a current display.

If the display is not graphic make a frame on some monitor using
its workarea."
  (if-let* ((monitor (equake--get-monitor))
           (workarea (equake--get-monitor-attribute 'workarea)))
      (make-frame (equake--make-frame-parameters monitor workarea))
    (equake--make-new-frame-when-no-monitor)))

(defun equake--make-new-frame-when-no-monitor ()
  "Make a graphical Equake frame on some monitor.

When there are no graphical frames on a monitor we can't
determine explicitly what the monitor name is.  That means we
can't tell Emacs to create a frame on this exact monitor.  In
this case we just create some graphical frame (with an utility of
`equake--get-display') and determine a monitor name after the
fact."
  (let* ((new-frame (make-frame-on-display (equake--get-display)))
         (monitor (equake--get-monitor new-frame))
         (workarea (equake--get-monitor-attribute 'workarea new-frame))
         (frame-parameters (equake--make-frame-parameters monitor workarea)))
    (modify-frame-parameters new-frame frame-parameters)
    new-frame))

(defun equake--make-frame-parameters (monitor target-workarea)
  "Make an alist of parameters for an Equake frame.
Given that this frame is going to end up on a monitor MONITOR
with workarea TARGET-WORKAREA, make an alist of parameters
suitable for `make-frame' or `modify-frame-parameters'"
  (let* ((mon-xpos (nth 0 target-workarea))
         (mon-ypos (nth 1 target-workarea))
         (mon-width (nth 2 target-workarea))
         (mon-height (nth 3 target-workarea))
         (x-offset (/ (- mon-width (* mon-width equake-size-width)) 2))
         (frame-xpos (floor (+ mon-xpos x-offset)))
         (frame-width (truncate (* mon-width equake-size-width)))
         (frame-height (truncate (* mon-height equake-size-height))))
    (list (cons 'name (format "*EQUAKE*[%s]" monitor))
          (cons 'alpha `(,equake-opacity-active ,equake-opacity-inactive))

          (cons 'user-position t)
          (cons 'left frame-xpos)
          (cons 'top mon-ypos)

          (cons 'user-size t)
          (cons 'width (cons 'text-pixels frame-width))
          (cons 'height (cons 'text-pixels frame-height))

          (cons 'menu-bar-lines 0)
          (cons 'tool-bar-lines 0)

          (cons 'auto-raise t)
          (cons 'skip-taskbar equake-hide-from-taskbar-choice)
          (cons 'undecorated t)
          (cons 'fullscreen nil))))

;;; DISPLAY guessing

(defun equake--get-display ()
  "Get a graphical display name.

It's useful when the DISPLAY environment variable is unset or set
incorrectly.  This issue arises when managing an Emacs daemon with
systemd.

First, we try to connect to the DISPLAY from the environment.  If
that doesn't work we try DISPLAY from the persistent file on a
disk (see `equake--read-display-from-disk').  At last, if
everything else fails we try possible DISPLAY values from
`equake-display-guess-list' which can be adjusted by a user.  If
that fails as well, we signal an error."
  (let ((candidates `(,(getenv "DISPLAY")
                      ,(equake--read-display-from-disk)
                      ,@equake-display-guess-list)))
    (if-let* ((display (-first #'equake--display-exists-p candidates)))
        display
      (error "Equake: can't access a working DISPLAY, please, open a graphical frame first"))))

(defun equake--read-display-from-disk ()
  "Read DISPLAY value from `equake-persistent-display-file'.

See `equake--update-persistent-display-file'."
  (condition-case nil
      (with-temp-buffer
        (insert-file-contents-literally equake-persistent-display-file)
        (buffer-string))
    (file-missing nil)))

(defun equake--update-persistent-display-file (frame)
  "Update a display value in the persistent file based on that of FRAME.

Meant to be hooked to `after-make-frame-functions'.

Since there is no obvious way to reliably get a display value
when it's not set in the environment, we have to use a heuristic.
Every time a graphical frame is opened we store its display value
in `equake-persistent-display-file'.  As long as we don't change
a display, this value remains valid and we can safely and
properly launch Equake at all times.

This approach does not eliminate the problem completely, since
there is still a corner case when a user tries to invoke Equake
on a new display before any other graphical frames have been
launched."
  (if-let* ((display (frame-parameter frame 'display)))
      (write-region display nil equake-persistent-display-file)))

(defun equake--display-exists-p (display)
  "Check if it's possible to connect to DISPLAY.

For some reason, we need to close connection right after opening
it, otherwise `make-frame-on-display' just hangs Emacs.  The
reason remains to be determined."
  (condition-case nil
      (progn (x-open-connection display) (x-close-connection display) t)
    (error nil)))

;;; Close (hide or destroy) equake frame when it loses focus

(defvar equake--last-frame-focus-state nil
  "Last known focus state of the equake frame.
Used to compare to the current state to determine if focus has been lost.")

(defun equake--after-focus-change ()
  "Compare the equake frame's last known focus state to the current one.
If focus is lost, hide or destroy the frame."
  (setq equake--focus-change-timer nil)
  (let ((frame (alist-get (equake--get-monitor) equake--frame)))
    (if (frame-live-p frame)
        (let ((state (with-no-warnings (frame-focus-state frame))))
          (when (and equake--last-frame-focus-state (not state))
            (setq equake--last-frame-focus-state state)
            ;; (message "lost focus")
            (equake--hide-or-destroy-frame frame))
          (when (and (not equake--last-frame-focus-state) state)
            (setq equake--last-frame-focus-state state)
            ;; (message "gained focus")
            ))
      ;; (message "dead frame")
      (setq equake--last-frame-focus-state nil))))

(defvar equake--focus-change-timer nil
  "Holds the scheduled call to `equake--after-focus-change'.")

(defvar equake--focus-change-debounce-delay 0.015
  "Delay in seconds to use when debouncing focus change events.
Window manager may send spurious focus change events.  To filter
them, the code delays handling of focus-change events by this
number of seconds.  Based on rudimentary testing, 0.015 (i.e. 15
milliseconds) is a good compromise between performing the
filtering and introducing a visible delay.)")

(defun equake--after-focus-change-hook ()
  "Schedule a call to `equake--after-focus-change', which does the real work.
The schedule is delayed by `equake--focus-change-debounce-delay' to de-bounce
spurious focus change events from the window manager.  This scheduling, and
hence the feature, is enabled if `equake-close-frame-on-focus-loss' is non-nil."
  (when equake-close-frame-on-focus-loss
    (and equake--focus-change-timer (cancel-timer equake--focus-change-timer))
    (setq equake--focus-change-timer
          (run-with-timer equake--focus-change-debounce-delay nil
                          #'equake--after-focus-change))))

(add-function :after after-focus-change-function #'equake--after-focus-change-hook)

;;; Rest

(defun equake--hide-from-taskbar ()
  "Hide Equake from the taskbar."
  (let ((frame (alist-get (equake--get-monitor) equake--frame)))
    (when (executable-find "xprop")
      (shell-command (concat "xprop -name "
                           (shell-quote-argument (frame-parameter frame 'name))
                           " -f _NET_WM_STATE 32a -set _NET_WM_STATE _NET_WM_STATE_SKIP_TASKBAR")))))

(defun equake--select-some-graphic-frame ()
  "Try to select some graphic frame.

Its purpose is to move selection from non-graphical frames.  Many
functions for working with monitors implicitly rely on a display
of a selected frame.  If the frame is non-graphical, they work in
unexpected ways.  This function is designed to be called right
before invoking an Equake frame, which is going to change
selection anyway.  Thus, selection change is of no concern."
  (if-let* ((graphic-frame (-first #'display-graphic-p (frame-list))))
      (select-frame graphic-frame t)))

(defun equake--shift-item (list item shift)
  "Shift \='ITEM\=' in \='LIST\=' by \='SHIFT\=' places.

Perform shifting as if swapping \='ITEM\=' with its adjacent element
until \='ITEM\=' takes the place it's supposed to take.

E.g. (equake--shift-item \='(1 2 3 4 5) 1 2)  -> (2 3 1 4 5)
     (equake--shift-item \='(1 2 3 4 5) 1 -1) -> (2 3 4 5 1)
     (equake--shift-item \='(1 2 3 4 5) 1 8) -> (2 3 4 1 5)"
  (let* ((i (-elem-index item list))
         (j (mod (+ i shift) (length list))))
    (if (< i j) ; shift the range by one
        (setf (cl-subseq list i j) (cl-subseq list (1+ i) (1+ j)))
      (setf (cl-subseq list (1+ j) (1+ i)) (cl-subseq list j i)))
    (setf (elt list j) item))) ; shift the last element

(defun equake--filter-history (history)
  "Filter out non-Equake buffers from HISTORY.

HISTORY is of format given by `window-prev-buffers'."
  (--filter (equake--tab-p (car it)) history))

(defun equake--on-buffer-list-update ()
  "Things to do when in Equake when the current buffer is changed."
  (when (frame-parameter nil 'equakep)  ; if Equake frame
    (equake--record-frame-history))
  (when-let* ((monitor (equake--get-tab-property 'monitor))) ; if Equake tab
    (equake--update-mode-line monitor)
    (modify-frame-parameters nil '((vertical-scroll-bars . nil)
                                   (horizontal-scroll-bars . nil)))))


;;; Shell launching

(defconst equake-shell-terminal-backends
  '(ghostel vterm eat shell)
  "Terminal backends, in order of preference.")

(defun equake--shell-backend-available-p (backend)
  "Return non-nil if BACKEND is available."
  (pcase backend
    ('ghostel (require 'ghostel nil t))
    ('vterm   (require 'vterm nil t))
    ('eat     (require 'eat nil t))
    ('shell   t)))

(defun equake--launch-shell-terminal (backend program args)
  "Launch PROGRAM with ARGS using BACKEND.
Return the resulting buffer, or nil if BACKEND is unavailable."
  (when (equake--shell-backend-available-p backend)
    (pcase backend
      ('ghostel
       (let ((ghostel-shell (cons program args)))
         (ghostel t)))

      ('vterm
       (let ((vterm-shell program)
             (vterm-shell-args args))
         (vterm)
         (current-buffer)))

      ('eat
       (let ((buffer (generate-new-buffer
                      (format "*equake-%s*" (file-name-nondirectory program)))))
         (with-current-buffer buffer
           (eat-mode)
           (eat-exec buffer (buffer-name buffer) program nil args))
         (switch-to-buffer buffer)
         buffer))

      ('shell
       (let ((explicit-shell-file-name program)
             (explicit-shell-args args))
         (shell)
         (delete-other-windows)
         (current-buffer))))))

(defun equake--launch-shell-with-fallback (program args)
  "Launch PROGRAM with ARGS using the first available terminal backend."
  (catch 'launched
    (dolist (backend equake-shell-terminal-backends)
      (condition-case err
          (let ((buffer (equake--launch-shell-terminal
                         backend program args)))
            (when (buffer-live-p buffer)
              (throw 'launched buffer)))
        (error
         (message "Equake: %s failed: %s"
                  backend (error-message-string err)))))
    nil))

(defcustom equake-shell-terminal-backends
  '(ghostel vterm eat shell)
  "Terminal backends, in order of preference."
  :type '(repeat symbol)
  :group 'equake)



(defun equake--launch-shell (launchshell)
  "Launch a new shell session.
LAUNCHSHELL selects the non-default shell."
  (interactive)
  (let ((sh-command (if (equal equake-default-sh-command "")
                        shell-file-name
                      equake-default-sh-command))
        (success t)
        buffer)
    (setq buffer
          (pcase launchshell
            ('eshell
             (eshell 'N)
             (current-buffer))
            ('vterm
             (when (require 'vterm nil t)
               (vterm)
               (current-buffer)))
            ('ghostel
             (when (require 'ghostel nil t)
               (ghostel t)))
            ('eat
             (when (require 'eat nil t)
               (let ((buf (eat nil '(4))))
                 (when (buffer-live-p buf)
                   (switch-to-buffer buf)
                   (set-buffer buf)
                   buf))))
            ((or 'rash 'nshell 'hilbish)
             (let* ((spec (assq launchshell equake-external-shells))
                    (program (plist-get (cdr spec) :program))
                    (args (plist-get (cdr spec) :args))
                    (mode (plist-get (cdr spec) :mode))
                    (executable (and program (executable-find program))))
               (when executable
                 (let ((buf (equake--launch-shell-with-fallback
                             executable args)))
                   (when (buffer-live-p buf)
                     (when mode
                       (with-current-buffer buf
                         (funcall mode)))
                     buf)))))
            ('ansi-term
             (ansi-term sh-command))
            ('term
             (term sh-command))
            ('shell
             (shell)
             (delete-other-windows)
             (when equake-shell-mode-setup
               (comint-send-string nil equake-shell-mode-setup))
             (current-buffer))
            (_ nil)))
    (unless (buffer-live-p buffer)
      (setq success nil))
    success))

;;; Orchestration
;; Prevent Eat/Ghostel semi-char-mode from swallowing Equake tab keybindings.
(declare-function eat-update-semi-char-mode-map "ext:eat")
(defvar eat-semi-char-non-bound-keys)

;; Various co-ordination hooks.
(add-hook 'equake-mode-hook #'equake-inhibit-message-locally)
(add-hook 'buffer-list-update-hook #'equake--on-buffer-list-update)
(add-hook 'kill-buffer-hook #'equake--on-kill-buffer)
(add-hook 'after-make-frame-functions #'equake--update-persistent-display-file)


(provide 'equake)

;;; equake.el ends here

;;; kfg.el --- an emacs configuration system
;;
;; Author: Austin Bingham <austin.bingham@gmail.com>
;; Version:
;; URL: https://github.com/abingham/kfg
;;
;; This file is not part of GNU Emacs.
;;
;; Copyright (c) 2014 Austin Bingham
;;
;;; Commentary:
;;
;; Description:
;;
;; The kfg emacs configuration system.
;;
;; This is the engine for a module emacs configuration system. Various
;; configuration modules should go in the "modules" directory. Put any
;; miscellaneous elisp files you need in the "elisp" directory. Then
;; execute this file.
;;
;; For more details, see the project page at
;; https://github.com/abingham/kfg.
;;
;; Installation:
;;
;; Copy kfg.el to some location in your emacs load path. Then add
;; "(require 'kfg)" to your emacs initialization (.emacs,
;; init.el, or something). Or just install the kfg package.
;; 
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:

(require 'cl)
(require 'package)

(defun kfg:dir-contents (dir)
  (remove "." (remove ".." (directory-files dir))))

(defun kfg:join (&rest comps)
  (if comps
      (let* ((rcomps (reverse comps))
             (dir-parts (mapcar 'file-name-as-directory (cdr rcomps)))
             (dir (apply 'concat (reverse dir-parts))))
        (concat dir (car rcomps)))
    ""))

(defun kfg:init-module (modules_dir module_name)
  "Initialize the module MODULE_NAME in MODULES_DIR. Returns a
list (NAME ENABLED (PACKAGE. . .))"
  (let ((init_file (kfg:join modules_dir module_name "init.el")))
    (if (file-exists-p init_file)
        (with-temp-buffer
          (insert-file-contents init_file)
          (cons (cons :module module_name)
                (eval (read (buffer-string)))))
      (progn
        (warn (format "No init.el for %s" module_name))
        (list (cons :module module_name) (cons :enabled nil) (list :packages))))))

(defun kfg:init-modules (modules_dir)
  "Initialize all of the modules found in MODULES_DIR. Returns a
list of module configs."
  (mapcar (lambda (d) (kfg:init-module modules_dir d))
          (kfg:dir-contents modules_dir)))

(defun kfg:enabled-modules (configs)
  (remove-if-not (lambda (c) (cdr (assoc :enabled c))) configs))

(defun kfg:find-all-packages (configs)
  "Find all packages required by enabled modules in the list of
module configs CONFIG. Returns the resulting set of
packages (i.e. no duplications.)"
  (delete-dups
   (apply 'append
          (mapcar (lambda (c) (cdr (assoc :packages c)))
                  (kfg:enabled-modules configs)))))

(defun kfg:install-packages (pkgs)
  "Install any packages in PKGS that are not installed. If any
packages need to be installed, the package index is updated
first."
  (unless (every 'package-installed-p pkgs)
    ;;check for new packages (package versions)
    (message "%s" "Missing packages detected. Refreshing its package database...")
    (package-refresh-contents)
    (message "%s" " done.")
    ;; install the missing packages
    (dolist (p pkgs)
      (when (not (package-installed-p p))
        (package-install p)))))

(defun kfg:configure-modules (modules_dir configs)
  (dolist (c (kfg:enabled-modules configs))
    (let* ((module_name (cdr (assoc :module c)))
           (config_file (kfg:join modules_dir module_name "config.el")))
      (if (file-exists-p config_file)
          (load-file config_file)
        (warn (format "No config.el for %s" module_name))))))

(defun kfg:initialize (root_dir)
  (let* ((modules_dir (kfg:join root_dir "modules"))
         (module_config (kfg:init-modules modules_dir))
         (packages (kfg:find-all-packages module_config)))
    (add-to-list 'load-path (kfg:join root_dir "elisp"))
    (package-initialize)
    (kfg:install-packages packages)
    (kfg:configure-modules modules_dir module_config)))

(provide 'kfg)



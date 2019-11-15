(require 'avy)
(require 'cl)
(require 'dash)
(require 'f)
(require 'org)
(require 's)
(require 'xenops-execute)
(require 'xenops-image)
(require 'xenops-math)
(require 'xenops-process)
(require 'xenops-text)
(require 'xenops-util)

(defvar xenops-cache-directory "/tmp/xenops-cache/"
  "Path to a directory in which xenops can save files.")

(defvar xenops-mode-map (make-sparse-keymap))

(define-minor-mode xenops-mode
  "A LaTeX editing environment.

\\{xenops-mode-map}"
  nil " xenops" nil
  (cond
   (xenops-mode
    (define-key xenops-mode-map "\C-c\C-c" #'xenops)
    (xenops-util-define-key-with-fallback "\C-y" #'xenops-handle-paste)
    (xenops-util-define-key-with-fallback [(super v)] #'xenops-handle-paste "\C-y")

    (xenops-image-activate)
    (xenops-math-activate)
    (xenops-text-activate))
   ;; Deactivate
   (t
    (xenops-math-deactivate))))

(defun xenops (&optional arg)
  (interactive "P")
  (cond
   ((equal arg '(16))
    (xenops-hide-images))
   ((equal arg '(4))
    (xenops-regenerate-images))
   (t (xenops-display-images))))

(defvar xenops-ops
  '((math . (:ops
             (xenops-math-display-image
              xenops-math-regenerate-image
              xenops-math-hide-image)
             :delimiters
             (("\\$" .
               "\\$")
              ("^[ \t]*\\\\begin{align\\*?}" .
               "^[ \t]*\\\\end{align\\*?}")
              ("^[ \t]*\\\\begin{tabular}" .
               "^[ \t]*\\\\end{tabular}"))))
    (image . (:ops
              (xenops-image-display-image
               xenops-image-hide-image)
              :delimiters
              (("[ \t]*\\\\includegraphics\\(\\[[^]]+\\]\\)?{\\([^}]+\\)}"))))))

(defun xenops-display-images ()
  (interactive)
  (xenops-process '(xenops-math-display-image
                    xenops-image-display-image)))

(defun xenops-display-images-if-cached ()
  (let (fn (symbol-function 'xenops-math-display-image))
    (cl-letf (((symbol-function 'xenops-display-images)
               (lambda (element) (funcall fn 'cached-only)))))
    (xenops-display-images)))

(defun xenops-regenerate-images ()
  (interactive)
  (xenops-process '(xenops-math-regenerate-image)))

(defun xenops-hide-images ()
  (interactive)
  (xenops-process '(xenops-math-hide-image
                    xenops-image-hide-image)))

(defun xenops-handle-paste ()
  (interactive)
  (or (xenops-math-handle-paste)
      (xenops-image-handle-paste)))

(defun xenops-display-images-headlessly ()
  "Run `xenops-display-images' in a headless emacs process."
  (cl-letf (((symbol-function 'org--get-display-dpi) (lambda () 129))
            ((symbol-function 'org-latex-color)
             (lambda (attr)
               (case attr
                 (:foreground "0,0,0")
                 (:background "1,1,1")
                 (t (error "Unexpected input: %s" attr))))))
    (xenops-display-images)))

(defun xenops-avy-goto-math ()
  (interactive)
  (let (avy-action) (xenops-avy-do-at-math)))

(defun xenops-avy-copy-math-and-paste ()
  (interactive)
  (let ((element)
        (avy-action
         (lambda (pt)
           (save-excursion
             (goto-char
              ;; TODO: hack: This should be just `pt`, but inline
              ;; math elements are not recognized when point is on
              ;; match for first delimiter.
              (1+ pt))
             (setq element (xenops-math-parse-element-at-point))
             (when element (xenops-math-copy element)))
           (when element
             (save-excursion (xenops-math-paste))))))
    (xenops-avy-do-at-math)))

(defun xenops-avy-do-at-math ()
  (avy-jump (xenops-math-get-math-element-begin-regexp)))

(provide 'xenops)

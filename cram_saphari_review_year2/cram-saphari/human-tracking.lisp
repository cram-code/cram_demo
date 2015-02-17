;;; Copyright (c) 2015, Georg Bartels <georg.bartels@cs.uni-bremen.de>
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;;
;;; * Redistributions of source code must retain the above copyright
;;; notice, this list of conditions and the following disclaimer.
;;; * Redistributions in binary form must reproduce the above copyright
;;; notice, this list of conditions and the following disclaimer in the
;;; documentation and/or other materials provided with the distribution.
;;; * Neither the name of the Institute for Artificial Intelligence/
;;; Universitaet Bremen nor the names of its contributors may be used to 
;;; endorse or promote products derived from this software without specific 
;;; prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package :cram-saphari)

;;;
;;; TEST DATA
;;;

(defparameter *humans-fluent* 
  (cram-language-implementation:make-fluent :name "humans-fluent"))

(defparameter *tracker-fluent* nil)

(defparameter *test-percept0*
  `(:user-id -1 :stamp 1.0 :frame-id "some-frame" :bodyparts nil))

(defparameter *test-percept1*
  `(:user-id -1 :stamp 2.0 :frame-id "some-frame" :bodyparts nil))

(defparameter *test-percept2*
  `(:user-id 1 :stamp 3.0 :frame-id "some-frame" :bodyparts (:knee :hand)))

(defparameter *test-percept3*
  `(:user-id 1 :stamp 4.0 :frame-id "some-frame" :bodyparts (:knee :hand)))

(defparameter *test-percept4*
  `(:user-id -1 :stamp 5.0 :frame-id "some-frame" :bodyparts nil))

(defparameter *test-percepts*
  (list *test-percept0* *test-percept1* *test-percept2* *test-percept3* *test-percept4*))

(defparameter *test-desig0*
  (make-designator 'human '((:tracker :openni))))

(defparameter *test-desig1*
  (make-effective-designator
   *test-desig0*
   :new-properties (merge-desig-descriptions *test-desig0* '((:user-id 1)))
   :data-object *test-percept2*))

(defparameter *test-desigs*
  (list *test-desig0* *test-desig1*))

;;;
;;; ACTUAL HUMAN DESIGNATOR STUFF
;;;

(defun human-detected-p (human-percept)
  "Predicate to check whether `human-percept' represents a detected human."
  (and (getf human-percept :user-id)
       (not (= (getf human-percept :user-id) -1))))

(defun human-percept-matches-desig-p (human-percept human-desig)
  "Predicate checking whether `human-percept' matches the description of `human-desig'."
  (and (getf human-percept :user-id)
       (desig-prop-value human-desig :user-id)
       (= (desig-prop-value human-desig :user-id)
          (getf human-percept :user-id))))

(defun human-desig-too-old-p (desig now timeout)
  (declare (type cram-designators:human-designator desig))
  (let ((last-timestamp (desig-prop-value desig :last-detected)))
    (and last-timestamp (> (- now last-timestamp) timeout))))

(defun find-matching-human-desig (human-percept human-desigs)
  "Returns the designator in `human-desigs' which matches `human-percept'."
  (find human-percept human-desigs :test #'human-percept-matches-desig-p))

(defun remove-old-human-desigs (desigs &key (timeout 0.5) (now (roslisp:ros-time)))
  "Checks whether any of the human designators in `desigs' has not been detected 
 for more than `timeout' seconds. Uses `now' as the current timestamp. Any designator 
 that is old will be removed from `desigs'. Returns the new list of desigs."
  (declare (type list desigs))
  (remove-if (alexandria:rcurry #'human-desig-too-old-p now timeout) desigs))

(defun add-new-human-desig (percept desigs)
  "Creates a new human designator out of `percept' and appends it to the list
 human designators `desigs'. `percept' shall be a plist. Returns the new `desigs'."
  (declare (type list percept desigs))
  ;; (format t "~%~%ADDING NEW HUMAN~%~%")
  (let ((new-desig 
          (make-designator 'human `((:tracker :openni)
                                    (:user-id ,(getf percept :user-id))
                                    (:tf-prefix ,(make-human-tf-prefix (getf percept :user-id)))
                                    (:first-detected ,(getf percept :stamp))
                                    (:last-detected ,(getf percept :stamp))))))
    (let ((effective-desig
            (equate new-desig (make-effective-designator new-desig :data-object percept))))
      (cons effective-desig desigs))))

(defun update-existing-desig (percept desigs)
  "Updates the first human designator in the list of human designators `desigs' which
 matches `percept' with a new effective designator. Assumes such a matching designator
 exists. Returns the new `desigs'."
  (let* ((old-desig (find-matching-human-desig percept desigs))
         (new-description (merge-desig-descriptions old-desig `((:last-detected ,(getf percept :stamp)))))
         (new-desig (make-effective-designator 
                     old-desig :new-properties new-description :data-object percept)))
    (equate old-desig new-desig)
    (substitute new-desig old-desig desigs)))

(defun update-human-desigs (percept desigs)
  ;; TODO(Georg): comment me!
  (when (human-detected-p percept)
    (if (find-matching-human-desig percept desigs)
        ;; CASE 1: PERCEPT AND MATCHING DESIG -> UPDATE DESIG
        (update-existing-desig percept desigs)
        ;; CASE 2: PERCEPT AND NO MATCHING DESIG -> ADD DESIG
        (add-new-human-desig percept desigs)))
  ;; CASE 3 (implicit): NO PERCEPT -> FORGET ABOUT ALL PRIOR DESIGS
  )

(defun human-close-p (human &optional (threshold 1.5))
  (labels ((get-min (sequence)
             (first (sort sequence #'<)))
           (calculate-human-distance (human)
             (get-min (mapcar (compose #'cl-transforms:x (rcurry #'getf :centroid))
                              (getf (reference human) :bodyparts)))))
    (< (calculate-human-distance human) threshold)))

(declare-goal track (human-desigs human-percept)
  (declare (ignore human-desigs human-percept)))

(def-goal (track ?human-desigs ?human-percept)
  (declare (type cram-language-implementation:fluent ?human-desigs ?human-percept))
  ;; (format t "Starting to track humans from percepts~%")
  (whenever ((pulsed ?human-percept))
    (setf (value ?human-desigs) (update-human-desigs (value ?human-percept) (value ?human-desigs)))
    (setf (value ?human-desigs) (remove-old-human-desigs (value ?human-desigs)))))

(defun begin-logging-human-intrusion (close-humans)
  (let ((id (beliefstate:start-node "HUMAN-INTRUSION" nil 2)))
    (mapcar (rcurry #'beliefstate:add-designator-to-node id) close-humans)
    id))

(defun finish-logging-human-intrusion (logging-id)
  (beliefstate:stop-node logging-id))

(cpl-impl::def-plan-macro with-human-monitoring ((human-percept) &body body)
  ;;; GIGANTIC HACK because I do not know how to make a proper macro..
  (with-gensyms (human-percept-sym)
    `(let ((,human-percept-sym ,human-percept))
       (execute-with-human-monitoring 
        ,human-percept-sym
        (lambda () ,@body)))))

(cpl-impl:def-cram-function execute-with-human-monitoring (human-percept main-lambda)
  (let ((human-desigs (make-fluent :name "human-desigs"))
        (close-humans (make-fluent :name "intruding-humans")))
    (cpl-impl:pursue
      (track human-desigs human-percept)
      
      (whenever ((pulsed human-desigs))
        (setf (value close-humans) (remove-if-not #'human-close-p (value human-desigs))))
        
      (:tag main-task (funcall main-lambda))
                      
      (whenever ((pulsed close-humans))
        (when (value close-humans)

          (let ((id (begin-logging-human-intrusion (value close-humans))))
            (format t "~%INTRUSION STARTED~%")
            (cpl:with-task-suspended (main-task)
              (cpl-impl:wait-for (cpl:eql close-humans nil)))
            (finish-logging-human-intrusion id)
            (format t "~%INTRUSION STOPPED~%~%~%")))))))

(cpl-impl:def-top-level-cram-function test-human-monitoring (demo-handle)
  (with-human-monitoring ((human-percept demo-handle))
    (cpl:sleep 10)))

(cpl-impl:def-top-level-cram-function test-suspend-motions (demo-handle)
  (with-slots (human-percept right-arm) demo-handle
    (with-human-monitoring (human-percept) 
      (cpl-impl:on-suspension (roslisp-beasty:stop-beasty right-arm)
        (cpl-impl:retry-after-suspension
          (roslisp-beasty:move-beasty-and-wait 
           right-arm (make-joint-goal '(0.52 -0.78 0.78 0.78 0.0 -0.78 0.0) nil)))))
    (with-human-monitoring (human-percept) 
      (cpl-impl:on-suspension (roslisp-beasty:stop-beasty right-arm)
        (cpl-impl:retry-after-suspension
          (roslisp-beasty:move-beasty-and-wait 
           right-arm 
           (make-cartesian-goal 
            (cl-transforms:make-transform
             (cl-transforms:make-3d-vector 0.359 0.459 0.533)
             (cl-transforms:axis-angle->quaternion
              (cl-transforms:make-3d-vector 0 1 0) PI)) nil)))))))
         
(cpl-impl:def-cram-function loop-beasty (right-arm)
  (loop for i upto 3 do
    (roslisp-beasty:move-beasty-and-wait 
     right-arm (make-joint-goal '(0.52 -0.78 0.78 0.78 0.0 -0.78 0.0) nil))
    (roslisp-beasty:move-beasty-and-wait 
     right-arm 
     (make-cartesian-goal 
      (cl-transforms:make-transform
       (cl-transforms:make-3d-vector 0.359 0.459 0.533)
       (cl-transforms:axis-angle->quaternion
        (cl-transforms:make-3d-vector 0 1 0) PI)) nil))))

(defclass cram-saphari-demo ()
  ((human-percept :initarg :human-percept :accessor human-percept)
   (human-sub :initarg :human-sub :accessor human-sub)
   (right-arm :initarg :right-arm :accessor right-arm)
   
))

(defun init-cram-saphari-demo ()
  (let* ((human-percept (make-fluent))
         (human-sub (subscribe "/saphari/human" "saphari_msgs/Human" 
                               (lambda (msg) (setf (value human-percept) (from-msg msg)))))
         (right-arm (roslisp-beasty:make-beasty-handle "right_arm" 1 1337)))
    (roslisp-beasty:beasty-switch-behavior right-arm (make-init-description nil))
    (roslisp-beasty:beasty-safety-reset right-arm (make-init-description nil))
    (make-instance 
     'cram-saphari-demo
     :human-percept human-percept
     :human-sub human-sub
     :right-arm right-arm)))
   
(defun main ()
  (with-ros-node ("saphari_demo")
    (test-human-monitoring (init-cram-saphari-demo))))

(defun dump-files ()
  (with-ros-node ("saphari_demo")
    (beliefstate:extract-files)))

;;
;; NICE WORKKING EXAMPLE
;;
;; (top-level
;;   (let ((fluent (make-fluent :value nil)))
;;     (cpl-impl:with-tags
;;       (cpl-impl:par
;;         (:tag suspending-task
;;           (cpl:sleep 0.5)
;;           (cpl-impl:with-task-suspended (suspended-task)
;;             (format t "successfully suspended task~%")))
;;         (:tag suspended-task
;;           (cpl-impl:on-suspension (setf (value fluent) t)
;;             (format t "starting task~%")
;;             (cpl-impl:wait-for fluent)
;;             (format t "stopping task~%")))))))
;;

;;
;; WEIRD BEHAVIOR #1
;;
;;
;; (top-level
;;   (cpl-impl:with-tags
;;     (cpl-impl:par
;;       (:tag suspending-task
;;         (cpl:sleep 0.5)
;;         (cpl-impl:with-task-suspended (suspended-task)
;;           (format t "successfully suspended task~%")))
;;       (:tag suspended-task
;;         (format t "starting task~%")
;;         (sleep 1)
;;         (format t "in the middle of task~%")
;;         (sleep 1)
;;         (format t "finishing task~%")))))
;;

;;
;; WEIRD BEHAVIOR #2
;;
;; (top-level
;;   (cpl-impl:with-tags
;;     (cpl-impl:par
;;       (:tag suspending-task
;;         (cpl:sleep 0.5)
;;         (cpl-impl:with-task-suspended (suspended-task)
;;           (format t "successfully suspended task~%")))
;;       (:tag suspended-task
;;         (format t "starting task~%")
;;         (cpl:sleep 1)
;;         (format t "in the middle of task~%")
;;         (cpl:sleep 1)
;;         (format t "finishing task~%")))))
;;
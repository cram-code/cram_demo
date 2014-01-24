;;; Copyright (c) 2014, Georg Bartels <georg.bartels@cs.uni-bremen.de>
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

(in-package :cram-saphari-review-year2)

(defparameter *start-config*
  #(0.809 1.13 -0.121 -1.389 0.477 0.621 -0.12)
  "Start configuration for the reflexxes demo.")

(defparameter *end-config*
  #(-0.623 0.772 -0.903 -0.672 0.657 0.621 -0.02)
  "End configuration for the reflexxes demo.")

(defparameter *high-joint-speed*
  (make-array 7 :initial-element 0.5))
(defparameter *low-joint-speed*
  (make-array 7 :initial-element 0.25))

(defparameter *high-joint-acc*
  (make-array 7 :initial-element 1))
(defparameter *low-joint-acc*
  (make-array 7 :initial-element 0.5))

(cpl:def-top-level-cram-function reflex-demo ()
  (loop for i to 1 do
    (seq
      (reflex-motion *start-config*)
      (reflex-motion *end-config*))))

(cpl:def-cram-function reflex-motion (goal-config)
  (let ((goal 
          (make-joint-impedance-goal
           :joint-goal goal-config
           :max-joint-vel *high-joint-speed*
           :max-joint-acc *high-joint-acc*))
        (safety-settings
          (make-safety-settings
           (list
            (make-beasty-reflex :CONTACT :IGNORE)
            (make-beasty-reflex :LIGHT-COLLISION :JOINT-IMP)
            (make-beasty-reflex :STRONG-COLLISION :SOFT-STOP)
            (make-beasty-reflex :SEVERE-COLLISION :HARD-STOP)))))
    (pursue
      (:tag motion-execution
        (retry-after-suspension
          (format t "MOTION-EXECUTION~%")
          (command-beasty *arm* goal safety-settings)))
      (whenever ((pulsed *collision-fluent*))
        (case (value *collision-fluent*)
          (:CONTACT
           (with-task-suspended (motion-execution)
             (format t "SLOWING-DOWN TASK~%")
             (setf (max-joint-vel goal) *low-joint-speed*)
             (setf (max-joint-acc goal) *low-joint-acc*)
             (cancel-command *arm*)))
          ((:LIGHT-COLLISION :STRONG-COLLISION :SEVERE-COLLISION)
           (with-task-suspended (motion-execution)
             (format t "WAITING ON TASK~%")
             (format t "ENCOUNTERED: ~a~%~%" (value *collision-fluent*))
             (stop-beasty *arm*)
             (setf (max-joint-vel goal) *low-joint-speed*)
             (setf (max-joint-acc goal) *low-joint-acc*)
             (cpl:sleep* 2))))))))
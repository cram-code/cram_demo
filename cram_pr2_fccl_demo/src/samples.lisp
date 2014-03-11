;;; Copyright (c) 2013, Georg Bartels <georg.bartels@cs.uni-bremen.de>
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

(in-package :cram-pr2-fccl-demo)

;;; POURING

(defparameter *bottle-top*
  (make-geometric-feature
   :id "bottle top plane"
   :frame-id "pancake_bottle"
   :feature-type 'plane
   :origin (cl-transforms:make-3d-vector 0 0 0.0825)
   :orientation (cl-transforms:make-3d-vector 0 0 1)))

(defparameter *bottle-bottom*
  (make-geometric-feature
   :id "bottle bottom plane"
   :frame-id "pancake_bottle"
   :feature-type 'plane
   :origin (cl-transforms:make-3d-vector 0 0 -0.11)
   :orientation (cl-transforms:make-3d-vector 0 0 -1)))

(defparameter *bottle-grasping-point*
  (make-geometric-feature
   :id "bottle grasping point"
   :frame-id "pancake_bottle"
   :feature-type 'point))

(defparameter *oven-center*
  (make-geometric-feature
   :id "oven center plane"
   :frame-id "pancake_maker"
   :feature-type 'plane
   :origin (cl-transforms:make-3d-vector 0 0 0)
   :orientation (cl-transforms:make-3d-vector 0 0 1)))

(defparameter *bottle-top-over-bottom*
  (make-feature-relation
   :id "bottle top over bottle bottom relation"
   :frame-id "torso_lift_link"
   :function-type 'above
   :tool-feature *bottle-top*
   :object-feature *bottle-bottom*))

(defparameter *bottle-top-right-bottom*
  (make-feature-relation
   :id "bottle top right bottle bottom relation"
   :frame-id "torso_lift_link"
   :function-type 'right
   :tool-feature *bottle-top*
   :object-feature *bottle-bottom*))

(defparameter *bottle-bottom-over-oven*
  (make-feature-relation
   :id "bottle bottom over oven"
   :frame-id "torso_lift_link"
   :function-type 'above
   :tool-feature *bottle-bottom*
   :object-feature *oven-center*))

(defparameter *bottle-left-of-oven*
  (make-feature-relation
   :id "bottle left of oven"
   :frame-id "torso_lift_link"
   :function-type 'left
   :tool-feature *bottle-top*
   :object-feature *oven-center*))
  
(defparameter *bottle-behind-of-oven*
  (make-feature-relation
   :id "bottle behind of oven"
   :frame-id "torso_lift_link"
   :function-type 'behind
   :tool-feature *bottle-top*
   :object-feature *oven-center*))

;;; HAND IN AIR

(defparameter *left-gripper-plane*
  (make-geometric-feature
   :id "left gripper plane"
   :frame-id "l_gripper_tool_frame"
   :feature-type 'plane
   :orientation (cl-transforms:make-3d-vector 0 0 1)))

(defparameter *waist-plane*
  (make-geometric-feature
   :id "pr2 horizontal waist plane"
   :frame-id "torso_lift_link"
   :feature-type 'plane
   :orientation (cl-transforms:make-3d-vector 0 0 1)))

(defparameter *hand-horizontal-relation*
  (make-feature-relation
   :id "hand horizontal relation"
   :frame-id "torso_lift_link"
   :function-type 'perpendicular
   :tool-feature *left-gripper-plane*
   :object-feature *waist-plane*))

(defparameter *hand-tilted-constraint*
  (make-feature-constraint
   :id "have hand tilted constraint"
   :relation *hand-horizontal-relation*
   :lower-boundary 0.4
   :upper-boundary 0.6))

(defparameter *hand-upright-constraint*
  (make-feature-constraint
   :id "have hand tilted constraint"
   :relation *hand-horizontal-relation*
   :lower-boundary 0.98
   :upper-boundary 1.1))
   
(defparameter *hand-test-motion*
  (make-motion-phase
   :id "sample motion moving pr2 hand in tilted pose"
   :constraints (list *hand-tilted-constraint*)))

(defparameter *hand-test-motion2*
  (make-motion-phase
   :id "sample motion moving pr2 hand in upright pose"
   :constraints (list *hand-upright-constraint*)))

;; (defvar *action-interface* nil)

;; (defun test-pr2-left-arm-above-waist ()
;;   "Sample function show-casing how to use the fccl action-interface."
;;   (let ((action-interface (get-action-interface))
;;         (motion-list (make-constraint-specifications)))
;;     (map 'list
;;          (lambda (single-motion)
;;            (execute-fccl-motion action-interface single-motion #'feedback-callback))
;;          motion-list)))

;; (defun get-action-interface ()
;;   (ensure-action-interface)
;;   *action-interface*)

;; (defun ensure-action-interface ()
;;   (unless *action-interface*
;;     (setf *action-interface* (make-action-interface))))

;; (defun make-action-interface ()
;;   "Creates a fccl-action-interface to command the left arm."
;;   (make-fccl-action-interface
;;    (actionlib:make-action-client
;;     "/l_arm_fccl_controller/command"
;;     "fccl_msgs/SingleArmMotionAction")
;;    (make-kinematic-chain "torso_lift_link" "l_gripper_tool_frame")))

;; (defun make-constraint-specifications ()
;;   "Creates a sample constraint specification to move the left gripper in front of the chest of the PR2."
;;   (let ((hand-plane (make-plane-feature
;;                      "left gripper plane"
;;                      "l_gripper_tool_frame"
;;                      (cl-transforms:make-3d-vector 0 0 0)
;;                      (cl-transforms:make-3d-vector 0 0 1)))
;;         (waist-plane (make-plane-feature
;;                       "horizontal waist plane"
;;                       "torso_lift_link"
;;                       (cl-transforms:make-3d-vector 0 0 0)
;;                       (cl-transforms:make-3d-vector 0 0 1))))
;;     (let ((left-hand-above-waist-constraint 
;;             (make-geometric-constraint
;;              "left hand above waist constraint" "torso_lift_link" "above"
;;              hand-plane waist-plane 0.1 2.0))
;;           (left-hand-below-waist-constraint 
;;             (make-geometric-constraint
;;              "left hand below waist constraint" "torso_lift_link" "below"
;;              hand-plane waist-plane 0.1 2.0))
;;           (left-hand-left-of-waist-constraint 
;;             (make-geometric-constraint
;;              "left hand left of waist constraint" "torso_lift_link" "left"
;;              hand-plane waist-plane 0.05 0.1))
;;           (left-hand-right-of-waist-constraint 
;;             (make-geometric-constraint
;;              "left hand right of waist constraint" "torso_lift_link" "right"
;;              hand-plane waist-plane 0.05 0.1))
;;           (left-hand-infront-of-waist-constraint 
;;             (make-geometric-constraint
;;              "left hand in front of waist constraint" "torso_lift_link" "behind"
;;              hand-plane waist-plane 0.4 0.5))
;;           (left-hand-infront-of-waist-constraint2
;;             (make-geometric-constraint
;;              "left hand in front of waist constraint 2" "torso_lift_link" "infront"
;;              hand-plane waist-plane -0.25 -0.2))
;;           (left-hand-parallel-to-ground-constraint
;;             (make-geometric-constraint
;;              "left hand parallel to ground constraint" "torso_lift_link" "perpendicular"
;;              hand-plane waist-plane 0.95 1.2)))
;;       (list 
;;        (list left-hand-above-waist-constraint left-hand-parallel-to-ground-constraint)
;;        (list left-hand-below-waist-constraint left-hand-parallel-to-ground-constraint)
;;        (list left-hand-left-of-waist-constraint left-hand-parallel-to-ground-constraint)
;;        (list left-hand-right-of-waist-constraint left-hand-parallel-to-ground-constraint)
;;        (list left-hand-infront-of-waist-constraint left-hand-parallel-to-ground-constraint)
;;        (list left-hand-infront-of-waist-constraint2 left-hand-parallel-to-ground-constraint)))))

;; (defun feedback-callback (feedback-msg)
;;   "Feedback callback returning t if all constraints in `feedback-msg' are fulfilled."
;;   (let ((feedback-list (from-msg feedback-msg)))
;;     (every #'constraint-fulfilled-p feedback-list)))

;; (defun constraint-fulfilled-p (constraint-feedback)
;;   "Checks whether `constraint-feedback' of type constraint-feedback is fulfilled."
;;   (declare (type geometric-constraint-feedback constraint-feedback))
;;   (< (weight (output constraint-feedback)) 1.0))
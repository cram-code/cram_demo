;;;
;;; Copyright (c) 2011, Lorenz Moesenlechner <moesenle@in.tum.de>
;;; All rights reserved.
;;; 
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;; 
;;;     * Redistributions of source code must retain the above copyright
;;;       notice, this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright
;;;       notice, this list of conditions and the following disclaimer in the
;;;       documentation and/or other materials provided with the distribution.
;;;     * Neither the name of the Intelligent Autonomous Systems Group/
;;;       Technische Universitaet Muenchen nor the names of its contributors 
;;;       may be used to endorse or promote products derived from this software 
;;;       without specific prior written permission.
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
;;;

(in-package :btr)

(defvar *right-parking-joint-states* '(("r_shoulder_pan_joint" -1.3810115229719555d0)
                                       ("r_shoulder_lift_joint" 1.1282870348994702d0)
                                       ("r_upper_arm_roll_joint" -1.7100000000000002d0)
                                       ("r_elbow_flex_joint" -2.105735087282934d0)
                                       ("r_forearm_roll_joint" -2.658135473603226d0)
                                       ("r_wrist_flex_joint" -1.9927790883777252d0)
                                       ("r_wrist_roll_joint" -2.5861844605475843d0)))

(defvar *left-parking-joint-states* '(("l_shoulder_pan_joint" 1.3810115229719555d0)
                                      ("l_shoulder_lift_joint" 1.1282870348994702d0)
                                      ("l_upper_arm_roll_joint" 1.71d0)
                                      ("l_elbow_flex_joint" -2.105735087282934d0)
                                      ("l_forearm_roll_joint" 2.6581354736032257d0)
                                      ("l_wrist_flex_joint" -1.9927790883777252d0)
                                      ("l_wrist_roll_joint" 2.586184460547585d0)))

(def-grasp :top (cl-transforms:euler->quaternion :ay (/ pi -2)))
(def-grasp :left (cl-transforms:euler->quaternion :az (/ pi 2)))
(def-grasp :right (cl-transforms:euler->quaternion :az (/ pi -2)))
(def-grasp :front (cl-transforms:make-identity-rotation))

(def-tool (cl-transforms:make-3d-vector 1 0 0) 0.20)

(def-fact-group robot-metadata ()
  (<- (robot pr2))
  (<- (camera-frame "openni_rgb_optical_frame"))
  (<- (camera-frame "narrow_stereo_optical_frame"))
  (<- (robot-pan-tilt-links "head_pan_link" "head_tilt_link"))
  (<- (robot-pan-tilt-joints "head_pan_joint" "head_tilt_joint"))
  (<- (end-effector-link :left "l_wrist_roll_link"))
  (<- (end-effector-link :right "r_wrist_roll_link"))

  (<- (robot-arms-parking-joint-states ?joint-states)
    (symbol-value *right-parking-joint-states* ?right-joint-states)
    (symbol-value *left-parking-joint-states* ?left-joint-states)
    (append ?right-joint-states ?left-joint-states ?joint-states))

  (<- (robot-arms-parking-joint-states ?joint-states :left)
    (symbol-value *left-parking-joint-states* ?joint-states))

  (<- (robot-arms-parking-joint-states ?joint-states :right)
    (symbol-value *right-parking-joint-states* ?joint-states))

  (<- (robot-pre-grasp-joint-states
       (("torso_lift_joint" 0.33) . ?parking-joint-states))
    (robot-arms-parking-joint-states ?parking-joint-states))

  (<- (robot-pre-grasp-joint-states
       (("torso_lift_joint" 0.165) . ?parking-joint-states))
    (robot-arms-parking-joint-states ?parking-joint-states))

  (<- (robot-pre-grasp-joint-states
       (("torso_lift_joint" 0.00) . ?parking-joint-states))
    (robot-arms-parking-joint-states ?parking-joint-states)))

(def-fact-group manipulation-knowledge ()
  (<- (grasp :top))
  (<- (grasp :side))
  (<- (grasp :front))

  ;; The OBJECT-GRASP predicate can be used to control which grasps
  ;; and which sides are valid for a specific object. The third
  ;; parameter, ?SIDES, indicates the arms that must be used for
  ;; grasping the object. ?SIDES is a list of arms to be used. A
  ;; solution for _all_ sides in that sequence must be found to let
  ;; reachability succeed.
  (<- (object-grasp ?world ?object ?grasp (?side))
    (household-object-type ?world ?object mug)
    (grasp ?grasp)
    (side ?side))

  (<- (object-grasp ?world ?object :side (:left :right))
    (household-object-type ?object plate))

  (<- (object-grasp ?world ?object :side (?side))
    (household-object-type ?object mondamin)
    (side ?side))

  (<- (object-grasp ?world ?object :side (:left :right))
    (household-object-type ?object pot))

  (<- (side :right))
  (<- (side :left)))

(defmethod side->ik-namespace ((side symbol))
  (ecase side
    (:right "reasoning/pr2_right_arm_kinematics")
    (:left "reasoning/pr2_left_arm_kinematics")))

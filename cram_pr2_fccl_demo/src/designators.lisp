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

(in-package :pr2-fccl-demo)

;;;
;;; AUX KNOWROB CALLS
;;;

(defun knowrob-pouring-description ()
  (query-motion-description 
   "motion:'PouringSomethingFromBottle'"
   "knowrob:'BottleCap'"
   "knowrob:'PancakeMaker'"))

(defun knowrob-flipping-description ()
  (warn "Lookup of pancake flipping not implemented, yet.")
  nil)

(defun left-arm-flipping-description ()
  ;;; FEATURES
  (let ((spatula-front
          (make-geometric-feature
           :id "left spatula front"
           :frame-id "l_spatula_blade"
           :feature-type 'LINE
           :origin (cl-transforms:make-3d-vector 0 0.0 0.0475)
           :orientation (cl-transforms:make-3d-vector 0 1 0)))
        (spatula-main-axis
          (make-geometric-feature
           :id "left spatula main axis"
           :frame-id "l_spatula_blade"
           :feature-type 'LINE
           :origin (cl-transforms:make-3d-vector 0 0.0 0.0)
           :orientation (cl-transforms:make-3d-vector 0 0 1)))
        (spatula-plane
          (make-geometric-feature
           :id "left spatula plane"
           :frame-id "l_spatula_blade"
           :feature-type 'PLANE
           :origin (cl-transforms:make-3d-vector 0 0 0)
           :orientation (cl-transforms:make-3d-vector 1 0 0)))
        (pancake-left-rim
          (make-geometric-feature
           :id "pancake left rim"
           :frame-id "pancake"
           :feature-type 'LINE
           :origin (cl-transforms:make-3d-vector 0 0.06 0)
           :orientation (cl-transforms:make-3d-vector 1 0 0)))
        (oven-center
          (make-geometric-feature
           :id "pancake center"
           :frame-id "oven"
           :feature-type 'PLANE
           :origin (cl-transforms:make-3d-vector 0 0 0.05)
           :orientation (cl-transforms:make-3d-vector 0 0 1))))
    ;;; RELATIONS
    (let ((spatula-front-above-oven-relation
            (make-feature-relation
             :id "spatula front edge above oven plane relation"
             :frame-id "base_link"
             :function-type 'ABOVE
             :tool-feature spatula-front
             :object-feature oven-center))
          (spatula-front-left-of-pancake
            (make-feature-relation
             :id "spatula front edge left of pancake relation"
             :frame-id "base_link"
             :function-type 'LEFT
             :tool-feature spatula-front
             :object-feature pancake-left-rim))
          (spatula-front-behind-pancake
            (make-feature-relation
             :id "spatula front edge behind pancake relation"
             :frame-id "base_link"
             :function-type 'BEHIND
             :tool-feature spatula-front
             :object-feature pancake-left-rim))
          (spatula-front-parallel-oven
            (make-feature-relation
             :id "spatula front edge parallel to oven"
             :frame-id "base_link"
             :function-type 'PERPENDICULAR
             :tool-feature spatula-front
             :object-feature oven-center))
          (spatula-oven-pitch
            (make-feature-relation
             :id "pitch between left spatula and oven"
             :frame-id "base_link"
             :function-type 'PERPENDICULAR
             :tool-feature spatula-main-axis
             :object-feature oven-center))
          (spatula-parallel-oven
            (make-feature-relation
             :id "left spatula parallel to oven relation"
             :frame-id "base_link"
             :function-type 'PERPENDICULAR
             :tool-feature spatula-plane
             :object-feature oven-center))
          (spatula-left-oven
            (make-feature-relation
             :id "left spatula left of oven relation"
             :frame-id "base_link"
             :function-type 'LEFT
             :tool-feature spatula-plane
             :object-feature oven-center))
          (spatula-behind-oven
            (make-feature-relation
             :id "left spatula behind of oven relation"
             :frame-id "base_link"
             :function-type 'BEHIND
             :tool-feature spatula-plane
             :object-feature oven-center))
          (spatula-above-oven
            (make-feature-relation
             :id "left spatula above oven relation"
             :frame-id "base_link"
             :function-type 'ABOVE
             :tool-feature spatula-plane
             :object-feature oven-center)))
      ;;; MOTIONS
      (let ((spatula-above-oven-motion
              (make-motion-phase
               :id "left spatula above oven motion"
               :constraints
               (list 
                (make-feature-constraint
                 :id "spatula front above oven constraint"
                 :relation spatula-front-above-oven-relation
                 :lower-boundary 0.1 :upper-boundary 0.2)
                (make-feature-constraint
                 :id "spatula front left of pancake constraint"
                 :relation spatula-front-left-of-pancake
                 :lower-boundary 0.02 :upper-boundary 0.05)
                (make-feature-constraint
                 :id "spatula front next to pancake constraint"
                 :relation spatula-front-behind-pancake
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "spatula front parallel to oven plane constraint"
                 :relation spatula-front-parallel-oven
                 :lower-boundary -0.03 :upper-boundary 0.03))))
            (spatula-touch-oven-motion
              (make-motion-phase
               :id "left spatula touch oven motion"
               :constraints
               (list 
                (make-feature-constraint
                 :id "spatula front above oven constraint"
                 :relation spatula-front-above-oven-relation
                 :lower-boundary -0.005 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "spatula front left of pancake constraint"
                 :relation spatula-front-left-of-pancake
                 :lower-boundary 0.02 :upper-boundary 0.05)
                (make-feature-constraint
                 :id "spatula front next to pancake constraint"
                 :relation spatula-front-behind-pancake
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "spatula front parallel to oven plane constraint"
                 :relation spatula-front-parallel-oven
                 :lower-boundary -0.03 :upper-boundary 0.03)
                (make-feature-constraint
                 :id "spatula front parallel to oven plane constraint"
                 :relation spatula-oven-pitch
                 :lower-boundary -0.3 :upper-boundary -0.2))))
            (spatula-push-under-motion
              (make-motion-phase
               :id "left spatula push under pancake motion"
               :constraints
               (list 
                (make-feature-constraint
                 :id "spatula front parallel to oven plane constraint"
                 :relation spatula-front-parallel-oven
                 :lower-boundary -0.03 :upper-boundary 0.03)
                (make-feature-constraint
                 :id "spatula front parallel to oven plane constraint"
                 :relation spatula-oven-pitch
                 :lower-boundary -0.03 :upper-boundary 0.03)
                (make-feature-constraint
                 :id "spatula on oven constraint"
                 :relation spatula-above-oven
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "spatula left of oven constraint"
                 :relation spatula-left-oven
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "spatula behind of oven constraint"
                 :relation spatula-behind-oven
                 :lower-boundary -0.01 :upper-boundary 0.01))))
            (spatula-lift-motion
              (make-motion-phase
               :id "left spatula lift motion"
               :constraints
               (list 
                (make-feature-constraint
                 :id "spatula front parallel to oven plane constraint"
                 :relation spatula-front-parallel-oven
                 :lower-boundary -0.03 :upper-boundary 0.03)
                (make-feature-constraint
                 :id "spatula pitch to oven plane constraint"
                 :relation spatula-oven-pitch
                 :lower-boundary -0.03 :upper-boundary 0.03)
                (make-feature-constraint
                 :id "spatula above oven constraint"
                 :relation spatula-above-oven
                 :lower-boundary 0.15 :upper-boundary 0.2)
                (make-feature-constraint
                 :id "spatula left of oven constraint"
                 :relation spatula-left-oven
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "spatula behind of oven constraint"
                 :relation spatula-behind-oven
                 :lower-boundary -0.01 :upper-boundary 0.01))))
            (spatula-flip-motion
              (make-motion-phase
               :id "left spatula flip motion"
               :constraints
               (list 
                (make-feature-constraint
                 :id "spatula pitch to oven plane constraint"
                 :relation spatula-oven-pitch
                 :lower-boundary -0.03 :upper-boundary 0.03)
                (make-feature-constraint
                 :id "spatula flip around constraint"
                 :relation spatula-parallel-oven
                 :lower-boundary -0.4 :upper-boundary -0.3)
                (make-feature-constraint
                 :id "spatula above oven constraint"
                 :relation spatula-above-oven
                 :lower-boundary 0.15 :upper-boundary 0.2)
                (make-feature-constraint
                 :id "spatula left of oven constraint"
                 :relation spatula-left-oven
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "spatula behind of oven constraint"
                 :relation spatula-behind-oven
                 :lower-boundary -0.01 :upper-boundary 0.01)))))
        (list 
         spatula-above-oven-motion 
         spatula-touch-oven-motion 
         spatula-push-under-motion
         spatula-push-under-motion
         spatula-lift-motion
         spatula-flip-motion)))))

(defun right-arm-flipping-description ()
  ;;; FEATURES
  (let ((right-spatula-front
          (make-geometric-feature
           :id "right spatula front edge"
           :frame-id "r_spatula_blade"
           :feature-type 'LINE
           :origin (cl-transforms:make-3d-vector 0 0.0 0.0475)
           :orientation (cl-transforms:make-3d-vector 0 1 0)))
          (right-spatula-blade
           (make-geometric-feature
            :id "right spatula blade"
            :frame-id "r_spatula_blade"
            :feature-type 'PLANE
            :origin (cl-transforms:make-3d-vector 0 0 0)
            :orientation (cl-transforms:make-3d-vector 1 0 0)))
          (pancake-right-rim
           (make-geometric-feature
            :id "pancake right rim"
            :frame-id "pancake"
            :feature-type 'LINE
            :origin (cl-transforms:make-3d-vector 0 -0.06 0)
            :orientation (cl-transforms:make-3d-vector 1 0 0)))
          (oven-center
           (make-geometric-feature
            :id "oven center"
            :frame-id "oven"
            :feature-type 'PLANE
            :origin (cl-transforms:make-3d-vector 0 0 0.05)
            :orientation (cl-transforms:make-3d-vector 0 0 1))))
    ;;; RELATIONS
    (let ((spatula-front-right-pancake
            (make-feature-relation
             :id "right spatula front right of pancake relation"
             :frame-id "base_link"
             :function-type 'RIGHT
             :tool-feature right-spatula-front
             :object-feature pancake-right-rim))
          (spatula-front-above-oven
            (make-feature-relation
             :id "right spatula front above pancake relation"
             :frame-id "base_link"
             :function-type 'ABOVE
             :tool-feature right-spatula-front
             :object-feature pancake-right-rim))
          (spatula-front-behind-pancake
            (make-feature-relation
             :id "right spatula front behind pancake relation"
             :frame-id "base_link"
             :function-type 'BEHIND
             :tool-feature right-spatula-front
             :object-feature pancake-right-rim))
          (spatula-front-parallel-oven
            (make-feature-relation
             :id "right spatula front parallel to oven"
             :frame-id "base_link"
             :function-type 'PERPENDICULAR
             :tool-feature right-spatula-front
             :object-feature oven-center))
          (spatula-oven-pitch
            (make-feature-relation
             :id "right spatula oven pitch"
             :frame-id "base_link"
             :function-type 'PERPENDICULAR
             :tool-feature right-spatula-blade
             :object-feature oven-center)))
      ;;; MOTIONS
      (let ((right-spatula-above-oven-motion
              (make-motion-phase
               :id "right spatula above oven motion"
               :constraints
               (list
                (make-feature-constraint
                 :id "right spatula front right of pancake constraint"
                 :relation spatula-front-right-pancake
                 :lower-boundary 0.02 :upper-boundary 0.05)
                (make-feature-constraint
                 :id "right spatula front above of oven constraint"
                 :relation spatula-front-above-oven
                 :lower-boundary 0.1 :upper-boundary 0.2)
                (make-feature-constraint
                 :id "right spatula front behind of pancake constraint"
                 :relation spatula-front-behind-pancake
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "right spatula front parallel to oven surface"
                 :relation spatula-front-parallel-oven
                 :lower-boundary -0.02 :upper-boundary 0.02)
                (make-feature-constraint
                 :id "right spatula tilted w.r.t. oven surface"
                 :relation spatula-oven-pitch
                 :lower-boundary -0.3 :upper-boundary -0.2))))
            (right-spatula-touch-oven-motion
              (make-motion-phase
               :id "right spatula above oven motion"
               :constraints
               (list
                (make-feature-constraint
                 :id "right spatula front right of pancake constraint"
                 :relation spatula-front-right-pancake
                 :lower-boundary 0.02 :upper-boundary 0.05)
                (make-feature-constraint
                 :id "right spatula front above of oven constraint"
                 :relation spatula-front-above-oven
                 :lower-boundary -0.05 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "right spatula front behind of pancake constraint"
                 :relation spatula-front-behind-pancake
                 :lower-boundary -0.01 :upper-boundary 0.01)
                (make-feature-constraint
                 :id "right spatula front parallel to oven surface"
                 :relation spatula-front-parallel-oven
                 :lower-boundary -0.02 :upper-boundary 0.02)
                (make-feature-constraint
                 :id "right spatula tilted w.r.t. oven surface"
                 :relation spatula-oven-pitch
                 :lower-boundary -0.3 :upper-boundary -0.2))))
            (right-spatula-move-away-motion
              (make-motion-phase
               :id "right spatula move away motion"
               :constraints
               (list
                (make-feature-constraint
                 :id "right spatula front right of pancake constraint"
                 :relation spatula-front-right-pancake
                 :lower-boundary 0.15 :upper-boundary 0.25)
                (make-feature-constraint
                 :id "right spatula front above of oven constraint"
                 :relation spatula-front-above-oven
                 :lower-boundary 0.1 :upper-boundary 0.2)
                (make-feature-constraint
                 :id "right spatula front behind of pancake constraint"
                 :relation spatula-front-behind-pancake
                 :lower-boundary -0.1 :upper-boundary 0.1)))))
        (list right-spatula-above-oven-motion
              right-spatula-touch-oven-motion
              right-spatula-touch-oven-motion
              right-spatula-move-away-motion
              right-spatula-move-away-motion
              right-spatula-move-away-motion)))))

;;;
;;; ASSEMBLING CONTROLLER CALLS
;;;

(defun constraint-controller-start ()
  (lambda (motion-phase)
    (cram-fccl:command-motion (get-left-arm-fccl-controller) motion-phase)))

(defun constraint-controller-stop ()
  (lambda () (cram-fccl:cancel-motion (get-left-arm-fccl-controller))))

;;;
;;; ASSEMBLING FLUENTS
;;;

(defun constraint-controller-finished-fluent ()
  (cram-fccl:get-constraints-fulfilled-fluent (get-left-arm-fccl-controller)))
    
;;;
;;; AUXILIARY FACTS FOR OUR DESIGNATORS
;;;

(def-fact-group pr2-fccl-demo-designators (action-desig)
  
  (<- (action-desig ?desig (?motion ?controller-start ?controller-stop ?controller-fluent))
    (constraints-desig? ?desig)
    (desig-prop ?desig (to pour))
    (lisp-fun knowrob-pouring-description ?motion)
    (lisp-fun constraint-controller-start ?controller-start)
    (lisp-fun constraint-controller-stop ?controller-stop)
    (lisp-fun constraint-controller-finished-fluent ?controller-fluent))

  (<- (action-desig ?desig (?motion ?controller-start ?controller-stop ?controller-fluent))
    (constraints-desig? ?desig)
    (desig-prop ?desig (to flip))
    (lisp-fun knowrob-flipping-description ?motion)
    (lisp-fun constraint-controller-start ?controller-start)
    (lisp-fun constraint-controller-stop ?controller-stop)
    (lisp-fun constraint-controller-finished-fluent ?controller-fluent)))
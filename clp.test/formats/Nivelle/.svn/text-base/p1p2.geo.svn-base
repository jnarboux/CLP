
%predicates
	ep/2,el/2,pl/2,col/4.

%model

# E0. # E1. # E2. # E3. # E4. # E5. # E6. # E7. # E8.

# E10. # E11. # E12. # E13. # E14. # E15. # E16. # E17.


col(E0,E1,E2,E10),col(E3,E4,E5,E11). 
col(E1,E5,E6,E12),col(E2,E4,E6,E13).
col(E1,E3,E7,E14),col(E0,E4,E7,E15).
col(E2,E3,E8,E16),col(E0,E5,E8,E17).

%rulesystem


el(E12,E13) -> FALSE.
el(E14,E15) -> goal.
el(E17,E16) -> goal.
el(VU,VU) /\ pl(E6,VU) /\ pl(E7,VU) /\ pl(E8,VU) -> goal.
%not using col(g,h,i,U) for efficiency reasons ...

col(VP,VQ,VR,VL) -> pl(VP,VL).
col(VP,VQ,VR,VL) -> pl(VQ,VL).
col(VP,VQ,VR,VL) -> pl(VR,VL).

pl(VP,VL) -> ep(VP,VP).     %a bit special indeed!
ep(VP,VQ) -> ep(VQ,VP).
ep(VP,VQ) /\ ep(VQ,VR) -> ep(VP,VR).


pl(VP,VL) -> el(VL,VL).     %a bit special indeed!
el(VL,VM) -> el(VM,VL).
el(VL,VM) /\ el(VM,VN) -> el(VL,VN).


ep(VP,VQ) /\ pl(VQ,VL) -> pl(VP,VL).
pl(VP,VL) /\ el(VL,VM) -> pl(VP,VM).

col(VA,VB,VC,VL) /\ col(VD,VE,VF,VM) /\                          % ABC on L, DEF on M
col(VB,VF,VG,VN) /\ col(VC,VE,VG,VO) /\                             %cross BF,CE in G 
col(VB,VD,VH,VP) /\ col(VA,VE,VH,VQ) /\                             %cross BD,AE in H
col(VC,VD,VI,VR) /\ col(VA,VF,VI,VS)                             %cross CD,AF in I
-> # VT /\ col(VG,VH,VI,VT) \/                                % G,H,I on line T 
   pl(VA,VM) \/ pl(VB,VM) \/ pl(VC,VM) \/ pl(VD,VL) \/ pl(VE,VL) \/ pl(VF,VL).  % exceptions

pl(VP,VL) /\ pl(VP,VM) /\ pl(VQ,VL) /\ pl(VQ,VM) -> ep(VP,VQ) \/  el(VL,VM).

ep(VP,VP) /\ ep(VQ,VQ) ->  # VL /\ pl(VP,VL) /\ pl(VQ,VL).

el(VL,VL) /\ el(VM,VM) -> # VP /\ pl(VP,VL) /\ pl(VP,VM).






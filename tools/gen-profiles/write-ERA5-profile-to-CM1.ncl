begin

input_ERA5="avg.nc"
output_sounding="ERA5_sounding.txt"

;=========================================================================

; load ERA5 data
f=addfile(input_ERA5,"r")
ps = f->ps
thetas = f->thetas
rs = f->rs
Zlev = f->Zlev
theta_z = f->theta_z(:)
r_z = f->r_z(:)
u_z = f->u_z(:)
v_z = f->v_z(:)
ug_z = f->ug_z(:)
vg_z = f->vg_z(:)
w_z = f->w_z(:)

; get number of ERA5 sounding levels
nsoundinglev = dimsizes(Zlev)

; write sounding file in CM1 format
quote = inttochar(34)
system("rm -v "+output_sounding)
system("echo "+quote+      "  "+(ps/100.)+"  "+thetas+"  "+rs       +quote+" >> "+output_sounding)
do ii = 0,nsoundinglev-1
  system("echo "+quote+      "  "+Zlev(ii)+"  "+theta_z(ii)+"  "+r_z(ii)+" "+u_z(ii)+" "+v_z(ii)+" "+ug_z(ii)+" "+vg_z(ii)+" "+w_z(ii)         +quote+" >> "+output_sounding)
end do

end

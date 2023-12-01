begin

f=addfile("avg.nc","r")

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

nsoundinglev = dimsizes(Zlev)

quote = inttochar(34)
filename = "sounding.txt"

system("rm -v sounding.txt")
system("echo "+quote+      "  "+(ps/100.)+"  "+thetas+"  "+rs       +quote+" >> "+filename)
do ii = 0,nsoundinglev-1
  system("echo "+quote+      "  "+Zlev(ii)+"  "+theta_z(ii)+"  "+r_z(ii)+" "+u_z(ii)+" "+v_z(ii)+" "+ug_z(ii)+" "+vg_z(ii)+" "+w_z(ii)         +quote+" >> "+filename)
end do



end

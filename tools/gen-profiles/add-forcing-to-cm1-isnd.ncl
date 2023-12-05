begin

input_sounding="input_sounding.OBS"
output_sounding="sounding.txt"
input_ERA5="avg.nc"

;=========================================================================

; load existing CM1 profile one line at a time
data = asciiread(input_sounding,-1,"string")

; get the z coordinate, ignoring header row
z = stringtofloat(str_get_field(data(1::), 1," "))

; load ERA5 data
f=addfile(input_ERA5,"r")
Zlev = f->Zlev
ug_z = f->ug_z(:)
vg_z = f->vg_z(:)
wprof_z = f->w_z(:)

; linearly interp ERA5 data -> CM1 grid
ug = linint1 (Zlev,ug_z, False, z, 0)
vg = linint1 (Zlev,vg_z, False, z, 0)
wprof = linint1 (Zlev,wprof_z, False, z, 0)

; fill any missing values on either end with nearest neighbor
ug = linmsg(ug,-1)
vg = linmsg(vg,-1)
wprof = linmsg(wprof,-1)

print(z+" "+ug+" "+vg+" "+wprof)

; write file to output_sounding
quote = inttochar(34)
system("rm -v "+output_sounding)
do ii = 0,dimsizes(data)-1
  if (ii .eq. 0) then
    system("echo "+quote+      "  "+data(ii)         +quote+" >> "+output_sounding)
  else
    system("echo "+quote+      "  "+data(ii)+"  "+ug(ii-1)+"  "+vg(ii-1)+" "+wprof(ii-1)         +quote+" >> "+output_sounding)
  end if
end do


end


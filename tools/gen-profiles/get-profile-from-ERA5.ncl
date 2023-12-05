begin

;year="2020"
;month="02"
;day="01"
;hh="00"
;sample_lat=13.
;sample_lon=-58.+360.

; location logic
sample_lat := tofloat(sample_lat)
sample_lon := tofloat(sample_lon)
if (sample_lon .lt. 0.0) then
  sample_lon = sample_lon + 360.0
end if

fullstr = year+month+day+hh

print("NCL diags: "+fullstr+"  lat: "+sample_lat+"    lon: "+sample_lon)

zf=addfile("~/rda/ds633.0/e5.oper.an.pl/"+year+month+"/e5.oper.an.pl.128_129_z.ll025sc."+year+month+day+"00_"+year+month+day+"23.nc","r")
uf=addfile("~/rda/ds633.0/e5.oper.an.pl/"+year+month+"/e5.oper.an.pl.128_131_u.ll025uv."+year+month+day+"00_"+year+month+day+"23.nc","r")
vf=addfile("~/rda/ds633.0/e5.oper.an.pl/"+year+month+"/e5.oper.an.pl.128_132_v.ll025uv."+year+month+day+"00_"+year+month+day+"23.nc","r")
tf=addfile("~/rda/ds633.0/e5.oper.an.pl/"+year+month+"/e5.oper.an.pl.128_130_t.ll025sc."+year+month+day+"00_"+year+month+day+"23.nc","r")
qf=addfile("~/rda/ds633.0/e5.oper.an.pl/"+year+month+"/e5.oper.an.pl.128_133_q.ll025sc."+year+month+day+"00_"+year+month+day+"23.nc","r")
wf=addfile("~/rda/ds633.0/e5.oper.an.pl/"+year+month+"/e5.oper.an.pl.128_135_w.ll025sc."+year+month+day+"00_"+year+month+day+"23.nc","r")

time_units = zf->time@units

era5_time = cd_inv_calendar(toint(year),toint(month),toint(day),toint(hh),0,0,time_units,0)

print(era5_time)
print(zf->time)

lev = zf->level
lev = lev*100.

z = zf->Z({era5_time},:,{sample_lat},{sample_lon})
z = z/9.81
u = uf->U({era5_time},:,{sample_lat},{sample_lon})
v = vf->V({era5_time},:,{sample_lat},{sample_lon})
t = tf->T({era5_time},:,{sample_lat},{sample_lon})
q = qf->Q({era5_time},:,{sample_lat},{sample_lon})
w = wf->W({era5_time},:,{sample_lat},{sample_lon})
r = q
r = q/(1-q)
print(q+" "+r)
r = r * 1000.

z3=zf->Z({era5_time},:,:,:)
z3=z3/9.81
lat3=zf->latitude(:)
lon3=zf->longitude(:)
i_lat = ind_nearest_coord (sample_lat, lat3, 0)
i_lon = ind_nearest_coord (sample_lon, lon3, 0)
uv=z2geouv(z3,lat3,lon3,1)

ug=uv(0,:,i_lat,i_lon)
vg=uv(1,:,i_lat,i_lon)

print(i_lat+" "+i_lon)
print(ug+" "+vg)

copy_VarMeta(u,ug)
copy_VarMeta(u,vg)

P0 = 100000.

if (month .eq. "01") then
  enday="31"
else
  enday="29"
end if

psf=addfile("~/rda/ds633.0/e5.oper.an.sfc/"+year+month+"/e5.oper.an.sfc.128_134_sp.ll025sc."+year+month+"0100_"+year+month+enday+"23.nc","r")
usf=addfile("~/rda/ds633.0/e5.oper.an.sfc/"+year+month+"/e5.oper.an.sfc.128_165_10u.ll025sc."+year+month+"0100_"+year+month+enday+"23.nc","r")
vsf=addfile("~/rda/ds633.0/e5.oper.an.sfc/"+year+month+"/e5.oper.an.sfc.128_166_10v.ll025sc."+year+month+"0100_"+year+month+enday+"23.nc","r")
tsf=addfile("~/rda/ds633.0/e5.oper.an.sfc/"+year+month+"/e5.oper.an.sfc.128_167_2t.ll025sc."+year+month+"0100_"+year+month+enday+"23.nc","r")
qsf=addfile("~/rda/ds633.0/e5.oper.an.sfc/"+year+month+"/e5.oper.an.sfc.128_168_2d.ll025sc."+year+month+"0100_"+year+month+enday+"23.nc","r")
sstf=addfile("~/rda/ds633.0/e5.oper.an.sfc/"+year+month+"/e5.oper.an.sfc.128_034_sstk.ll025sc."+year+month+"0100_"+year+month+enday+"23.nc","r")
sktf=addfile("~/rda/ds633.0/e5.oper.an.sfc/"+year+month+"/e5.oper.an.sfc.128_235_skt.ll025sc."+year+month+"0100_"+year+month+enday+"23.nc","r")

ps = psf->SP({era5_time},{sample_lat},{sample_lon})
us = usf->VAR_10U({era5_time},{sample_lat},{sample_lon})
vs = vsf->VAR_10V({era5_time},{sample_lat},{sample_lon})
ts = tsf->VAR_2T({era5_time},{sample_lat},{sample_lon})
qs = qsf->VAR_2D({era5_time},{sample_lat},{sample_lon})
sst = sstf->SSTK({era5_time},{sample_lat},{sample_lon})
skt = sktf->SKT({era5_time},{sample_lat},{sample_lon})

rs = qs
rs = mixhum_ptd(ps, qs, -1)

thetas = ts
thetas = ts*(P0/ps)^0.286

zs = ps
zs = 0.

ws = ps
ws = 0.0

print(z+" "+lev+" "+u+" "+v+" "+t+" "+r)
print(zs+" "+ps+" "+us+" "+vs+" "+ts+" "+rs)

nlev = dimsizes(lev)

combined = new((/nlev+1/),typeof(lev))

z_all = combined
z_all(nlev) = zs
z_all(0:nlev-1) = z(:)

lev_all = combined
lev_all(nlev) = ps
lev_all(0:nlev-1) = lev(:)

u_all = combined
u_all(nlev) = us
u_all(0:nlev-1) = u(:)

v_all = combined
v_all(nlev) = vs
v_all(0:nlev-1) = v(:)

t_all = combined
t_all(nlev) = ts
t_all(0:nlev-1) = t(:)

r_all = combined
r_all(nlev) = rs
r_all(0:nlev-1) = r(:)

w_all = combined
w_all(nlev) = ws
w_all(0:nlev-1) = w(:)

ug_all = combined
ug_all(nlev) = ug@_FillValue
ug_all(0:nlev-1) = ug(:)

vg_all = combined
vg_all(nlev) = vg@_FillValue
vg_all(0:nlev-1) = vg(:)

print("----")

print(z_all+" "+lev_all+" "+u_all+" "+v_all+" "+t_all+" "+r_all)

; generate Zlev
nsoundinglev=50
Zlev = fspan(100.,5000.,nsoundinglev)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

; do vertical interpolation from model levels to equally spaced Z levels
interp_type=1
p_z = int2p_n_Wrap(z_all,lev_all,Zlev,interp_type,0)
u_z = int2p_n_Wrap(z_all,u_all,Zlev,interp_type,0)
v_z = int2p_n_Wrap(z_all,v_all,Zlev,interp_type,0)
t_z = int2p_n_Wrap(z_all,t_all,Zlev,interp_type,0)
r_z = int2p_n_Wrap(z_all,r_all,Zlev,interp_type,0)

ug_z = int2p_n_Wrap(z_all,ug_all,Zlev,interp_type,0)
vg_z = int2p_n_Wrap(z_all,vg_all,Zlev,interp_type,0)

omega_z = int2p_n_Wrap(z_all,w_all,Zlev,interp_type,0)

theta_z = t_z
theta_z = t_z*(P0/p_z)^0.286

w_z = omega_z
w_z = omega_to_w(omega_z,p_z,t_z)

interp_g_below=True
low_int=500.
high_int=1200.
below_xtrp=1000.
if (interp_g_below) then
  slope_ug = (ug_z({high_int}) - ug_z({low_int})) / (high_int - low_int)
  slope_vg = (vg_z({high_int}) - vg_z({low_int})) / (high_int - low_int)
  ;slope_w = (w_z({high_int}) - w_z({low_int})) / (high_int - low_int)
  do jj = 0,nsoundinglev-1
    if (Zlev(jj) .lt. below_xtrp) then
      ug_z(jj) = ug_z({below_xtrp}) - slope_ug * (below_xtrp - Zlev(jj))
      vg_z(jj) = vg_z({below_xtrp}) - slope_vg * (below_xtrp - Zlev(jj))
      ;w_z(jj) = w_z({below_xtrp}) - slope_w * (below_xtrp - Zlev(jj))
    end if
  end do
end if

print(Zlev+" "+p_z+" "+u_z+" "+v_z+" "+theta_z+" "+r_z)

;quote = inttochar(34)
;filename = "sounding.txt"
;
;system("rm -v sounding.txt")
;system("echo "+quote+      "  "+(ps/100.)+"  "+thetas+"  "+rs       +quote+" >> "+filename)
;do ii = 0,nsoundinglev-1
;  system("echo "+quote+      "  "+Zlev(ii)+"  "+theta_z(ii)+"  "+r_z(ii)+" "+u_z(ii)+" "+v_z(ii)       +quote+" >> "+filename)
;end do



outfilename=fullstr+".nc"
system("/bin/rm -f "+outfilename)   ; remove any pre-existing file
ncdf = addfile(outfilename ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True)

ncdf->Zlev = Zlev
ncdf->theta_z = theta_z
ncdf->r_z = r_z
ncdf->u_z = u_z
ncdf->v_z = v_z
ncdf->w_z = w_z
ncdf->omega_z = omega_z

ncdf->ug_z = ug_z
ncdf->vg_z = vg_z

ncdf->ps = ps
ncdf->thetas = thetas
ncdf->rs = rs
ncdf->sst = sst
ncdf->skt = skt

end


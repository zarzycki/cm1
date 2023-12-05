
# CM1 and real-world LES

NOTE: For now, this only works over ocean.

## Generate input_sounding

The input sounding for isnd/testcase 99 includes 3 additional columns not included when isnd = 7. These three columns include the zonal geostrophic wind (ug, m/s), the meridional geostrophic wind (vg, m/s), and the z-coordinate vertical velocity (w, w/s).

There are some scripts that are available in `./tools/gen-profiles/` that can help with generating input_soundings.

#### From ERA5

1. Edit `driver-ERA5-profiles.sh` to leverage the NCAR RDA to generate snapshot ERA5 intermediate files at a location and a series of times.
2. If desirable, average over multiple ERA5 intermediate files using `nceavg files*nc avg.nc`
3. Edit top of `write-ERA5-profile-to-CM1.ncl` to point to relevant ERA5 data and run using NCL. This will automatically populate a CM1 "sounding" file with 8 columns needed for isnd/testcase = 99.

#### From obs + ERA5 forcing

1. Generate your own CM1 sounding file as you otherwise would for `isnd = 7` (each row has z, theta, qv, u, v)
2. Run steps 1 and 2 from above to generate ERA5 large-scale forcing fields
3. Edit top of `add-forcing-to-cm1-isnd.ncl` to point to CM1 sounding from step 1 and ERA5 file from step 2. Run NCL, which should create another CM1 sounding file, but now with three columns appended.

## Use sample namelist

Things to set:

```
! Config settings
 testcase  =  99,  ! Colin's test case to force wprof activation
 isnd      =  99,  ! Colin's test case to read 8-column file with ug, vg, wprof
 lspgrad   =  2,   ! Get large-scale pressure gradient from ug/vg

! Coriolis
 fcor    = 0.353e-4,  ! Calculate and set based on lat of interest

! Radiation settings (set date + location to get solar zenith, etc.)
 radopt  =        2,    ! Radiation option (0 off, 2 RRTMG)
 dtrad   =    300.0,
 ctrlat  =    13.19,
 ctrlon  =   -59.54,
 year    =     2020,
 month   =        2,
 day     =        1,
 hour    =       00,
 minute  =       00,
 second  =       00,

! Surface conditions
 tsk0       = 300.30,    ! Surface temperature (K)
```

---

## Notes


### Large scale pressure gradient

There are a few options that are controlled by `lspgrad`.

```
 lspgrad - Apply large-scale pressure gradient acceleration to u and v
           components of velocity.
        0 = no
        1 = yes, based on geostropic balance using base-state wind profiles
          (note:  lspgrad = 1 was called "pertcor" in earlier versions of cm1)
        2 = yes, based on geostropic balance using ug,vg arrays
        3 = yes, based on gradient-wind balance (Bryan et al 2017, BLM)
        4 = yes, specified values (set ulspg, vlspg in base.F)
```

For our purposes, 2 and 4 seem most logical. We can load gridded model data and use something like a centered difference to calculate either the geostrophic wind or pressure gradient.

The LSPG is applied thusly:

```
uten1(i,j,k) = uten1(i,j,k)+ulspg(k)
vten1(i,j,k) = vten1(i,j,k)+vlspg(k)
```

For `4` a user must supply arrays for `ulspg` and `vlspg` directly in base.F. For `2` the user must specify vertical profiles of `ug` and `vg` in `base.F`. Then CM1 will back out `ulspg` and `vlspg ` from the winds:

```
ulspg(k) = -fcor*(vg(k)+vmove)
vlspg(k) =  fcor*(ug(k)+umove)
```

and then call the uten1 and vten1 lines above.

### Imposed vertical velocity

This is controlled by the variable `wprof`. Whether this code is invoked or not is governed by the boolean `dolsw`. E.g. see param.F

```
...
!--------------------------------------------------------------
!  Large-scale vertical velocity:

      dolsw = .false.

      IF( testcase.eq.3 ) dolsw = .true.
      IF( testcase.eq.4 ) dolsw = .true.
      IF( testcase.eq.5 ) dolsw = .true.
      IF( testcase.eq.6 ) dolsw = .true.
      IF( testcase.eq.7 ) dolsw = .true.

...
```

The way this is done is via the function `wsub` which is called in `adv.F`.

If we want to edit apply `wprof` I think we have to edit `base.F` *and* make sure we are either running a testcase that supports `dolsw = .true.` or we need to edit `param.F` to add the test case.

### Input profile

I think the best way here is to create our own observed sounding. This requires `isnd` to be set to 7 in the namelist and then input.sounding needs to look like this:

```
1015.6  298.155 15.9
50 298.15579352491795 15.825015439873674 -6.414258294858722 -1.7147163720254763
60 298.1521861276413 15.75063293189496 -6.816741953473045 -1.802758207013584
70 298.15560013523526 15.698801169784748 -7.183519666838334 -1.8895604829267614
80 298.15564684339097 15.669997071985794 -7.483237031363434 -1.9702106071844838
```

The format George Bryan specifies is:

```
  One-line header containing:   sfc pres (mb)    sfc theta (K)    sfc qv (g/kg)

   (Note1: here, "sfc" refers to near-surface atmospheric conditions.
    Technically, this should be z = 0, but in practice is obtained from the
    standard reporting height of 2 m AGL/ASL from observations)
   (Note2: land-surface temperature and/or sea-surface temperature (SST) are
    specified elsewhere: see tsk0 in namelist.input and/or tsk array in
    init_surface.F)

 Then, the following lines are:   z (m)    theta (K)   qv (g/kg)    u (m/s)    v (m/s)

   (Note3: # of levels is arbitrary)

     Index:   sfc    =  surface (technically z=0, but typically from 2 m AGL/ASL obs)
              z      =  height AGL/ASL
              pres   =  pressure
              theta  =  potential temperature
              qv     =  mixing ratio
              u      =  west-east component of velocity
              v      =  south-north component of velocity

 Note4:  For final line of input_sounding file, z (m) must be greater than the model top
         (which is nz * dz when stretch_z=0, or ztop when stretch_z=1,  etc)
```

NOTE: This tool may help, I haven't tried it: https://github.com/cwebster2/pyMeteo

### Temperature and moisture forcing.

BOMEX specifies a radiative cooling and drying. George codes this in `base.F` as:

```
      radsfc = -2.0 /( 3600.0 * 24.0 )
      z1     =  1500.0
      z2     =  2100.0

      do k=1,nk
        if( zh(1,1,k).le.z1 )then
          thfrc(k) = radsfc
        elseif( zh(1,1,k).le.z2 )then
          thfrc(k) = radsfc + ( 0.0 - radsfc )*(zh(1,1,k)-z1)/(z2-z1)
        else
          thfrc(k) = 0.0
        endif
      enddo

      if( myid.eq.0 ) print *
      if( myid.eq.0 ) print *,'  k,zh,thfrc,qvfrc '

      qvsfc  =  -1.2e-8
      z1     =   300.0
      z2     =   500.0

      do k=1,nk
        if( zh(1,1,k).le.z1 )then
          qvfrc(k) = -1.2e-8
        elseif( zh(1,1,k).le.z2 )then
          qvfrc(k) = qvsfc + ( 0.0 - qvsfc )*(zh(1,1,k)-z1)/(z2-z1)
        else
          qvfrc(k) = 0.0
        endif
        if( myid.eq.0 ) print *,k,zh(1,1,k),thfrc(k)*3600.0*24.0,qvfrc(k)
      enddo
```

If `testcase` is GE 1, this is called.

```
      IF( testcase.ge.1 )THEN

        call     testcase_simple_phys(mh,rho0,rr0,rf0,th0,u0,v0,     &
                   zh,zf,dum1,dum2,dum3,dum4,dum5,dum6,              &
                   ufrc,vfrc,thfrc,qvfrc,ug,vg,dvdr,                 &
                   uavg,vavg,thavg,qavg,cavg,                        &
                   ua,va,tha,qa,uten1,vten1,thten1,qten,             &
                   o30 ,zir,ruh,ruf,rvh,rvf,mtime)
        if(timestats.ge.1) time_misc=time_misc+mytime()

      ENDIF
```

`testcase_simple_phys` seems a bit hacky but essentially if there is a non-zero value of `ufrc,vfrc,thfrc,qvfrc` they will be applied to the RHS of the primitive equations.

### Update namelist

Other relevant namelist settings to update:

#### Coriolis force

```
icor    = 1           ! turn on Coriolis acceleration
fcor    = 0.35e-4,    ! f
```

#### Radiation stuff

If `radopt` is 0, the radiation code isn't invoked and none of this matters. However, if radopt = 1 or 2, then we need to specify these to get the correct radiation for location and time of year. Note that ctrlat and ctrlon here don't impact fcor which is set above.

```
 &param11
 radopt  =        0,
 dtrad   =    300.0,
 ctrlat  =    36.68,
 ctrlon  =   -98.35,
 year    =     2009,
 month   =        2,
 day     =        1,
 hour    =       21,
 minute  =       00,
 second  =       00,
 /
```

#### Microphysics

Currently for the BOMEX case this is set to 5, which seems safe for climate applications.

```
 ptype     =  5,
 ihail     =  0,
 iautoc    =  0,
```

CM1 docs below:

```
ptype - Explicit moisture scheme:

             0 = no microphysics (vapor only)

             1 = Kessler scheme (water only)

             2 = NASA-Goddard version of LFO scheme

             3 = Thompson scheme

             4 = Gilmore/Straka/Rasmussen version of LFO scheme

   (default) 5 = Morrison double-moment scheme

             6 = Rotunno-Emanuel (1987) simple water-only scheme

            (Note: options 26,27,28 use namelist nssl2mom_params, see below)
             26 = NSSL 2-moment scheme (graupel-only, no hail);
                  graupel density predicted
             27 = NSSL 2-moment scheme (graupel and hail);
                  graupel and hail densities predicted
             28 = NSSL single-moment scheme (graupel-only, similar to ptype=4);
                  fixed graupel density (rho_qh)

            (Note: P3 = Predicted Particle Property bulk microphysics scheme)
             50 = P3 1-ice category, 1-moment cloud water
             51 = P3 1-ice category plus double-moment cloud water
             52 = P3 2-ice categories plus double-moment cloud water
             53 = P3 1-ice category, 3-moment ice, plus double-moment cloud water

             55 = Jensen's ISHMAEL (Ice-Spheroids Habit Model with Aspect-ratio Evolution)

 ihail - Use hail or graupel for large ice category when ptype=2,5.
          (Goddard-LFO and Morrison schemes only)
             1 = hail
             0 = graupel

 iautoc - Include autoconversion of qc to qr when ptype = 2?  (0=no, 1=yes)
            (Goddard-LFO scheme only)
```
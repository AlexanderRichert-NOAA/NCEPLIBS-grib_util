!> @file
!>                .     .   .                                      .
!> @author Gilbert @date 2003-06-12
!
!>  This routine creates a GRIB1 PDS (Section 1)
!>  from appropriate information from a GRIB2 Product Definition Template.
!>
!> PROGRAM HISTORY LOG:
!> 2003-06-12  Gilbert
!> 2005-04-19  Gilbert    - Changed scaling factor used with potential
!>                          vorticity surfaces.
!> 2007-05-08  VUONG      - Add Product Definition Template entries
!>                          120 - Ice Concentration Analysis
!>                          121 - Western North Atlantic Regional Wave Model
!>                          122 - Alaska Waters Regional Wave Model
!>                          123 - North Atlantic Hurricane Wave Model
!>                          124 - Eastern North Pacific Regional Wave Model
!>                          131 - Great Lake Wave Model
!>                           88 - NOAA Wave Watch III (NWW3)
!>                           45 - Coastal Ocean Circulation
!>                           47 - HYCOM - North Pacific basin
!> 2007-05-14  Boi Vuong  - Added Time Range Indicator 51 (Climatological
!>                          Mean Value)
!> 2007-10-24  Boi Vuong  - Added level 8 (Nominal top of atmosphere)
!> 2009-05-19  Boi Vuong  - Added levels 10(Entire Atmosphere), 11(Cumulonimbus
!>                          Base),12(Cumulonimbus Top) and level 126(Isobaric Pa)
!> 2009-12-14  Boi Vuong  - Added check for WAFS to use PDT 4.15 for Icing,
!>                          Turbulence and Cumulonimbus
!> 2010-08-10  Boi Vuong  - Added check for FNMOC to use TMP as TMAX and TMIN
!>                        - Removed check WAFS MAX wind level
!> 2011-10-24  Boi Vuong  - Added check for NAM (NMM-B) parameters to set 
!>                          statistical processing as MAX and MIN
!> 2012-03-29  Boi Vuong  - Added check Time Range for APCP in FNMOC 
!> 2014-05-20  Boi Vuong  - Added check Time Range after F252 
!> 2014-11-14  Boi Vuong  - Added check Time Range for 15-hr or 18-hr or 21-hr or
!>                          24-hr Accumulation for APCP after F240 
!> 2018-07-26  Boi Vuong  - Added check Time Range for continuous accumulated APCP 
!>                          after F252 when convert from grib2 to grib1
!>
!> USAGE:    CALL makepds(idisc,idsect,ipdsnum,ipdstmpl,ibmap,
!>                        idrsnum,idrstmpl,kpds,iret)
!>   INPUT ARGUMENT LIST:
!>     idisc      - GRIB2 discipline from Section 0.
!>     idsect()   - GRIB2 Section 1 info.
!>                idsect(1)=Id of orginating centre (Common Code Table C-1)
!>                idsect(2)=Id of orginating sub-centre (local table)
!>                idsect(3)=GRIB Master Tables Version Number (Code Table 1.0)
!>                idsect(4)=GRIB Local Tables Version Number (Code Table 1.1)
!>                idsect(5)=Significance of Reference Time (Code Table 1.2)
!>                idsect(6)=Reference Time - Year (4 digits)
!>                idsect(7)=Reference Time - Month
!>                idsect(8)=Reference Time - Day
!>                idsect(9)=Reference Time - Hour
!>                idsect(10)=Reference Time - Minute
!>                idsect(11)=Reference Time - Second
!>                idsect(12)=Production status of data (Code Table 1.3)
!>                idsect(13)=Type of processed data (Code Table 1.4)
!>     ipdsnum    - GRIB2 Product Definition Template Number
!>     ipdstmpl() - GRIB2 Product Definition Template entries for PDT 4.ipdsnum
!>     ibmap      - GRIB2 bitmap indicator from octet 6, Section 6.
!>     idrsnum    - GRIB2 Data Representation Template Number
!>     idrstmpl() - GRIB2 Data Representation Template entries
!>
!>   OUTPUT ARGUMENT LIST:
!>     kpds()     - GRIB1 PDS info as specified in W3FI63.
!>          (1)   - ID OF CENTER
!>          (2)   - GENERATING PROCESS ID NUMBER
!>          (3)   - GRID DEFINITION
!>          (4)   - GDS/BMS FLAG (RIGHT ADJ COPY OF OCTET 8)
!>          (5)   - INDICATOR OF PARAMETER
!>          (6)   - TYPE OF LEVEL
!>          (7)   - HEIGHT/PRESSURE , ETC OF LEVEL
!>          (8)   - YEAR INCLUDING (CENTURY-1)
!>          (9)   - MONTH OF YEAR
!>          (10)  - DAY OF MONTH
!>          (11)  - HOUR OF DAY
!>          (12)  - MINUTE OF HOUR
!>          (13)  - INDICATOR OF FORECAST TIME UNIT
!>          (14)  - TIME RANGE 1
!>          (15)  - TIME RANGE 2
!>          (16)  - TIME RANGE FLAG
!>          (17)  - NUMBER INCLUDED IN AVERAGE
!>          (18)  - VERSION NR OF GRIB SPECIFICATION
!>          (19)  - VERSION NR OF PARAMETER TABLE
!>          (20)  - NR MISSING FROM AVERAGE/ACCUMULATION
!>          (21)  - CENTURY OF REFERENCE TIME OF DATA
!>          (22)  - UNITS DECIMAL SCALE FACTOR
!>          (23)  - SUBCENTER NUMBER
!>     iret       - Error return value:
!>                  0  = Successful
!>                  1  = Don't know what to do with pre-defined bitmap.
!>                  2  = Unrecognized GRIB2 PDT 4.ipdsnum
!>
!> REMARKS:  Use pds2pdtens for ensemble related PDS
!>
!> ATTRIBUTES:
!>   LANGUAGE: Fortran 90
!>   MACHINE:  IBM SP
!>
!>
      subroutine makepds(idisc,idsect,ipdsnum,ipdstmpl,ibmap,
     &                     idrsnum,idrstmpl,kpds,iret)

        
        use params

        integer,intent(in) :: idsect(*),ipdstmpl(*),idrstmpl(*)
        integer,intent(in) :: ipdsnum,idisc,idrsnum,ibmap
        integer,intent(out) :: kpds(*)
        integer,intent(out) :: iret

        iret=0
        ipos=0
        kpds(1:24)=0
        if ( (ipdsnum.lt.0).OR.(ipdsnum.gt.15) ) then
           print *,'makepds: Don:t know GRIB2 PDT 4.',ipdsnum
           iret=2
           return
        endif

        kpds(1)=idsect(1)
        kpds(2)=ipdstmpl(5)
        kpds(3)=255
        kpds(4)=128
        if ( ibmap.ne.255 ) kpds(4)=kpds(4)+64
        if ( ibmap.ge.1.AND.ibmap.le.253 ) then
           print *,'makepds: Don:t know about predefined bit-map ',ibmap
           iret=1
           return
        endif
        call param_g2_to_g1(idisc,ipdstmpl(1),ipdstmpl(2),kpds(5),
     &                      kpds(19))
!
!  Special parameters for ICAO WAFS (Max Icing, TP and CAT)
!
        If (ipdstmpl(16).eq.2.and.ipdstmpl(1).eq.19.and.
     &      ipdstmpl(2).eq.20) kpds(5) = 169
        If (ipdstmpl(16).eq.2.and.ipdstmpl(1).eq.19.and.
     &      ipdstmpl(2).eq.21) kpds(5) = 171
        If (ipdstmpl(16).eq.2.and.ipdstmpl(1).eq.19.and.
     &      ipdstmpl(2).eq.22) kpds(5) = 173
!
!  Special parameters for NAM (NMMB)
!
        If (idisc.eq.0.and.ipdstmpl(1).eq.2) then
           if (ipdstmpl(2).eq.220) then
               kpds(5) = 237
               kpds(19) = 129
           end if
           if (ipdstmpl(2).eq.221) then
               kpds(5) = 238
               kpds(19) = 129
           end if
           if (ipdstmpl(2).eq.222) then
               kpds(5) = 253
               kpds(19) = 129
           end if
           if (ipdstmpl(2).eq.223) then
               kpds(5) = 254
               kpds(19) = 129
           end if
        endif
!
        If (idisc.eq.0.and.ipdstmpl(2).eq.16
     &     .and.ipdstmpl(3).eq.198) then
           kpds(5) = 235
           kpds(19) = 129
        endif
!
        If (idisc.eq.0.and.ipdstmpl(2).eq.7
     &     .and.ipdstmpl(3).eq.199) then
           kpds(5) = 236
           kpds(19) = 129
        endif
!
!  Special parameters for ICAO Height at CB Base and Top
!  in GRIB1 Table 140
!
        If (ipdstmpl(1).eq.3.and.ipdstmpl(2).eq.3) then
           If (ipdstmpl(10).eq.11) then
              kpds(19) = 140
              kpds(5)  = 179
           end if
           If (ipdstmpl(10).eq.12) then
             kpds(19) = 140
             kpds(5)  = 180
           end if
        end if
!
        call levelcnv(ipdstmpl,kpds(6),kpds(7))      ! level
        kpds(8)=mod(idsect(6),100)
        if ( kpds(8).eq.0 ) kpds(8)=100
        kpds(9)=idsect(7)                            ! Year
        kpds(10)=idsect(8)                           ! Month
        kpds(11)=idsect(9)                           ! Day
        kpds(12)=idsect(10)                          ! Hour
        if ( ipdstmpl(8).ne.13 ) then
           kpds(13)=ipdstmpl(8)                      ! Time Unit
        else
           kpds(13)=254
        endif
        kpds(14)=ipdstmpl(9)                         ! P1
        if ( ipdsnum.le.7 ) then                     ! P2
           kpds(15)=0
           kpds(16)=0
           kpds(20)=0
           if ( kpds(14).eq.0 ) kpds(16)=1
           if ( kpds(14).gt.255 ) kpds(16)=10
           if ( ipdstmpl(5).eq.77.OR.ipdstmpl(5).eq.81.OR.
     &          ipdstmpl(5).eq.96.OR.ipdstmpl(5).eq.80.OR.
     &          ipdstmpl(5).eq.82.OR.ipdstmpl(5).eq.120.OR.
     &          ipdstmpl(5).eq.47.OR.ipdstmpl(5).eq.11 ) then 
              kpds(16)=10
           end if
           if (ipdstmpl(5).eq.84.AND.kpds(5).eq.154)kpds(16) = 10
!
!          NOAA Wave Watch III and Coastal Ocean Circulation
!          and Alaska Waters Regional Wave Model
!
           if ( ipdstmpl(5).eq.88.OR.ipdstmpl(5).eq.121
     &          .OR.ipdstmpl(5).eq.122.OR.ipdstmpl(5).eq.123
     &          .OR.ipdstmpl(5).eq.124.OR.ipdstmpl(5).eq.125
     &          .OR.ipdstmpl(5).eq.131.OR.ipdstmpl(5).eq.45
     &          .OR.ipdstmpl(5).eq.11 ) then
              kpds(16) = 0
!
! Level Surface set to 1
!
              if (kpds(5).eq.80.OR.kpds(5).eq.82.OR.
     &             kpds(5).eq.88.OR.kpds(5).eq.49.OR.
     &             kpds(5).eq.50) kpds(7)=1  ! Level Surface
              if (ipdstmpl(5).eq.122.OR.ipdstmpl(5).eq.124.OR.
     &            ipdstmpl(5).eq.131.OR.ipdstmpl(5).eq.123.OR.
     &            ipdstmpl(5).eq.125.OR.ipdstmpl(5).eq.88.OR.
     &            ipdstmpl(5).eq.121) kpds(7)=1
              if (idsect(1).eq.54.AND.ipdstmpl(5).eq.45) kpds(16) = 10
           endif
        else
           selectcase (ipdsnum)
            case(8)
              ipos=24
            case(9)
              ipos=31
            case(10)
              ipos=25
            case(11)
              ipos=27
            case(12)
              ipos=26
            case(13)
              ipos=40
            case(14)
              ipos=39
           end select
           kpds(15)=ipdstmpl(ipos+3)+kpds(14)  ! P2
           selectcase (ipdstmpl(ipos))
            case (255)
              kpds(16)=2
            case (0)
              kpds(16)=3
            case (1)
              kpds(16)=4
            case (2)
              kpds(16)=2
            case (3)
              kpds(16)=2
            case (4)
              kpds(16)=5
            case (51)
              kpds(16)=51
           end select
           kpds(20)=ipdstmpl(ipos-1)
        endif
        if (ipdstmpl(9) .ge. 252) then
           if (ipdstmpl(ipos+3).eq.3) then
               kpds(13)= 10                          ! Forecast time unit is 3-hour
               kpds(14)=ipdstmpl(9)/3                ! Time range P1
               kpds(15)=ipdstmpl(ipos+3)/3+kpds(14)  ! Time range P2
           else if (ipdstmpl(ipos+3).eq.6) then
               kpds(13)= 11                          ! Forecast time unit is 6-hour
               kpds(14)=ipdstmpl(9)/6                ! Time range P1
               kpds(15)=ipdstmpl(ipos+3)/6+kpds(14)  ! Time range P2
           else if (ipdstmpl(ipos+3).eq.12) then
               kpds(13)= 12                          ! Forecast time unit is 12-hour
               kpds(14)=ipdstmpl(9)/12               ! Time range P1
               kpds(15)=ipdstmpl(ipos+3)/12+kpds(14) ! Time range P2
           end if
        end if
        if (ipdsnum .eq. 8 .AND. ipdstmpl(9) .eq. 0) then
           if (ipdstmpl(ipos+3).ge.252) then
               kpds(13)= 10                          ! Forecast time unit is hour
               kpds(14)=ipdstmpl(9)/3                ! Time range P1
               kpds(15)=ipdstmpl(ipos+3)/3+kpds(14)  ! Time range P2
           end if
        end if
!
!  Checking total preciptation for 15-hr or 18-hr or 21-hr or 24-hr accumulation
!  after forecast hour F240
!
        if (ipdstmpl(9) .ge. 240 )then
            if ( ipdstmpl(ipos+3).eq.15 .OR. ipdstmpl(ipos+3).eq.18
     &     .OR. ipdstmpl(ipos+3).eq.21 .OR. 
     &     ipdstmpl(ipos+3).eq.24 ) then
               kpds(13)= 10                          ! Forecast time unit is 3-hour
               kpds(14)=ipdstmpl(9)/3                ! Time range P1
               kpds(15)=ipdstmpl(ipos+3)/3+kpds(14)  ! Time range P2
           end if
        end if
!
!   Checking Unit of Time Range for FNMOC (APCP)
!
        if (ipdstmpl(4).eq.58 .AND. ipdsnum.eq.11 .AND.
     &     (ipdstmpl(1).eq.1 .AND.ipdstmpl(2).eq.8)
     &     .AND. (ipdstmpl(10).eq.1)) then
           if (ipdstmpl(9) .ge. 252) then
              kpds(13)= 11      !  Forecast time unit is 6-hour
              kpds(14)=ipdstmpl(9)/6      ! Time range P1
              kpds(15)=ipdstmpl(ipos+3)/6+kpds(14)  ! Time range P2
           else 
              kpds(13)= 1       !  Forecast time unit is 1-hour
              kpds(14)=ipdstmpl(9)  ! Time range P1
           end if
         end if
!
!   Special case for FNMOC (TMAX and TMIN)
!
        if (ipdstmpl(4).eq.58 .AND. ipdsnum.eq.11 .AND.
     &     (ipdstmpl(1).eq.0
     &     .AND.ipdstmpl(2).eq.0).AND.(ipdstmpl(10).eq.103)) then
           kpds(16) = 2
!   For Maximum Temperature
        If (ipdstmpl(27).eq.2 .AND. ipdstmpl(1).eq.0 .AND.
     &      ipdstmpl(2).eq.0) kpds(5) = 15
!   For Minimum Temperature
        If (ipdstmpl(27).eq.3 .AND. ipdstmpl(1).eq.0 .AND.
     &      ipdstmpl(2).eq.0) kpds(5) = 16
        end if
!
!   Special case for WAFS (Mean/MAx IP,CTP and CAT)
!
        if (ipdstmpl(5).eq.96.AND.((ipdstmpl(1).eq.19)
     &     .AND.(ipdstmpl(2).eq.20.or.ipdstmpl(2).eq.21.or.
     &     ipdstmpl(2).eq.22)).AND.(ipdstmpl(10).eq.100)) then
           kpds(16) = 10
        end if
!
        kpds(17)=0
        kpds(18)=1                                   ! GRIB edition
        kpds(21)=(idsect(6)/100)+1                   ! Century
        if ( kpds(8).eq.100 ) kpds(21)=idsect(6)/100
        kpds(22)=idrstmpl(3)                         ! Decimal scale factor
        kpds(23)=idsect(2)                           ! Sub-center
        return
        end


        subroutine levelcnv(ipdstmpl,ltype,lval)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!                .     .   .                                      .
! SUBPROGRAM:    levelcnv
!   PRGMMR: Gilbert        ORG: W/NP11     DATE: 2003-06-12
!
! ABSTRACT: this routine converts Level/layer information
!   from a GRIB2 Product Definition Template to GRIB1 
!   Level type and Level value.
!
! PROGRAM HISTORY LOG:
! 2003-06-12  Gilbert
! 2007-10-24  Boi Vuong  - Added level 8 (Nominal top of atmosphere)
! 2011-01-13  Boi Vuong  - Added level/layer values from 235 to 239
!
! USAGE:    CALL levelcnv(ipdstmpl,ltype,lval)
!   INPUT ARGUMENT LIST:
!     ipdstmpl() - GRIB2 Product Definition Template values
!
!   OUTPUT ARGUMENT LIST:      (INCLUDING WORK ARRAYS)
!     ltype    - GRIB1 level type (PDS octet 10)
!     lval     - GRIB1 level/layer value(s) (PDS octets 11 and 12)
!
! REMARKS: LIST CAVEATS, OTHER HELPFUL HINTS OR INFORMATION
!
! ATTRIBUTES:
!   LANGUAGE: Fortran 90
!   MACHINE:  IBM SP
!
!$$$

        integer,intent(in) :: ipdstmpl(*)
        integer,intent(out) :: ltype,lval

        ltype=255
        lval=0
        ltype1=ipdstmpl(10)
        ltype2=ipdstmpl(13)

        if ( ltype1.eq.10.AND.ltype2.eq.255 ) then
           ltype=200
           lval=0
        elseif ( ltype1.eq.11.AND.ltype2.eq.255 ) then
           ltype=216
           lval=0
        elseif ( ltype1.eq.12.AND.ltype2.eq.255 ) then
           ltype=217
           lval=0
        elseif ( ltype1.lt.100.AND.ltype2.eq.255 ) then
           ltype=ltype1
           lval=0
        elseif ( ltype1.eq.1.AND.ltype2.eq.8 ) then
           ltype=ltype1
           lval=0
        elseif ( ltype1.eq.10.AND.ltype2.eq.255 ) then
           ltype=200
           lval=0
        elseif ( ltype1.eq.235.AND.ltype2.eq.255 ) then
           ltype=235
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1)
        elseif ( ltype1.ge.200.AND.ltype2.eq.255 ) then
           ltype=ltype1
           lval=0
        elseif (ltype1.eq.100.AND.ltype2.eq.255 ) then
           ltype=100
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1/100.)
        elseif (ltype1.eq.100.AND.ltype2.eq.100 ) then
           ltype=101
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1/1000.)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2/1000.)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.101.AND.ltype2.eq.255 ) then
           ltype=102
           lval=0
        elseif (ltype1.eq.102.AND.ltype2.eq.255 ) then
           ltype=103
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1)
        elseif (ltype1.eq.102.AND.ltype2.eq.102 ) then
           ltype=104
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.103.AND.ltype2.eq.255 ) then
           ltype=105
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1)
        elseif (ltype1.eq.103.AND.ltype2.eq.103 ) then
           ltype=106
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1/100.)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2/100.)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.104.AND.ltype2.eq.255 ) then
           ltype=107
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1*10000.)
        elseif (ltype1.eq.104.AND.ltype2.eq.104 ) then
           ltype=108
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1*100.)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2*100.)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.105.AND.ltype2.eq.255 ) then
           ltype=109
           lval=ipdstmpl(12)
        elseif (ltype1.eq.105.AND.ltype2.eq.105 ) then
           ltype=110
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.106.AND.ltype2.eq.255 ) then
           ltype=111
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1*100.)
        elseif (ltype1.eq.106.AND.ltype2.eq.106 ) then
           ltype=112
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1*100.)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2*100.)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.107.AND.ltype2.eq.255 ) then
           ltype=113
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1)
        elseif (ltype1.eq.107.AND.ltype2.eq.107 ) then
           ltype=114
           rscal1=10.**(-ipdstmpl(11))
           lval1=475-nint(real(ipdstmpl(12))*rscal1)
           rscal2=10.**(-ipdstmpl(14))
           lval2=475-nint(real(ipdstmpl(15))*rscal2)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.108.AND.ltype2.eq.255 ) then
           ltype=115
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1/100.)
        elseif (ltype1.eq.108.AND.ltype2.eq.108 ) then
           ltype=116
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1/100.)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2/100.)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.109.AND.ltype2.eq.255 ) then
           ltype=117
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1*1000000000.)
        elseif (ltype1.eq.111.AND.ltype2.eq.255 ) then
           ltype=119
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1*10000.)
        elseif (ltype1.eq.111.AND.ltype2.eq.111 ) then
           ltype=120
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1*100.)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2*100.)
           lval=(lval1*256)+lval2
        elseif (ltype1.eq.160.AND.ltype2.eq.255 ) then
           ltype=160
           rscal1=10.**(-ipdstmpl(11))
           lval=nint(real(ipdstmpl(12))*rscal1)
        elseif ((ltype1.ge.236.AND.ltype1.le.239).AND.
     &     (ltype2.ge.236.AND.ltype2.le.239)) then
           ltype=ltype1
           rscal1=10.**(-ipdstmpl(11))
           lval1=nint(real(ipdstmpl(12))*rscal1)
           rscal2=10.**(-ipdstmpl(14))
           lval2=nint(real(ipdstmpl(15))*rscal2)
           lval=(lval1*256)+lval2
        else
           print *,'levelcnv: GRIB2 Levels ',ltype1,ltype2,
     &             ' not recognized.'
           ltype=255
        endif

!  High resolution stuff
!        elseif (ltype.eq.121) then
!           ipdstmpl(10)=100
!           ipdstmpl(12)=(1100+(lval/256))*100
!           ipdstmpl(13)=100
!           ipdstmpl(15)=(1100+mod(lval,256))*100
!        elseif (ltype.eq.125) then
!           ipdstmpl(10)=103
!           ipdstmpl(11)=-2
!           ipdstmpl(12)=lval
!        elseif (ltype.eq.128) then
!           ipdstmpl(10)=104
!           ipdstmpl(11)=-3
!           ipdstmpl(12)=1100+(lval/256)
!           ipdstmpl(13)=104
!           ipdstmpl(14)=-3
!           ipdstmpl(15)=1100+mod(lval,256)
!        elseif (ltype.eq.141) then
!           ipdstmpl(10)=100
!           ipdstmpl(12)=(lval/256)*100
!           ipdstmpl(13)=100
!           ipdstmpl(15)=(1100+mod(lval,256))*100

        return
        end


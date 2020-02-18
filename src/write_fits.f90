!-----------------------------------------------------------------
!
!  This file is (or was) part of SPLASH, a visualisation tool
!  for Smoothed Particle Hydrodynamics written by Daniel Price:
!
!  http://users.monash.edu.au/~dprice/splash
!
!  SPLASH comes with ABSOLUTELY NO WARRANTY.
!  This is free software; and you are welcome to redistribute
!  it under the terms of the GNU General Public License
!  (see LICENSE file for details) and the provision that
!  this notice remains intact. If you modify this file, please
!  note section 2a) of the GPLv2 states that:
!
!  a) You must cause the modified files to carry prominent notices
!     stating that you changed the files and the date of any change.
!
!  Copyright (C) 2020- Daniel Price. All rights reserved.
!  Contact: daniel.price@monash.edu
!
!-----------------------------------------------------------------
!----------------------------------------------------------------------
!
!  Module handling read and write of FITS files
!  With thanks to Christophe Pinte
!
!----------------------------------------------------------------------
module readwrite_fits
 implicit none
 public :: read_fits_image,write_fits_image,fits_error
 public :: read_fits_cube

 private

contains

!---------------------------------------------------
! subroutine to read image from FITS file
! using cfitsio library
!---------------------------------------------------
subroutine read_fits_image(filename,image,naxes,ierr)
 character(len=*), intent(in)   :: filename
 real, intent(out), allocatable :: image(:,:)
 integer, intent(out) :: naxes(2),ierr
 integer :: iunit,ireadwrite,npixels,blocksize
 integer :: firstpix,nullval,group,nfound
 logical :: anynull
 integer :: naxis,ndim,myaxes(3)
 !
 !--open file and read header information
 !
 ierr = 0
 call ftgiou(iunit,ierr)

 ireadwrite = 0
 call ftopen(iunit,filename,ireadwrite,blocksize,ierr)
 if (ierr /= 0) then
    ierr = -1
    return
 endif

 call ftgknj(iunit,'NAXIS',1,2,naxes,nfound,ierr)
 npixels = naxes(1)*naxes(2)
 !
 !--sanity check the header read
 !
 if (npixels <= 0) then
    !print*,' ERROR: No pixels found'
    ierr = 1
    return
 endif
 !
 ! read image
 !
 firstpix = 1
 nullval = -999
 group = 1
 allocate(image(naxes(1),naxes(2)),stat=ierr)
 if (ierr /= 0) then
    ierr = 2
    return
 endif
 ierr = 0
 call ftgpve(iunit,group,firstpix,npixels,nullval,image,anynull,ierr)
 call ftclos(iunit,ierr)
 call ftfiou(iunit,ierr)

end subroutine read_fits_image

!---------------------------------------------------
! subroutine to read spectral cube from FITS file
! using cfitsio library
!---------------------------------------------------
subroutine read_fits_cube(filename,image,naxes,ierr)
 character(len=*), intent(in)   :: filename
 real, intent(out), allocatable :: image(:,:,:)
 integer, intent(out) :: naxes(3),ierr
 integer :: iunit,ireadwrite,npixels,blocksize
 integer :: firstpix,nullval,group,nfound
 logical :: anynull
 integer :: naxis,ndim,myaxes(3)
 !
 !--open file and read header information
 !
 ierr = 0
 call ftgiou(iunit,ierr)

 ireadwrite = 0
 call ftopen(iunit,filename,ireadwrite,blocksize,ierr)
 if (ierr /= 0) then
    ierr = -1
    return
 endif

 call ftgidm(iunit,ndim,ierr) ! get_img_dim
 call ftgisz(iunit,3,naxes,ierr)
 if (naxes(3)==0) naxes(3) = 1
 ! call ftgknj(iunit,'NAXIS',1,2,naxes,nfound,ierr)
 npixels = product(naxes)
 !
 !--sanity check the header read
 !
 if (npixels <= 0) then
    ierr = 1
    return
 endif
 !
 ! read images
 !
 firstpix = 1
 nullval = -999
 group = 1
 allocate(image(naxes(1),naxes(2),naxes(3)),stat=ierr)
 if (ierr /= 0) then
    ierr = 2
    return
 endif
 ierr = 0
 call ftgpve(iunit,group,firstpix,npixels,nullval,image,anynull,ierr)
 call ftclos(iunit,ierr)
 call ftfiou(iunit,ierr)
  
end subroutine read_fits_cube

!---------------------------------------------------
! error code handling
!---------------------------------------------------
 character(len=30) function fits_error(ierr)
  integer, intent(in) :: ierr

  select case(ierr)
  case(2)
     fits_error = 'could not allocate memory'
  case(1)
     fits_error = 'no pixels found'
  case(-1)
     fits_error = 'could not open fits file'
  case default
     fits_error = 'unknown error'
  end select

 end function fits_error

!------------------------------------------------
! Writing new fits file
!------------------------------------------------
 subroutine write_fits_image(filename,image,naxes,ierr)
  character(len=*), intent(in) :: filename
  integer, intent(in)  :: naxes(2)
  real(kind=4),     intent(in) :: image(naxes(1),naxes(2))
  integer, intent(out) :: ierr
  integer :: iunit,blocksize,group,firstpixel,bitpix,npixels
  logical :: simple,extend

  !  Get an unused Logical Unit Number to use to open the FITS file.
  ierr = 0
  call ftgiou(iunit,ierr)

  !  Create the new empty FITS file.
  blocksize=1
  print "(a)",' writing '//trim(filename)
  call ftinit(iunit,filename,blocksize,ierr)

  !  Initialize parameters about the FITS image
  simple=.true.
  ! data size
  bitpix=-32
  extend=.true.

  !  Write the required header keywords.
  call ftphpr(iunit,simple,bitpix,2,naxes,0,1,extend,ierr)

  group=1
  firstpixel=1
  npixels = naxes(1)*naxes(2)
  ! write as real*4
  call ftppre(iunit,group,firstpixel,npixels,image,ierr)

  !  Close the file and free the unit number
  call ftclos(iunit, ierr)
  call ftfiou(iunit, ierr)

 end subroutine write_fits_image

end module readwrite_fits
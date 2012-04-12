!-*- mode: F90; mode: font-lock -*-!

module w90_wan_ham

  use w90_constants, only : dp

  implicit none

  contains


  subroutine get_D_h_a(delHH_a,UU,eig,D_h_a)
  !===============================================!
  !                                               !
  ! Compute D^H_a=UU^dag.del_a UU (a=alpha,beta), !
  ! using Eq.(24) of WYSV06                       !
  !                                               !
  !===============================================!

    ! TO DO: Implement version where energy denominators only connect
    !        occupied and empty states. In this case probably do not need
    !        to worry about avoiding small energy denominators

    use w90_constants, only     : dp,cmplx_0,cmplx_i
    use w90_parameters, only    : num_wann,fermi_energy
    use w90_utility, only       : utility_rotate
    use w90_wanint_common, only : get_occ
    use w90_io, only            : stdout !debug

    ! Arguments
    !
    complex(kind=dp), dimension(:,:), intent(in)  :: delHH_a
    complex(kind=dp), dimension(:,:), intent(in)  :: UU
    real(kind=dp),    dimension(:),   intent(in)  :: eig
    complex(kind=dp), dimension(:,:), intent(out) :: D_h_a

    complex(kind=dp), allocatable :: delHH_a_bar(:,:)
    real(kind=dp)                 :: occ(num_wann)
    integer                       :: n,m

    call get_occ(eig,occ,fermi_energy)

    allocate(delHH_a_bar(num_wann,num_wann))
    delHH_a_bar=utility_rotate(delHH_a,UU,num_wann)
    do m=1,num_wann
       do n=1,num_wann
          if(occ(n)>0.999_dp.and.occ(m)<0.001) then
             D_h_a(n,m)=delHH_a_bar(n,m)/(eig(m)-eig(n))
          else
             D_h_a(n,m)=cmplx_0
          end if
       end do
    end do
    D_h_a=D_h_a-conjg(transpose(D_h_a))

  end subroutine get_D_h_a


  subroutine get_JJplus(delHH,UU,eig,JJplus)
  !==================================!
  !                                  !
  ! Compute JJ^+_a (a=alpha or beta) !
  !                                  !
  !==================================!

    use w90_constants, only     : dp,cmplx_0,cmplx_i
    use w90_parameters, only    : num_wann,fermi_energy
    use w90_utility, only   : utility_rotate

    complex(kind=dp), dimension(:,:), intent(in)  :: delHH
    complex(kind=dp), dimension(:,:), intent(in)  :: UU
    real(kind=dp),    dimension(:),   intent(in)  :: eig
    complex(kind=dp), dimension(:,:), intent(out) :: JJplus

    complex(kind=dp), allocatable :: delHH_bar(:,:)
    integer                       :: n,m

    allocate(delHH_bar(num_wann,num_wann))
    delHH_bar=utility_rotate(delHH,UU,num_wann)
    do m=1,num_wann
       do n=1,num_wann
          if(eig(n)>fermi_energy .and. eig(m)<fermi_energy) then
             JJplus(n,m)=cmplx_i*delHH_bar(n,m)/(eig(m)-eig(n))
          else
             JJplus(n,m)=cmplx_0
          end if
       end do
    end do
    JJplus=utility_rotate(JJplus,conjg(transpose(UU)),num_wann)

  end subroutine get_JJplus


  subroutine get_JJminus(delHH,UU,eig,JJminus)
  !==================================!
  !                                  !
  ! Compute JJ^-_a (a=alpha or beta) !
  !                                  !
  !==================================!

    use w90_constants, only     : dp,cmplx_0,cmplx_i
    use w90_parameters, only    : num_wann,fermi_energy
    use w90_utility, only   : utility_rotate

    complex(kind=dp), dimension(:,:), intent(in)  :: delHH
    complex(kind=dp), dimension(:,:), intent(in)  :: UU
    real(kind=dp),    dimension(:),   intent(in)  :: eig
    complex(kind=dp), dimension(:,:), intent(out) :: JJminus

    complex(kind=dp), allocatable :: delHH_bar(:,:)
    integer                       :: n,m

    allocate(delHH_bar(num_wann,num_wann))
    delHH_bar=utility_rotate(delHH,UU,num_wann)
    do m=1,num_wann
       do n=1,num_wann
          if(eig(m)>fermi_energy .and. eig(n)<fermi_energy) then
             JJminus(n,m)=cmplx_i*delHH_bar(n,m)/(eig(m)-eig(n))
          else
             JJminus(n,m)=cmplx_0
          end if
       end do
    end do
    JJminus=utility_rotate(JJminus,conjg(transpose(UU)),num_wann)

  end subroutine get_JJminus


  subroutine get_occ_mat(eig,UU,f,g)
  !================================!
  !                                !
  ! Occupation matrix f, and g=1-f !
  !                                !
  !================================!
    
    use w90_constants, only     : dp,cmplx_0
    use w90_parameters, only    : fermi_energy,num_wann
    use w90_wanint_common, only : get_occ

    ! Arguments
    !
    real(kind=dp),    dimension(:),   intent(in)  :: eig
    complex(kind=dp), dimension(:,:), intent(in)  :: UU
    complex(kind=dp), dimension(:,:), intent(out) :: f
    complex(kind=dp), dimension(:,:), intent(out) :: g

    real(kind=dp) :: occ(num_wann)
    integer       :: n,m,i

    call get_occ(eig,occ,fermi_energy)
    f=cmplx_0; g=cmplx_0
    do n=1,num_wann
       do m=1,num_wann
          do i=1,num_wann
             f(n,m)=f(n,m)+UU(n,i)*occ(i)*conjg(UU(m,i))
          enddo
          g(n,m)=-f(n,m)
          if(m==n) g(n,n)=g(n,n)+1.0_dp
       enddo
    enddo

  end subroutine get_occ_mat


  subroutine get_deleig_a(deleig_a,eig,delHH_a,UU)
  !==========================!
  !                          !
  ! Band derivatives dE/dk_a !
  !                          !
  !==========================!

    use w90_constants, only   : dp,cmplx_0,cmplx_i
    use w90_utility, only : utility_diagonalize,utility_rotate,utility_rotate_diag
    use w90_parameters, only  : num_wann,use_degen_pert,degen_thr

    ! Arguments
    !
    real(kind=dp),                    intent(out) :: deleig_a(num_wann)
    real(kind=dp),                    intent(in)  :: eig(num_wann)
    complex(kind=dp), dimension(:,:), intent(in)  :: delHH_a
    complex(kind=dp), dimension(:,:), intent(in)  :: UU

    ! Misc/Dummy
    !
    integer                       :: i,degen_min,degen_max,dim
    real(kind=dp)                 :: diff
    complex(kind=dp), allocatable :: delHH_bar_a(:,:),U_deg(:,:)

    allocate(delHH_bar_a(num_wann,num_wann))
    allocate(U_deg(num_wann,num_wann))
    
    if(use_degen_pert) then
       
       delHH_bar_a=utility_rotate(delHH_a,UU,num_wann)
       
       ! Assuming that the energy eigenvalues are stored in eig(:) in
       ! increasing order (diff >= 0)
       
       i=0
       do 
          i=i+1
          if(i>num_wann) exit
          if(i+1 <= num_wann) then
             diff=eig(i+1)-eig(i)
          else
             !
             ! i-th is the highest band, and it is non-degenerate
             !
             diff =degen_thr+1.0_dp
          end if
          if(diff<degen_thr) then
             !
             ! Bands i and i+1 are degenerate 
             !
             degen_min=i
             degen_max=degen_min+1
             !
             ! See if any higher bands are in the same degenerate group
             !
             do
                if(degen_max+1>num_wann) exit
                diff=eig(degen_max+1)-eig(degen_max)
                if(diff<degen_thr) then
                   degen_max=degen_max+1
                else
                   exit
                end if
             end do
             !
             ! Bands from degen_min to degen_max are degenerate. Diagonalize 
             ! the submatrix in Eq.(31) YWVS07 over this degenerate subspace.
             ! The eigenvalues are the band gradients
             !
             !
             dim=degen_max-degen_min+1
             call utility_diagonalize(delHH_bar_a(degen_min:degen_max,&
                  degen_min:degen_max),dim,&
                  deleig_a(degen_min:degen_max),U_deg(1:dim,1:dim))
             !
             ! Scanned bands up to degen_max
             !
             i=degen_max
          else
             !
             ! Use non-degenerate form [Eq.(27) YWVS07] for current (i-th) band
             !
             deleig_a(i)=aimag(cmplx_i*delHH_bar_a(i,i))
          end if
       end do
       
    else
       
       ! Use non-degenerate form for all bands
       !
       deleig_a(:)=aimag(cmplx_i*utility_rotate_diag(delHH_a(:,:),UU,num_wann))

    end if
    
  end subroutine get_deleig_a
  
end module w90_wan_ham
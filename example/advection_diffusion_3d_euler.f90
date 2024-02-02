program advection_diffusion_3d_euler

    use self_data
    use self_advection_diffusion_3d
  
    implicit none
    character(SELF_INTEGRATOR_LENGTH), parameter :: integrator = 'euler'
    integer, parameter :: nvar = 1
    integer,parameter :: controlDegree = 7
    integer,parameter :: targetDegree = 16
    real(prec), parameter :: u = 0.25_prec ! velocity
    real(prec), parameter :: v = 0.25_prec
    real(prec), parameter :: w = 0.25_prec
    real(prec), parameter :: nu = 0.001_prec ! diffusivity
    real(prec), parameter :: dt = 1.0_prec*10.0_prec**(-4) ! time-step size
    real(prec), parameter :: endtime = 0.001_prec
    real(prec), parameter :: iointerval = 0.001_prec
    type(advection_diffusion_3d) :: modelobj
    type(Lagrange),target :: interp
    type(Mesh3D),target :: mesh
    type(SEMHex),target :: geometry
    type(MPILayer),target :: decomp
    CHARACTER(LEN=255) :: WORKSPACE

    ! We create a domain decomposition.
    call decomp % Init(enableMPI=.false.)

    ! Create a uniform block mesh
    call get_environment_variable("WORKSPACE",WORKSPACE)
    call mesh % Read_HOPr(trim(WORKSPACE)//"/share/mesh/Block3D/Block3D_mesh.h5",decomp)
  
    ! Create an interpolant
    call interp % Init(N=controlDegree, &
                       controlNodeType=GAUSS, &
                       M=targetDegree, &
                       targetNodeType=UNIFORM)
  
    ! Generate geometry (metric terms) from the mesh elements
    call geometry % Init(interp,mesh % nElem)
    call geometry % GenerateFromMesh(mesh)
  
    ! Initialize the model
    call modelobj % Init(nvar,mesh,geometry,decomp)
  
    ! Set the velocity
    modelobj % u = u
    modelobj % v = v
    modelobj % w = w
    !Set the diffusivity
    modelobj % nu = nu
  
    ! Set the initial condition
    call modelobj % solution % SetEquation( 1, 'f = \exp( -( (x-0.5)^2 + (y-0.5)^2 + (z-0.5)^2 )/0.005 )')
    call modelobj % solution % SetInteriorFromEquation( geometry, 0.0_prec ) 
  
    print*, "min, max (interior)", &
      minval(modelobj % solution % interior % hostdata), &
      maxval(modelobj % solution % interior % hostdata)
  
    ! Set the model's time integration method
    call modelobj % SetTimeIntegrator( integrator )
  
    ! forward step the model to `endtime` using a time step
    ! of `dt` and outputing model data every `iointerval`
    call modelobj % ForwardStep(endtime,dt,iointerval)
  
    print*, "min, max (interior)", &
    minval(modelobj % solution % interior % hostdata), &
    maxval(modelobj % solution % interior % hostdata)
  
    ! Clean up
    call modelobj % free()
    call decomp % free()
    call mesh % free()
    call geometry % free()
    call interp % free()
    
  
  end program advection_diffusion_3d_euler
  
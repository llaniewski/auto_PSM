
source("lib/lattice.R")

xyz = c("x","y","z")
XYZ = c("X","Y","Z")

if (Options$q19) {
    U = d3q19
} else if (Options$q27) {
    U = d3q27
    ## For ordering matching Nathan's model:
    # w = c(1,2,3,4,5,6,7,16,17,18,19,20,21,22,23,24,25,26,27,8,9,10,11,12,13,14,15)
    # U = U[w,]
} else stop("Unknown")

AddDensity( name=paste0("f",1:nrow(U)-1), dx=U[,1], dy=U[,2], dz=U[,3], group="f")

# Accessing adjacent nodes
# for (d in rows(DensityAll)) AddField( name=d$name,  dx=c(1,-1), dy=c(1,-1), dz=c(1,-1) )

AddDensity( name="sol",  group="Force", parameter=TRUE)
AddDensity( name="solB", group="Force", parameter=TRUE)
AddDensity( name=paste0("uP",xyz), group="Force", parameter=TRUE)

AddGlobal(name="TotalSVF", comment='Total of solids throughout domain')

AddQuantity(name="U",unit="m/s",vector=T)
AddQuantity(name="UP",unit="m/s",vector=T)
AddQuantity(name="P",unit="Pa")
AddQuantity(name="Solid",unit="1")
AddQuantity(name="B",unit="1")

AddSetting(name="nu", default=1/6, comment='kinetic viscosity in LBM unit', unit='m2/s')
AddSetting( name="Lambda", comment="TRT Magic Number")

AddSetting(name=paste0("Velocity",XYZ), default="0.0", zonal=TRUE, comment=paste0('wall/inlet/outlet velocity ',xyz,'-direction'))

AddSetting(name="Pressure", default="0Pa", comment='Inlet pressure', zonal=TRUE, unit="1Pa")

AddSetting(name=paste0("Accel",XYZ), default=0.0, comment=paste0('body acceleration ',xyz,'-direction'), zonal=TRUE, unit="m/s2")

AddGlobal(name=paste0("TotalFluidMomentum",XYZ), unit="kgm/s")
AddGlobal(name="TotalFluidMass", unit="kg")
AddGlobal(name="TotalFluidVolume", unit="m3")
AddGlobal(name=paste0("TotalSolidMomentum",XYZ), unit="kgm/s")
AddGlobal(name="TotalSolidMass", unit="kg")
AddGlobal(name="TotalSolidVolume", unit="m3")

BC = expand.grid(side=1:6, type_name=c("Velocity","Pressure"))
BC$type = tolower(BC$type_name)
BC$side_name = c("W","E","S","N","F","B")[BC$side]
BC$direction = rep(1:3,each=2)[BC$side]
BC$sign = rep(c(1,-1),times=3)[BC$side]
BC$name = paste0(BC$side_name,BC$type_name)

AddNodeType(name=BC$name, group="BOUNDARY")

if (Options$singlekernel) {
        AddStage("BaseInit", "Init", save = TRUE, load = FALSE)
        AddStage("BaseIteration", "Run", save = TRUE, load = TRUE, particle = TRUE)
        AddAction("Iteration", "BaseIteration")
        AddAction("Init", "BaseInit")
} else {
        AddStage("BaseInit", "Init", save = TRUE, load = FALSE, particle=TRUE)
        AddStage("BaseIteration", "Run", save = Fields$group %in% "f", load = TRUE)
        AddStage("CalcF", save = Fields$group %in% "Force", load = DensityAll$group %in% "f", particle=TRUE)
        AddAction("Iteration", c("BaseIteration", "CalcF"))
        AddAction("Init", c("BaseInit"))
}

AddNodeType(name="Wall", group="COLLISION")
AddNodeType(name="BGK", group="COLLISION")
AddNodeType(name="TRT", group="COLLISION")

# AddNodeType(name="Trivial", group="TRANSFER") // Default
AddNodeType(name="TN", group="TRANSFER")
AddNodeType(name="LLW", group="TRANSFER")

# AddNodeType(name="Classic", group="FORCING") // Default
AddNodeType(name="NEBB", group="FORCING")
AddNodeType(name="SUP", group="FORCING")
AddNodeType(name="EDM", group="FORCING")
AddNodeType(name="MWBB", group="FORCING")

if require("nature.core.os").os_name == "Linux" then
    require("ngx.re").opt("jit_stack_size", 200 * 1024)
end
require("jit.opt").start("minstitch=2", "maxtrace=4000", "maxrecord=8000",
    "sizemcode=64", "maxmcode=4000", "maxirconst=1000")

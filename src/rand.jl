import OpenCL
const cl = OpenCL

randSource = open(readall, joinpath(dirname(Base.source_path()), "rand.cl"))

kern_dict = Dict()
function randByCtx(ctx)
    local kern = get(kern_dict, ctx, nothing)
    if(kern == nothing)
       # build the program and
       p = cl.Program(ctx, source=randSource)
       p = cl.build!(p, options=string("-I", joinpath(dirname(Base.source_path()), "../", " -w")))
       #dev, log = OpenCL.info(p, :build_log)
       #println("Build Error:", log)
       # construct a kernel obje
       kern = cl.Kernel(p, RAND_FUNC)
       kern_dict[ctx] = kern
    end
    return kern
end



function randBuf(dims::Int...; ctx=nothing, queue=nothing)
    if(ctx == nothing)
         device, ctx, queue = get_next_compute_context()
    end
    local dim = 1;
    for i=1:length(dims)
         dim *= dims[i]
    end

    kernel = randByCtx(ctx)

    seed = uint32(time_ns())
    cl.set_arg!(kernel, 1, seed)
    globalMem = cl.Buffer(Float32, ctx, :rw, dim)
    cl.set_arg!(kernel, 2, globalMem)

    evt = cl.enqueue_kernel(queue, kernel, dim/4)

    return Future(ctx, queue, globalMem, dims, evt)
end

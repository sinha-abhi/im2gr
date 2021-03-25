# api functions

# probably don't use `track` when benchmarking
function im2gr!(
  image::AbstractImage{T},
  mode::ConstructionMode;
  diff_fn::Function = __default_diff_fn,
  track::Bool = false
) where T <: Unsigned
  if track
    sz = size(image.data)
    @printf("Image size: %d, %d, %d\n", sz[1], sz[2], sz[3])
    @printf("Search distance: %d\n", image.d)
    @printf("Result vector upper bound: %d\n", image.ub)
    @printf("Loading image... %s\n", mode)
  end

  (mode == SingleThread) && load_st!(image, diff_fn, track)
  (mode == MultiThread) && load_st!(image, diff_fn, track)
  (mode == CUDA) && load_st!(image, diff_fn, track)

  # reshape vectors to actual length
  resize!(image.ei, image.vc)
  resize!(image.ej, image.vc)
  resize!(image.evd, image.vc)
  resize!(image.evi, image.vc)

  nothing
end

# udpate image -- new data or new d or both
function update_image!(
  image::AbstractImage{T};
  data::Union{Nothing, AbstractArray{T}} = nothing,
  d::Union{Nothing, Int} = nothing
)::Bool where T <: Unsigned
  # this is kinda crappy
  udata = !isequal(image.data, data)
  ud = image.d != d
  update = (d != nothing) || (data != nothing)
  update = update && (udata && ud)
  if update
    udata && (image.data = data)
    ud && (image.d = d)

    ub = graph_vector_ub(size(image.data), image.d)
    image.ub = ub
    image.ei = Vector{Int}(undef, ub)
    image.ej = Vector{Int}(undef, ub)
    image.evd = Vector{Int}(undef, ub)
    image.evi = Vector{Int}(undef, ub)
  end

  update
end
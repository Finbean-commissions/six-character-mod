function TSIL.RNG.CopyRNG(rng)
    local seed = rng:GetSeed()
    return TSIL.RNG.NewRNG(seed)
end

bugs_model_def = JuliaBUGS.BUGSExamples.VOLUME_I[:blockers].model_def
data = JuliaBUGS.BUGSExamples.VOLUME_I[:blockers].data
inits = JuliaBUGS.BUGSExamples.VOLUME_I[:blockers].inits[1]

bugs_model = compile(bugs_model_def, data, inits)

@model function blockers(rc, rt, nc, nt, Num)
    d ~ dnorm(0.0, 1.0E-6)
    tau ~ dgamma(0.001, 0.001)

    mu = Vector{Real}(undef, Num)
    delta = Vector{Real}(undef, Num)
    pc = Vector{Real}(undef, Num)
    pt = Vector{Real}(undef, Num)

    for i in 1:Num
        mu[i] ~ dnorm(0.0, 1.0E-5)
        delta[i] ~ dnorm(d, tau)

        pc[i] = logistic(mu[i])
        pt[i] = logistic(mu[i] + delta[i])

        rc[i] ~ dbin(pc[i], nc[i])
        rt[i] ~ dbin(pt[i], nt[i])
    end

    var"delta.new" ~ dnorm(d, tau)
    sigma = 1 / sqrt(tau)

    return sigma
end

@unpack rt, nt, rc, nc, Num = data
dppl_model = blockers(rc, rt, nc, nt, Num)

vi, bugs_logp = get_vi_logp(bugs_model, false)
params_vi = JuliaBUGS.get_params_varinfo(bugs_model, vi)
# test if JuliaBUGS and DynamicPPL agree on parameters in the model
@test params_in_dppl_model(dppl_model) == keys(params_vi)

vi, dppl_logp = get_vi_logp(dppl_model, vi, false)
@test bugs_logp ≈ -8418.416388 rtol = 1E-6
@test bugs_logp ≈ dppl_logp rtol = 1E-6

vi, bugs_logp = get_vi_logp(bugs_model, true)
vi, dppl_logp = get_vi_logp(dppl_model, vi, true)
@test bugs_logp ≈ dppl_logp rtol = 1E-6

using CxxWrap: StdVector
using FastJet
using Test

function printInfo(jets)
    # print out some infos
    # println("Clustering with ", description(jet_def))
    # print the jets
    println("        pt y phi")
    for i = 1:length(jets)
        println("jet ", i, ": ", pt(jets[i]), " ", rap(jets[i]), " ", phi(jets[i]))
        constits = constituents(jets[i])
        for j = 1:length(constits)
            println("    constituent ", j, "'s pt: ", pt(constits[j]), " index ", user_index(constits[j]))
        end
    end
end

# this is the example from http://www.fastjet.fr/quickstart.html
function main()
    particles = PseudoJet[]
    # an event with 3 particles:  px    py   pz   E
    push!(particles, PseudoJet(  99.0,  0.1, 0, 100.0))
    push!(particles, PseudoJet(   4.0, -0.1, 0,   5.0))
    push!(particles, PseudoJet( -99.0,    0, 0,  99.0))
    set_user_index(particles[1], 22)
    set_user_index(particles[2], 24)
    set_user_index(particles[3], 26)
  
    # choose a jet definition
    @testset "Core functionality -- antikt" begin
        R = 0.7
        jet_def = JetDefinition(antikt_algorithm, R)
        # run the clustering, extract the jets
        cs = ClusterSequence(StdVector(particles), jet_def)
        GC.@preserve cs begin
            GC.gc()
            jets = inclusive_jets(cs, 0.0)
            @test length(jets) == 2
            printInfo(jets)
            println(FastJet.four_mom(jets[1]))
            println(FastJet.four_mom(jets[2]))
        end
    end
    # choose a jet definition
    @testset "Core functionality -- ee_gen_kt" begin
        R = 4.0
        p = 1.0 # generalized algorithm: p=1: kt; p=-1: anti-kt; p=0: Cambridge
        jet_def = JetDefinition(FastJet.ee_genkt_algorithm, R, p)
        # run the clustering, extract the jets
        cs = ClusterSequence(StdVector(particles), jet_def)
        GC.@preserve cs begin
            GC.gc()
            jets = exclusive_jets(cs, 2)
            @test length(jets) == 2
            printInfo(jets)
            println(FastJet.four_mom(jets[1]))
            println(FastJet.four_mom(jets[2]))
        end
    end
    @testset "Core functionality -- Durham" begin
        jet_def = JetDefinition(FastJet.ee_kt_algorithm)
        # run the clustering, extract the jets
        cs = ClusterSequence(StdVector(particles), jet_def)
        GC.@preserve cs begin
            GC.gc()
            jets = exclusive_jets(cs, 2)
            @test length(jets) == 2
            printInfo(jets)
            println(FastJet.four_mom(jets[1]))
            println(FastJet.four_mom(jets[2]))
        end
    end
    @testset "Plugins" begin
        # run the clustering, extract the jets
        vp = FastJet.ValenciaPlugin(1.2, 0.8)
        vp_def = JetDefinition(vp)
        valencia = ClusterSequence(StdVector(particles), vp_def)
        GC.@preserve vp valencia vp_def begin
            jets = inclusive_jets(valencia, 0.0)
            GC.gc()
            @test length(jets) == 2
            printInfo(jets)
            # run the clustering, extract the jets
            cs = ClusterSequence(StdVector(particles), vp_def)            
            jets = exclusive_jets(valencia, 3)
            printInfo(jets)
            @test length(jets) == 3
        end
        println(FastJet.will_delete_self_when_unused(valencia))
    end
    p = PseudoJet(3.0, 4.0, 0.0, 25.0)
    mom = FastJet.four_mom(p)
    @test mom[1] == px(p)
    @test mom[2] == py(p)
    @test mom[3] == pz(p)
    @test mom[4] == E(p)
    @test p[1] == px(p)
    @test p[2] == py(p)
    @test p[3] == pz(p)
    @test p[4] == E(p)
    set_user_index(p, 17)
    @test user_index(p) == 17
    @test modp2(p) == 25.0
end 
main() 

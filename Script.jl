using DataFrames, Distributions, StatsPlots, Random, JLD2
import CSV: read
import StatsBase: proportions

Random.seed!(12345)

dat_col = [read("Data/"* i, DataFrame) for i in filter(x -> endswith(x, ".csv"), readdir("Data"))]
dat_col = [select(i, Cols(x -> x in ["B365H", "B365D", "B365A"] || endswith(x, "Team") || x == "Date")) for i in dat_col]
dat_col = [dropmissing(i, Cols(x -> endswith(x, "Team"))) for i in dat_col]


### MISSING VALUE IMPUTATION: Next/previous game's probabilities 
function miss_impute(df)
    df_temp = df
    dat_miss = subset(transform(df_temp, :Date => (x -> 1:nrow(df)) => :n), :B365H => ByRow(x -> ismissing(x)))
    for i in 1:nrow(dat_miss)
        adjacent_game = reverse([subset(df_temp, [:HomeTeam, :AwayTeam] => ByRow((x, y) -> x == dat_miss[i, :AwayTeam] && y == dat_miss[i, :HomeTeam]))[1, l] for l in 4:6])
        for j in eachindex(adjacent_game)
            df_temp[dat_miss[i, :n], 3 + j] = adjacent_game[j]
        end
    end
    return df_temp
end
dat_col = miss_impute.(dat_col)


### SIMULATION
dat_col = transform.(dat_col, Cols(x -> x in ["B365H", "B365D", "B365A"]) .=> ByRow(x -> 1/x), renamecols = false)
dat_col = transform.(dat_col, Cols(x -> x in ["B365H", "B365D", "B365A"] ) => ByRow((x, y, z) -> sum([x,y,z])) => :prob_scale)
dat_col = transform.(dat_col, Cols(x -> x in ["B365H"] || x == "prob_scale") => ByRow((x, y) -> x/y) => :B365H_prob)
dat_col = transform.(dat_col, Cols(x -> x in ["B365D"] || x == "prob_scale") => ByRow((x, y) -> x/y) => :B365D_prob)
dat_col = transform.(dat_col, Cols(x -> x in ["B365A"] || x == "prob_scale") => ByRow((x, y) -> x/y) => :B365A_prob)
dat_col = [select(i, Not(1, 4:7)) for i in dat_col]

team_code = Dict(sort(unique(vcat(select.(dat_col, :HomeTeam)...)).HomeTeam) .=> 1:38)

dat_col = transform.(dat_col, [:HomeTeam] .=> ByRow(x -> team_code[x]), renamecols = false)
dat_col = transform.(dat_col, [:AwayTeam] .=> ByRow(x -> team_code[x]), renamecols = false)
dat_col = Matrix.(dat_col)

homepoint(x) = if !ismissing(x);  x == 1 ? 3 : x == 2 ? 0 : 1; else missing end
awaypoint(x) = if !ismissing(x);  x == 1 ? 0 : x == 2 ? 3 : 1; else missing end

function season_final(season)
    teams = unique(season[:, 1])

    results = [let p = filter(x -> x[1] == i && x[2] == j, eachrow(season)); i == j ? missing : ([1, 0, 2]' * rand(Multinomial(1, p[1][3:5]), 1))[1] end for i in teams, j in teams]
    
    table_final = [sum(skipmissing(vcat(map(homepoint, results[i, :]), map(awaypoint, results[:, i])))) for i in 1:length(teams)]

    return [teams table_final]
end

function temp(x, i)
    @info i
    return season_final.(x)
end
results = [temp(dat_col, i) for i in 1:10^6]


Random.seed!(12345)

function champ_finder(x)
    points = x[:, 2]
    champ = findall(x -> x == findmax(points)[1], points)
    champ_status = zeros(length(points))
    champ_status[rand(champ, 1)[1]] = 1.0
    res = hcat(x, champ_status)
    return res
end
results = [champ_finder.(results[i]) for i in eachindex(results)]


### RESULTS & ANALYSIS
## First 9 Years
function champ_count_2(x)
    champ_n = combine(groupby(DataFrame(vcat(x...), :auto), :x1), [:x2, :x3] .=> sum)
    return subset(champ_n, :x2_sum => ByRow(x -> x == sort(unique(champ_n.x2_sum), rev = true)[2]))
end
top_team9 = vcat(map(x -> champ_count_2(results[x][1:9]), eachindex(results))...)

# Probability of the top team winning no league cups, 2014-2023: ~ 0.028316
bar(0:7, proportions(round.(Int64, top_team9.x3_sum)), bar_width = .1, xticks = 0:7, legend = :none, c = palette(:roma, 5)[4], xlabel = "Şampiyonluk Sayısı", ylabel = "Olasılık")

# Point distribution of second top teams with no league cups, 2014-2023
histogram(round.(Int64, subset(top_team9, :x3_sum => ByRow(x -> x == 0)).x2_sum), bin = 550:630, legend = :none, c = palette(:roma, 5)[4], xlabel = "Toplam Puan", ylabel = "Gözlem Sayısı")
vline!([618], c = palette(:roma, 5)[1], linestyle = :dash)

# Probability of a team collecting 618 points regardless of its rank, but winning no league cups 2014-2023: ~ 0.000836
function  point_count(x, p)
    return subset(combine(groupby(DataFrame(vcat(x...), :auto), :x1), [:x2, :x3] .=> sum), :x2_sum => ByRow(x -> x >= p))
end
pts_count9 = vcat(map(x -> point_count(results[x][1:9], 618), eachindex(results))...)
nrow(subset(pts_count9, :x3_sum => ByRow(x -> x == 0)))/nrow(pts_count9)


## All 10 Years
second_team10 = vcat(champ_count_2.(results)...)

# Probability of a second top team winning no league cups, 2014-2024: ~ 0.017752
bar(0:7, proportions(round.(Int64, second_team10.x3_sum)), bar_width = .1, xticks = 0:7, legend = :none, c = palette(:roma, 5)[4], xlabel = "Şampiyonluk Sayısı", ylabel = "Olasılık")
 
# Point distribution of second top teams with no league cups, 2014-2023
histogram(round.(Int64, subset(second_team10, :x3_sum => ByRow(x -> x == 0)).x2_sum), bin = 595:725, legend = :none, c = palette(:roma, 5)[4], xlabel = "Toplam Puan", ylabel = "Gözlem Sayısı")
vline!([717], c = palette(:roma, 5)[1], linestyle = :dash)

# Probability of a team collecting 716 points regardless of its rank, but winning no league cups 2014-2024: ~ 0.000037
pts_count10 = vcat(map(x -> point_count(results[x], 717), eachindex(results))...)
nrow(subset(pts_count10, :x3_sum => ByRow(x -> x == 0)))/nrow(pts_count10)


### MISC
# Major Teams' Probability of Winning the League Cup
function champ_extractor(x)
    champ_row = vcat(filter(x -> x[3] == 1, eachrow(x))...)
    return champ_row[1]
end

champs10 = map(x -> champ_extractor.(results[x]), eachindex(results))
champ_prob = [[champs10[i][j] for i in eachindex(champs10)] for j in 1:10]
champ_prob_dat = transform(subset(combine(groupby(DataFrame(year = repeat(2014:2023, inner = 10^6), team = vcat(champ_prob...), champ = ones(10^7)), [:year, :team]), :champ => (x -> sum(x)/10^6) => :champ_prob), :team => ByRow(x -> x in map(x -> team_code[x], ["Galatasaray", "Fenerbahce", "Besiktas", "Trabzonspor", "Buyuksehyr"]))), :team => ByRow(x -> x == 9.0 ? "Beşiktaş" : x == 16.0 ? "Fenerbahçe" : x == 17.0 ? "Galatasaray" : x == 36 ? "Trabzonspor" : "Başakşehir"), renamecols = false)
@df champ_prob_dat groupedbar(:year, :champ_prob, group = :team, xticks = (2014:2023, ["14-15", "15-16", "16-17", "17-18", "18-19", "19-20", "20-21", "21-22", "22-23", "23-24"]), c = [palette(:roma, 5, rev = true)[i] for i in 1:5]', xrotation = 0, xlabel = "Sezon", ylabel = "Şampiyonluk Olasılığı", legend = :top)

# Substantive Comparisons
champs_14 = round.(Int64, map(x -> vcat(filter(y -> y[3] == 1.0, eachrow(results[x][1]))...)[1], eachindex(results)))
length(filter(x -> x == team_code["Kasimpasa"], champs_14))/length(results)

champs_21 = round.(Int64, map(x -> vcat(filter(y -> y[3] == 1.0, eachrow(results[x][8]))...)[1], eachindex(results)))
length(filter(x -> x == team_code["Goztep"], champs_21))/length(results)

champs_22 = round.(Int64, map(x -> vcat(filter(y -> y[3] == 1.0, eachrow(results[x][9]))...)[1], eachindex(results)))
length(filter(x -> x == team_code["Konyaspor"], champs_22))/length(results) 
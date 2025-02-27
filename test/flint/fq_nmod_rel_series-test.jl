@testset "fq_nmod_rel_series.types" begin
   @test rel_series_type(fq_nmod) == fq_nmod_rel_series
end

@testset "fq_nmod_rel_series.constructors" begin
   R, t = FiniteField(23, 5, "t")
   
   S1 = RelSeriesRing(R, 30)
   S2 = RelSeriesRing(R, 30)

   @test isa(S1, FqNmodRelSeriesRing)
   @test S1 !== S2

   S, x = PowerSeriesRing(R, 30, "x")

   @test elem_type(S) == fq_nmod_rel_series
   @test elem_type(FqNmodRelSeriesRing) == fq_nmod_rel_series
   @test parent_type(fq_nmod_rel_series) == FqNmodRelSeriesRing

   @test isa(S, FqNmodRelSeriesRing)

   a = x^3 + 2x + 1
   b = (t^2 + 1)*x^2 + (t + 3)x + O(x^4)

   @test isa(a, SeriesElem)
   @test isa(b, SeriesElem)

   c = S(a)
   d = S([t + 1, t, R(1)], 3, 5, 0)

   @test isa(c, SeriesElem)
   @test isa(d, SeriesElem)

   g = S(1)
   h = S(fmpz(2))
   k = S()

   @test isa(g, SeriesElem)
   @test isa(h, SeriesElem)
   @test isa(k, SeriesElem)

   l = S(t)

   @test isa(l, SeriesElem)
end

@testset "fq_nmod_rel_series.printing" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   b = (t^2 + 1)*x^2 + (t + 3)x + O(x^4)

   @test sprint(show, "text/plain", b) == "(t + 3)*x + (t^2 + 1)*x^2 + O(x^4)"
end

@testset "fq_nmod_rel_series.manipulation" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   @test max_precision(S) == 30

   a = 2x + x^3
   b = O(x^4)

   @test isgen(gen(S))

   @test iszero(zero(S))

   @test isone(one(S))

   @test isunit(-1 + x + 2x^2)

   @test valuation(a) == 1

   @test valuation(b) == 4

   @test precision(a) == 31

   @test precision(b) == 4

   @test isequal(deepcopy(a), a)

   @test isequal(deepcopy(b), b)

   @test coeff(a, 1) == 2

   @test coeff(b, 7) == 0

   @test characteristic(S) == 23
end

@testset "fq_nmod_rel_series.similar" begin
   R0, a = FiniteField(23, 2, "a")
   R, x = PowerSeriesRing(R0, 10, "x")
   S, y = PowerSeriesRing(ZZ, 10, "y")

   for iters = 1:10
      f = rand(R, 0:10)
      fz = rand(S, 0:10, -10:10)

      g = similar(fz, R0, "y")
      h = similar(f, "y")
      k = similar(f)
      m = similar(fz, R0, 5)
      n = similar(f, 5)

      @test isa(g, fq_nmod_rel_series)
      @test isa(h, fq_nmod_rel_series)
      @test isa(k, fq_nmod_rel_series)
      @test isa(m, fq_nmod_rel_series)
      @test isa(n, fq_nmod_rel_series)

      @test parent(g).S == :y
      @test parent(h).S == :y

      @test iszero(g)
      @test iszero(h)
      @test iszero(k)
      @test iszero(m)
      @test iszero(n)

      @test parent(g) !== parent(f)
      @test parent(h) !== parent(f)
      @test parent(k) === parent(f)
      @test parent(m) !== parent(f)
      @test parent(n) !== parent(f)

      p = similar(f, cached=false)
      q = similar(f, "z", cached=false)
      r = similar(f, "z", cached=false)
      s = similar(f)
      t = similar(f)

      @test parent(p) === parent(f)
      @test parent(q) !== parent(r)
      @test parent(s) === parent(t)
   end
end

@testset "fq_nmod_rel_series.rel_series" begin
   R, a = FiniteField(23, 2, "a")
   f = rel_series(R, [1, 2, 3], 3, 5, 2, "y")

   @test isa(f, fq_nmod_rel_series)
   @test base_ring(f) === R
   @test coeff(f, 2) == 1
   @test coeff(f, 4) == 3
   @test parent(f).S == :y

   g = rel_series(R, [1, 2, 3], 3, 7, 4)

   @test isa(g, fq_nmod_rel_series)
   @test base_ring(g) === R
   @test coeff(g, 4) == 1
   @test coeff(g, 6) == 3
   @test parent(g).S == :x

   h = rel_series(R, [1, 2, 3], 2, 7, 1)
   k = rel_series(R, [1, 2, 3], 1, 6, 0, cached=false)
   m = rel_series(R, [1, 2, 3], 3, 9, 5, cached=false)

   @test parent(h) === parent(g)
   @test parent(k) !== parent(m)

   p = rel_series(R, fq_nmod[], 0, 3, 1)
   q = rel_series(R, [], 0, 3, 2)

   @test isa(p, fq_nmod_rel_series)
   @test isa(q, fq_nmod_rel_series)

   @test pol_length(p) == 0
   @test pol_length(q) == 0

   r = rel_series(R, fmpz[1, 2, 3], 3, 11, 8)

   @test isa(r, fq_nmod_rel_series)

   s = rel_series(R, [1, 2, 3], 3, 5, 0; max_precision=10)
   
   @test max_precision(parent(s)) == 10
end

@testset "fq_nmod_rel_series.unary_ops" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = 1 + 2x + x^2 + O(x^3)

   @test isequal(-a, -2x - x^3 + O(x^31))

   @test isequal(-b, -1 - 2x - x^2 + O(x^3))
end

@testset "fq_nmod_rel_series.binary_ops" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = O(x^4)
   c = 1 + x + 3x^2 + O(x^5)
   d = x^2 + 3x^3 - x^4

   @test isequal(a + b, x^3+2*x+O(x^4))

   @test isequal(a - c, x^3-3*x^2+x-1+O(x^5))

   @test isequal(b*c, O(x^4))

   @test isequal(a*c, 3*x^5+x^4+7*x^3+2*x^2+2*x+O(x^6))

   @test isequal(a*d, -x^7+3*x^6-x^5+6*x^4+2*x^3+O(x^33))

   f1 = 1 + x + x^2 + x^3
   f2 = x + x^2
   f3 = x + x^2 + x^3
   f4 = x^2 + x^3 + x^4 + x^5

   @test f1 + f1 == 2+2*x+2*x^2+2*x^3+O(x^30)

   @test f1 + f2 == 1+2*x+2*x^2+x^3+O(x^30)
   @test f2 + f1 == f1 + f2

   @test f1 + f3 == 1+2*x+2*x^2+2*x^3+O(x^30)
   @test f3 + f1 == f1 + f3

   @test f1 + f4 == 1+x+2*x^2+2*x^3+x^4+x^5+O(x^30)
   @test f4 + f1 == f1 + f4

   @test f1 - f1 == 0+O(x^30)

   @test f1 - f2 == 1+x^3+O(x^30)

   @test f1 - f3 == 1+O(x^30)

   @test f1 - f4 == 1+x-x^4-x^5+O(x^30)

   g1 = x^2*f1
   g2 = x^2*f2
   g3 = x^2*f3
   g4 = x^2*f4

   @test g1 + g1 == 2*x^2+2*x^3+2*x^4+2*x^5+O(x^32)

   @test g1 + g2 == x^2+2*x^3+2*x^4+x^5+O(x^32)
   @test g2 + g1 == g1 + g2

   @test g1 + g3 == x^2+2*x^3+2*x^4+2*x^5+O(x^32)
   @test g3 + g1 == g1 + g3

   @test g1 + g4 == x^2+x^3+2*x^4+2*x^5+x^6+x^7+O(x^32)
   @test g4 + g1 == g1 + g4

   @test g1 - g1 == 0+O(x^32)

   @test g1 - g2 == x^2+x^5+O(x^32)
   @test g2 - g1 == -(g1 - g2)

   @test g1 - g3 == x^2+O(x^32)
   @test g3 - g1 == -(g1 - g3)

   @test g1 - g4 == x^2+x^3-x^6-x^7+O(x^32)
   @test g4 - g1 == -(g1 - g4)

   h1 = f1
   h2 = -f2
   h3 = -f3
   h4 = -f4

   @test h1 + h2 == 1+x^3+O(x^30)
   @test h2 + h1 == h1 + h2

   @test h1 + h3 == 1+O(x^30)
   @test h3 + h1 == h1 + h3

   @test h1 + h4 == 1+x-x^4-x^5+O(x^30)
   @test h4 + h1 == h1 + h4

   @test h1 - h2 == 1+2*x+2*x^2+x^3+O(x^30)
   @test h2 - h1 == -(h1 - h2)

   @test h1 - h3 == 1+2*x+2*x^2+2*x^3+O(x^30)
   @test h3 - h1 == -(h1 - h3)

   @test h1 - h4 == 1+x+2*x^2+2*x^3+x^4+x^5+O(x^30)
   @test h4 - h1 == -(h1 - h4)

   k1 = g1
   k2 = -g2
   k3 = -g3
   k4 = -g4

   @test k1 + k2 == x^2+x^5+O(x^32)
   @test k2 + k1 == k1 + k2

   @test k1 + k3 == x^2+O(x^32)
   @test k3 + k1 == k1 + k3

   @test k1 + k4 == x^2+x^3-x^6-x^7+O(x^32)
   @test k4 + k1 == k1 + k4

   @test k1 - k2 == x^2+2*x^3+2*x^4+x^5+O(x^32)
   @test k2 - k1 == -(k1 - k2)

   @test k1 - k3 == x^2+2*x^3+2*x^4+2*x^5+O(x^32)
   @test k3 - k1 == -(k1 - k3)

   @test k1 - k4 == x^2+x^3+2*x^4+2*x^5+x^6+x^7+O(x^32)
   @test k4 - k1 == -(k1 - k4)

   m1 = 1 + x + x^2 + x^3 + O(x^4)
   m2 = x + x^2 + O(x^3)
   m3 = x + x^2 + x^3 + O(x^4)
   m4 = x^2 + x^3 + x^4 + x^5 + O(x^6)

   @test isequal(m1 + m1, 2+2*x+2*x^2+2*x^3+O(x^4))

   @test isequal(m1 + m2, 1+2*x+2*x^2+O(x^3))

   @test isequal(m1 + m3, 1+2*x+2*x^2+2*x^3+O(x^4))

   @test isequal(m1 + m4, 1+x+2*x^2+2*x^3+O(x^4))

   @test isequal(m1 - m1, 0+O(x^4))

   @test isequal(m1 - m2, 1+O(x^3))

   @test isequal(m1 - m3, 1+O(x^4))

   @test isequal(m1 - m4, 1+x+O(x^4))
end

@testset "fq_nmod_rel_series.adhoc_binary_ops" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = O(x^4)
   c = 1 + x + 3x^2 + O(x^5)
   d = x^2 + 3x^3 - x^4

   @test isequal(2a, 4x + 2x^3 + O(x^31))

   @test isequal(fmpz(3)*b, O(x^4))

   @test isequal(c*2, 2 + 2*x + 6*x^2 + O(x^5))

   @test isequal(d*fmpz(3), 3x^2 + 9x^3 - 3x^4 + O(x^32))
end

@testset "fq_nmod_rel_series.comparison" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = O(x^3)
   c = 1 + x + 3x^2 + O(x^5)
   d = 3x^3 - x^4

   @test a == 2x + x^3

   @test b == d

   @test c != d

   @test isequal(a, 2x + x^3 + O(x^31))

   @test !isequal(b, d)
end

@testset "fq_nmod_rel_series.adhoc_comparison" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = O(x^0)
   c = 1 + O(x^5)
   d = S(3)

   @test d == 3

   @test c == fmpz(1)

   @test fmpz() != a

   @test 2 == b

   @test fmpz(1) == c
end

@testset "fq_nmod_rel_series.powering" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = O(x^4)
   c = 1 + x + 2x^2 + O(x^5)
   d = 2x + x^3 + O(x^4)

   @test isequal(a^12, x^36+24*x^34+264*x^32+1760*x^30+7920*x^28+25344*x^26+59136*x^24+101376*x^22+126720*x^20+112640*x^18+67584*x^16+24576*x^14+4096*x^12+O(x^42))

   @test isequal(b^12, O(x^48))

   @test isequal(c^12, 2079*x^4+484*x^3+90*x^2+12*x+1+O(x^5))

   @test isequal(d^12, 4096*x^12+24576*x^14+O(x^15))

   @test_throws DomainError a^-1
end

@testset "fq_nmod_rel_series.shift" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = O(x^4)
   c = 1 + x + 2x^2 + O(x^5)
   d = 2x + x^3 + O(x^4)

   @test isequal(shift_left(a, 2), 2*x^3+x^5+O(x^33))

   @test isequal(shift_left(b, 2), O(x^6))

   @test isequal(shift_right(c, 1), 1+2*x+O(x^4))

   @test isequal(shift_right(d, 3), 1+O(x^1))

   @test_throws DomainError shift_left(a, -1)

   @test_throws DomainError shift_right(a, -1)
end

@testset "fq_nmod_rel_series.truncation" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 2x + x^3
   b = O(x^4)
   c = 1 + x + 2x^2 + O(x^5)
   d = 2x + x^3 + O(x^4)

   @test isequal(truncate(a, 3), 2*x + O(x^3))

   @test isequal(truncate(b, 2), O(x^2))

   @test isequal(truncate(c, 5), 2*x^2+x+1+O(x^5))

   @test isequal(truncate(d, 5), x^3+2*x+O(x^4))

   @test_throws DomainError truncate(a, -1)
end

@testset "fq_nmod_rel_series.inversion" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = 1 + x + 2x^2 + O(x^5)
   b = S(-1)

   @test isequal(inv(a), -x^4+3*x^3-x^2-x+1+O(x^5))

   @test isequal(inv(b), -1+O(x^30))
end

@testset "fq_nmod_rel_series.exact_division" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = x + x^3
   b = O(x^4)
   c = 1 + x + 2x^2 + O(x^5)
   d = x + x^3 + O(x^6)

   @test isequal(divexact(a, d), 1+O(x^5))

   @test isequal(divexact(d, a), 1+O(x^5))

   @test isequal(divexact(b, c), O(x^4))

   @test isequal(divexact(d, c), -2*x^5+2*x^4-x^2+x+O(x^6))
end

@testset "fq_nmod_rel_series.adhoc_exact_division" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   a = x + x^3
   b = O(x^4)
   c = 1 + x + 2x^2 + O(x^5)
   d = x + x^3 + O(x^6)

   @test isequal(divexact(a, 7), 10*x+10*x^3+O(x^31))

   @test isequal(divexact(b, fmpz(11)), 0+O(x^4))

   @test isequal(divexact(c, fmpz(2)), 12 + 12*x+x^2+O(x^5))

   @test isequal(divexact(d, 9), 18*x+18*x^3+O(x^6))

   @test isequal(divexact(94872394861923874346987123694871329847a, 94872394861923874346987123694871329847), a)

   @test isequal(divexact((t + 1)*a, t + 1), a)
end

@testset "fq_nmod_rel_series.special_functions" begin
   R, t = FiniteField(23, 5, "t")
   S, x = PowerSeriesRing(R, 30, "x")

   @test isequal(exp(x + O(x^10)), 18*x^9+x^8+8*x^7+10*x^6+14*x^5+x^4+4*x^3+12*x^2+x+1+O(x^10))

   @test isequal(divexact(x, exp(x + O(x^10)) - 1), 13*x^8+9*x^6+13*x^4+2*x^2+11*x+1+O(x^9))
end

@testset "fq_nmod_rel_series.unsafe_operators" begin
   S, t = FiniteField(23, 5, "t")
   R, x = PowerSeriesRing(S, 30, "x")

   for iter = 1:300
      f = rand(R, 0:9)
      g = rand(R, 0:9)
      f0 = deepcopy(f)
      g0 = deepcopy(g)

      h = rand(R, 0:9)

      k = f + g
      h = add!(h, f, g)
      @test isequal(h, k)
      @test isequal(f, f0)
      @test isequal(g, g0)

      f1 = deepcopy(f)
      f1 = add!(f1, f1, g)
      @test isequal(f1, k)
      @test isequal(g, g0)

      g1 = deepcopy(g)
      g1 = add!(g1, f, g1)
      @test isequal(g1, k)
      @test isequal(f, f0)

      f1 = deepcopy(f)
      f1 = addeq!(f1, g)
      @test isequal(h, k)
      @test isequal(g, g0)

      k = f*g
      h = mul!(h, f, g)
      @test isequal(h, k)
      @test isequal(f, f0)
      @test isequal(g, g0)

      f1 = deepcopy(f)
      f1 = mul!(f1, f1, g)
      @test isequal(f1, k)
      @test isequal(g, g0)

      g1 = deepcopy(g)
      g1 = mul!(g1, f, g1)
      @test isequal(g1, k)
      @test isequal(f, f0)

      h = zero!(h)
      @test isequal(h, R())
   end
end
